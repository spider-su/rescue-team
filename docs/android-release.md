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
godot --headless --path . --script res://tests/test_campaign.gd
godot --headless --path . --script res://tests/test_old_town.gd
godot --headless --path . --script res://tests/test_audio.gd
godot --headless --path . --script res://tests/test_puzzle_polish.gd
godot --headless --path . --script res://tests/test_crew_progression.gd
godot --headless --path . --script res://tests/test_action_presentation.gd
godot --headless --path . --script res://tests/test_rescue_ui.gd
mkdir -p build
godot --headless --path . --export-debug "Android" build/game-debug.apk
```

This exports the **twenty-mission campaign with three optional Floodworks trials**. The new scrolling, ranger and Old Town chapter still need physical-device acceptance; use the [Old Town device scenario](old-town.md#verification-and-device-scenario). The owner reported the preceding coastal UI working but scrolling being difficult; device/OS details were not provided.

## Signed Play upload bundle

The manual `Godot Game CI` dispatch accepts `release_aab=true`, `release_version_code` and `release_version_name`. It first runs the full existing import/test/debug-export pipeline, then installs the pinned Godot Gradle template and creates `rescue-team-release.aab` using `--export-release`. The normal APK export preset is changed only in that disposable CI checkout.

```bash
gh workflow run godot-ci.yml --ref main \
  -f release_aab=true -f release_version_code=1 -f release_version_name=0.1.0
