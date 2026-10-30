# Rescue Team — Android build and release

## Current debug APK flow

The `Godot Game CI` workflow builds `build/game-debug.apk` and uploads an artifact named `rescue-team-debug-apk` on pushes to `main` and `feat/**`, pull requests to `main` and manual workflow dispatches.

Uses pinned **Godot 4.7.2 stable** editor/templates, Java 17, Android SDK and headless project/test checks. **Only an arm64 APK** is currently produced. CI **prefers a persistent debug keystore** supplied by repository Actions secret `ANDROID_DEBUG_KEYSTORE_BASE64`. Until configured, the workflow falls back to an ephemeral key and emits a warning, so Android **cannot upgrade an existing installation** signed by another run.

### One-time: configure stable CI debug signing

On a trusted machine with JDK installed, create a **development-only** key (not your Play release key):

```bash
keytool -genkeypair -keystore rescue-debug.keystore -storepass android -keypass android \
  -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Rescue Team Debug,O=Development,C=PL"
base64 -w 0 rescue-debug.keystore
```

On macOS, use `base64 < rescue-debug.keystore | tr -d '\\n'` instead of `base64 -w 0`.

Copy the single-line Base64 result to **Settings → Secrets and variables → Actions → New repository secret** in GitHub. Name it `ANDROID_DEBUG_KEYSTORE_BASE64`. Keep a backed-up copy of the keystore in private storage. Do not commit it or paste it into a chat.

Run **Godot Game CI** again. Future CI builds will use that same key for the package `com.spidersu.rescueteam`. Existing APKs were signed with unrelated temporary keys; **the first switch still requires uninstalling the old Rescue Team app**, which may erase saved progress. After that first reinstall, updates signed with the stable key should work as long as version codes do not decrease.

If the artifact isn't installable even after uninstalling, confirm it is an APK from the workflow (not the artifact ZIP itself), check Android version/device ABI (only ARM64 is currently exported), free storage and the exact Package Installer error. ADB can report `INSTALL_FAILED_UPDATE_INCOMPATIBLE` for a signature mismatch.

For private pull requests, repository secrets can be used by CI. GitHub does not provide secrets to untrusted fork PRs; those builds intentionally use an ephemeral key and should not be installed over existing signed builds.

Local build: install matching Godot 4.7.2 editor/export templates, Android SDK and Java 17; configure Godot Editor Settings > Export > Android. Then:

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_rescue_level.gd
mkdir -p build
godot --headless --path . --export-debug "Android" build/game-debug.apk
```

This exports **Mission 01, the first original playable rescue puzzle**. Physical-device smoke testing is not yet recorded.

## Regression playtest: progress and crate safety (pending on device)

- Complete Mission 01, close the app with Android's force-stop action, then reopen it offline. Mission 02 must remain unlocked. Complete another mission and repeat; prior unlocks and best move counts must remain. This checks completed-save persistence, not power-loss durability during a write.
- In a test map with an engineer, crate and waiting civilian in adjacent corridor cells, tap the crate from both an adjacent and a distant starting tile. Neither input may push the crate onto the civilian; a rejected push must preserve move count and undo history. After collecting the civilian and moving the carrier away, the former civilian tile must accept a crate normally, and undo must restore the push.
- Record APK commit, device model, Android version and exact results. Headless regression tests cover interrupted temporary writes and failed replacement; those results do not establish real-device usability.

## Release readiness (not yet implemented)

1. Keep product package ID `com.spidersu.rescueteam` stable, increase Android version code for each published build.
2. Add legally cleared product assets and icons; ensure no inherited template-only graphics or text remain.
3. Create/back up a stable release signing key, protect credentials in secrets; never reuse a CI debug key for Play publishing.
4. Configure an Android App Bundle (AAB), Gradle build when necessary, supported Play target SDK, release signing, Play test tracks and reproducible update-over-install tests.
5. Verify Android touch, offline play, save persistence, pause/resume, system bars, screen sizes, performance, sound lifecycle and crash behavior on **real devices**.
6. Prepare store metadata, contact/support page, privacy policy and data-safety declarations before release.
7. Only add ad/IAP integration when validated by player tests and commercial roadmap decision.

A green CI result means **export verified**, not a physically tested game or store-ready release.

Godot reference: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
