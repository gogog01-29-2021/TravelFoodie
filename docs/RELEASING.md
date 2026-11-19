# Releasing TravelFoodie as an APK (GitHub Releases)

Pushing a version tag builds a signed APK on GitHub Actions and publishes it as a
GitHub Release that anyone can download. No Google Play review is involved.

## One-time setup

1. **Create a release keystore** (do this on your own machine; never commit it):

   ```bash
   keytool -genkeypair -v -keystore travelfoodie-release.jks -alias travelfoodie \
     -keyalg RSA -keysize 2048 -validity 10000
   ```

   Back it up somewhere safe. **If you lose this file or its password you can never
   ship an update that installs over the old app.**

2. **Add repository secrets** (GitHub: Settings, Secrets and variables, Actions), or with the
   `gh` CLI:

   ```bash
   base64 -i travelfoodie-release.jks | gh secret set RELEASE_KEYSTORE_BASE64
   gh secret set RELEASE_STORE_PASSWORD
   gh secret set RELEASE_KEY_ALIAS          # travelfoodie
   gh secret set RELEASE_KEY_PASSWORD
   gh secret set MAPS_API_KEY
   gh secret set KAKAO_API_KEY
   gh secret set NAVER_CLIENT_ID
   gh secret set NAVER_CLIENT_SECRET
   ```

3. **Restrict the Maps key** in Google Cloud Console to package `com.travelfoodie` and the
   release certificate SHA-1/SHA-256. The release workflow prints the certificate
   fingerprint in its "Name and verify the APK" step.

## Shipping a version

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow sets `versionName` from the tag and `versionCode` from the run number (it only
ever goes up, which Android requires for updates). The signed APK and its SHA-256 appear
under the repository's Releases. If the keystore secret is missing, the workflow still builds
but produces an unsigned APK as a workflow artifact and publishes nothing.

## What to know before sharing the APK

- Users must allow "install unknown apps" and will see a Play Protect warning for a new,
  unknown developer. There are no automatic updates; they install each new APK by hand.
- Google is rolling out developer verification for apps installed outside Play. Enforcement
  started on 2026-09-30 in Brazil, Indonesia, Singapore and Thailand, with a global rollout
  planned for 2027, so plan to register as a verified developer.
- Anything in `BuildConfig` or the manifest (including `NAVER_CLIENT_SECRET`) can be extracted
  from a downloaded APK. Treat those values as public and restrict each key on the provider side.
- The `Android CI` workflow builds every push, runs the minified release build, and smoke-tests
  that release APK on an emulator. Wait for it to pass before tagging.