```

For subsequent Play uploads, choose a version code that has never been used for this app. The bundle is signed using the dedicated upload key supplied by `ANDROID_RELEASE_KEYSTORE_BASE64`, `ANDROID_RELEASE_KEYSTORE_USER` and `ANDROID_RELEASE_KEYSTORE_PASSWORD`. No fallback to debug signing is allowed. The recovery keystore and credentials are stored privately outside the repository; back them up to secure owner-controlled storage before relying on this key for continuing releases.

The `rescue-team-release-aab` artifact includes the signed bundle, SHA-256/source/CI metadata, manifest and certificate-verification evidence. Before uploading, CI runs pinned bundletool validation, JAR signature verification and checks the exact upload certificate, package, requested version, non-debuggable status, arm64 libraries and absence of INTERNET permission. The bundle is an upload candidate; these checks do not prove device acceptance or Play policy approval. It is not directly installable like an APK.

### Play Console crash-report warnings

The version-code-1 AAB uses the standard Godot 4.7.2 Gradle release template, which does not enable R8 minification. Its DEX retains Godot class names and it has no obfuscation mapping metadata. The missing deobfuscation-file warning is therefore informational: there is no `mapping.txt` to upload. If minification is enabled later, retain and upload the mapping from that exact build; do not upload an empty or unrelated mapping.

Native symbols are useful because the bundle contains stripped `libgodot_android.so` and `libc++_shared.so`. Release CI also downloads the [official Godot release symbols](https://github.com/godotengine/godot/releases/tag/4.7.2-stable), verifies the pinned archive SHA-256, and runs `scripts/release_symbols.py` to compare each library's GNU build ID against the actual AAB. Missing symbols or mismatched IDs fail packaging. Only matching ABIs are included, with ABI directories at the ZIP root. The separate `rescue-team-native-debug-symbols` CI artifact contains `native-debug-symbols.zip` and JSON checksum/build-ID evidence.

For version code 1, the prepared local upload is `build/release-0.1.0-1/native-debug-symbols.zip`; its verification evidence is in [the release handoff](evidence/2026-11-02-release-aab/README.md). It supplements the existing bundle without rebuilding or consuming another version code.

In Play Console, open **Test and release → Latest releases and bundles → version code 1 → Downloads → Assets → Native debug symbols**, then upload **`native-debug-symbols.zip`**. If creating the release, the bundle's three-dot menu also offers **Upload native debug symbols (.zip)**. Upload the inner ZIP, not GitHub's outer artifact ZIP. See [Godot's upload instructions](https://docs.godotengine.org/en/4.7/tutorials/platform/android/resolving_crashes_on_android.html) and [Android's native-symbol guidance](https://developer.android.com/build/include-native-symbols). Play's processing/acceptance must be checked after upload; local verification alone does not establish it.

## Regression playtest: progress and crate safety (pending on device)

- Complete Mission 01, close the app with Android's force-stop action, then reopen it offline. Mission 02 must remain unlocked. Complete another mission and repeat; prior unlocks and best move counts must remain. This checks completed-save persistence, not power-loss durability during a write.
- In a test map with an engineer, crate and waiting civilian in adjacent corridor cells, tap the crate from both an adjacent and a distant starting tile. Neither input may push the crate onto the civilian; a rejected push must preserve move count and undo history. After collecting the civilian and moving the carrier away, the former civilian tile must accept a crate normally, and undo must restore the push.
- Record APK commit, device model, Android version and exact results. Headless regression tests cover interrupted temporary writes and failed replacement; those results do not establish real-device usability.

## Release readiness

1. Keep product package ID `com.spidersu.rescueteam` stable, increase Android version code for each published build.
2. Add legally cleared product assets and icons; ensure no inherited template-only graphics or text remain.
3. Create/back up a stable release signing key, protect credentials in secrets; never reuse a CI debug key for Play publishing.
4. Configure an Android App Bundle (AAB), Gradle build when necessary, supported Play target SDK, release signing, Play test tracks and reproducible update-over-install tests.
5. Verify Android touch, offline play, save persistence, pause/resume, system bars, screen sizes, performance, sound lifecycle and crash behavior on **real devices**.
6. Prepare store metadata, contact/support page, privacy policy and data-safety declarations before release.
7. Only add ad/IAP integration when validated by player tests and commercial roadmap decision.

The complete candidate gate, ownership boundaries and tester report are in [release.md](release.md) and [playtest-report.md](playtest-report.md). Store copy and the publication-ready privacy-policy text are in [store-listing.md](store-listing.md) and [privacy-policy.md](privacy-policy.md). A green CI result means **export verified**, not a physically tested game or store-ready release.

Godot reference: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html

## Regression playtest: hero obstacle messages (pending on device)

Use the APK commit recorded on the PR. Select the engineer and tap fire, then tap a destination beyond the fire in a blocked corridor. A portrait popup must explain the fire without moving anyone or changing undo history. Repeat to see different wording. Tap a locked gate and a destination behind it: the hero should explain opening the gate with the blue switch. Check wall, crate, blocked push and Old Town infected messages. Each category has four lines, with no immediate repeats.

On a smaller phone, verify the entire message fits and the portrait matches the selected hero. Wait 4.5 seconds for dismissal, then repeat and switch heroes, restart or return to missions: stale popups must disappear. Tap a reachable tile while the popup is visible: movement must work immediately. Complete a normal rescue and undo it to check unchanged rules. Record device/OS, APK commit and results; desktop screenshots and headless checks do not establish device ergonomics.

## Audio listening and interruptions

Use the [audio device scenario](audio.md#android-listening-scenario-pending) to verify music loops, action sounds, independent saved mutes, background/resume and native output/focus changes. These checks remain pending on hardware.

## Fair scoring, hints, resume and Floodworks

Run the [puzzle-polish device scenario](puzzle-polish.md#validation-and-on-device-scenario), including an existing v1 score save, partial-walk interruption, restored undo and valve/bridge prerequisite behavior. These additions have automated coverage; Android usability remains pending.

## Crew recovery and cosmetic rewards

Run the [crew and district recovery device scenario](emotional-progression.md#verification-and-android-scenario). Verify the visual rewards stay cosmetic, save offline and remain readable while scrolling a small display.

## Action-animation acceptance

On a physical Android device, complete missions that exercise walking, fire spray, crate push, civilian pickup, ranger containment, valve turn and the exit celebration. Each effect should start promptly, remain readable at the smallest supported screen, finish before the next input becomes active, and never change move count, undo grouping or the solved path. Check a longer routed move for steady pacing and use **UNDO** immediately after an effect. Record the APK commit, device, Android version, frame pacing observations and exact result.
