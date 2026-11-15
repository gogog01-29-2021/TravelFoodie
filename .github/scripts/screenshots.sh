#!/usr/bin/env bash
# Walk the app's bottom-nav tabs on a running emulator and save screenshots.
# Deliberately no `set -e`: keep going so a failed tap still leaves earlier shots.
set -u

PKG=com.travelfoodie
OUT=screenshots
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

adb install -r app/build/outputs/apk/debug/app-debug.apk

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

# Diagnostics: was the app still alive, and did it log crashes?
adb shell pidof "$PKG" > "$OUT/pid.txt" 2>&1 || echo "app process not running" >> "$OUT/pid.txt"
adb logcat -d > "$OUT/logcat.txt" 2>&1
grep -E "FATAL EXCEPTION|AndroidRuntime" "$OUT/logcat.txt" | head -40 > "$OUT/crashes.txt" || true
