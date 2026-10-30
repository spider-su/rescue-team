# Rescue Team

**An original, touch-first 2D rescue puzzle game for Android.** Built in **Godot 4.7.2 stable (GDScript)**.

> **Current status: Phase 1 playable prototype.** Three original, progressively varied cooperative rescue puzzles are implemented. Ten curated levels, original artwork and broader device playtesting are still planned. The initial Android happy-path test passed on 2026-10-30 (installed APK and completed Mission 01, user reported).

## Game vision

Command a small rescue squad through compact, readable puzzles (roughly 1–3 minutes per level). Choose a rescuer, combine character abilities, manipulate the environment and guide civilians to a safe exit. **Original** characters, levels, art and sounds only; this is not a port or distribution of any legacy Java ME game.

- **Firefighter:** extinguish fire to open safe routes.
- **Engineer:** move objects and operate mechanisms to create routes.
- **Shared loop:** select a character → plan actions → rescue civilians → reach extraction → restart/undo if necessary.
- **Platform:** Android-first, portrait, touch-friendly, playable fully offline.
- **Monetization:** no ads or IAP in the prototype. Explore a demo/full-unlock model *after* playtests.

Detailed product scope and stage gates: [Game design](docs/game-design.md) and [Roadmap](docs/roadmap.md).

## Current project contents

- `project.godot`: Godot project and 720×1280 portrait configuration.
- `scenes/main.tscn` + `scripts/rescue_game.gd` + `scripts/board_view.gd`: first playable portrait puzzle with touch controls.
- `scripts/rescue_level.gd`: deterministic 11×5 board state, two specialists, fire, crate/switch/gate, civilian pickup, extraction, undo and restart.
- `tests/test_rescue_level.gd`: headless tests including a complete winning action sequence, invalid moves and undo.
- `.github/workflows/godot-ci.yml`: Android debug APK build using GitHub Actions, Java 17, Android SDK, pinned Godot editor/export templates; uploads an installable artifact.
- `docs/architecture.md`, `docs/android-release.md`: technical and release documentation.

## Run locally

1. Install **Godot 4.7.2 stable (standard/GDScript)** and open `project.godot`.
2. Run the project with F5.
3. For headless project import and logic tests:

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_rescue_level.gd
```

Play **Mission 01: The Locked Corridor**. Select the engineer (E), move right and push the crate (BOX) onto the blue switch to open the gate. Then select the firefighter (F), extinguish the fire, pick up the civilian (C), and reach EXIT. Use PREVIOUS/NEXT to switch between unlocked missions (progress saved locally after a rescue). Tap a distant reachable square to walk there automatically. Tap the fire or crate to approach and interact; locked gates are not bypassed. Each destination tap can be undone in one step. UNDO and RESTART are provided. The project owner installed the APK on Android and successfully completed Mission 01 on 2026-10-30. Device model, OS version, broader touch ergonomics and lifecycle behavior have not been independently verified.

## Android APK / CI

Push to `main` (or `feat/**`), open a PR targeting `main`, or manually dispatch **Godot Game CI**. The workflow installs Godot **4.7.2** and matching Android export templates, runs headless checks and exports a **debug APK**.

Download the `rescue-team-debug-apk` artifact from the successful run in [Actions](https://github.com/spider-su/rescue-team/actions). The APK contains a temporary debug signature, regenerated on each CI run. Do **not** use it for Play publishing or update-over-install tests between runs.

See [Android release guide](docs/android-release.md) for release signing, AAB, device testing and privacy/store readiness. Release AAB and commercial billing are **not configured yet**.

## Template provenance and independence

Bootstrapped from [spider-su/mobile_template / game-template](https://github.com/spider-su/mobile_template/tree/game-template), based on the MIT-licensed code there. This repository owns its own product development; **do not merge the Expo app template or game-template branches into this repository**. Port upstream fixes deliberately after reviewing differences.

See [AGENTS.md](AGENTS.md) for implementation/testing rules.
