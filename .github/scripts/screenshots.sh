#!/usr/bin/env bash
# Install an APK on a running emulator, walk the bottom-nav tabs, save screenshots and
# FAIL if the app crashes or dies. Used by the emulator smoke test and screenshot workflows.
#
#   APK          path to the APK to install (default: debug build output)
#   OUT          directory for screenshots/logs (default: screenshots)
#   KEEP_LOGCAT  1 = keep the full logcat in OUT (default); 0 = keep only a crash summary.
#                Use 0 when a real Maps key is in the build: the Maps SDK can print the key
#                in logcat, and OUT is uploaded as a downloadable artifact.
#
# Deliberately no `set -e`: a failed tap should still leave the earlier screenshots behind.
set -u

PKG=com.travelfoodie
APK="${APK:-app/build/outputs/apk/debug/app-debug.apk}"
OUT="${OUT:-screenshots}"
KEEP_LOGCAT="${KEEP_LOGCAT:-1}"
LOGCAT_TMP="$(mktemp)"
mkdir -p "$OUT"

shot() {
  adb exec-out screencap -p > "$OUT/$1.png"
  echo "captured $1 ($(wc -c < "$OUT/$1.png") bytes)"
}

# Tap a view found by resource-id or exact text in a uiautomator dump.
tap() {
  adb shell uiautomator dump /sdcard/ui.xml > /dev/null 2>&1
  adb pull /sdcard/ui.xml "$OUT/ui.xml" > /dev/null 2>&1
  local xy
  xy=$(python3 - "$1" "$OUT/ui.xml" <<'PY'
import re, sys
needle, path = sys.argv[1], sys.argv[2]
xml = open(path, encoding="utf-8", errors="ignore").read()
for m in re.finditer(r'<node [^>]*>', xml):
    node = m.group(0)
    if f'resource-id="{needle}"' in node or f'text="{needle}"' in node:
        b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', node)
        if b:
            x1, y1, x2, y2 = map(int, b.groups())
            print((x1 + x2) // 2, (y1 + y2) // 2)
            break
PY
)
  if [ -n "$xy" ]; then
    adb shell input tap $xy
    echo "tapped $1 at $xy"
  else
    echo "NOT FOUND: $1"
  fi
}

adb install -r "$APK" || { echo "APK install failed"; exit 1; }

# Pre-grant runtime permissions so system dialogs do not cover the screens.
for p in POST_NOTIFICATIONS ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION RECORD_AUDIO READ_CONTACTS; do
  adb shell pm grant "$PKG" "android.permission.$p" || true
done

adb logcat -c
adb shell am start -W -n "$PKG/.MainActivity"
sleep 15
shot 01-map

tap "$PKG:id/nav_trips";       sleep 5; shot 02-trips
tap "$PKG:id/nav_attractions"; sleep 5; shot 03-attractions
tap "$PKG:id/nav_restaurants"; sleep 5; shot 04-restaurants
tap "$PKG:id/nav_profile";     sleep 5; shot 05-profile

# Diagnostics. logcat goes to a temp file first so a key never lands in OUT unless asked.
adb logcat -d > "$LOGCAT_TMP" 2>&1
if [ "$KEEP_LOGCAT" = "1" ]; then cp "$LOGCAT_TMP" "$OUT/logcat.txt"; fi

STATUS=0

# A crash of OUR app: a FATAL EXCEPTION block whose "Process:" line is our package.
if grep -A3 "FATAL EXCEPTION" "$LOGCAT_TMP" | grep -q "Process: $PKG"; then
  echo "FAIL: $PKG crashed"
  grep -A25 "FATAL EXCEPTION" "$LOGCAT_TMP" | head -60 > "$OUT/crashes.txt"
  cat "$OUT/crashes.txt"
  STATUS=1
fi

if [ -z "$(adb shell pidof "$PKG" | tr -d '[:space:]')" ]; then
  echo "FAIL: $PKG process is not running after the walkthrough"
  STATUS=1
fi

# R8/minify symptoms that do not always crash the app but mean something is stripped.
grep -E "ClassNotFoundException|NoSuchMethodException|NoClassDefFoundError" "$LOGCAT_TMP" \
  | grep -i "$PKG\|travelfoodie" | head -20 > "$OUT/r8-suspects.txt" || true

[ "$STATUS" = "0" ] && echo "OK: no crash, app still running"
exit "$STATUS"
