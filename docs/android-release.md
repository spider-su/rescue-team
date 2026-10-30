# Rescue Team — Android build and release

## Current debug APK flow

The `Godot Game CI` workflow builds `build/game-debug.apk` and uploads an artifact named `rescue-team-debug-apk` on pushes to `main` and `feat/**`, pull requests to `main` and manual workflow dispatches.

Uses pinned **Godot 4.7.2 stable** editor/templates, Java 17, Android SDK and headless project/test checks. **Only an arm64 APK** is currently produced. CI generates an **ephemeral** debug keystore on every run; upgrades across runs may fail because signatures differ.

Local build: install matching Godot 4.7.2 editor/export templates, Android SDK and Java 17; configure Godot Editor Settings > Export > Android. Then:

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_game_session.gd
mkdir -p build
godot --headless --path . --export-debug "Android" build/game-debug.apk
```

This uses the **temporary inherited demo** until phase 1 implements actual rescue gameplay.

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
