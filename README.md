# Rescue Team

**An original, touch-first 2D rescue puzzle game for Android.** Built in **Godot 4.7.2 stable (GDScript)**.

> **Current status: project bootstrap.** The playable screen is the inherited Godot *tap-to-score technical demo*, **not** Rescue Team gameplay yet. The roadmap defines the first playable rescue puzzle and 10-level vertical slice.

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
- `scenes/main.tscn` + `scripts/demo_game.gd`: disposable starter screen.
- `scripts/game_session.gd`: tested score/pause/save example (to be replaced with real game state).
- `tests/test_game_session.gd`: headless smoke tests of the inherited starter logic.
- `.github/workflows/godot-ci.yml`: Android debug APK build using GitHub Actions, Java 17, Android SDK, pinned Godot editor/export templates; uploads an installable artifact.
- `docs/architecture.md`, `docs/android-release.md`: technical and release documentation.

## Run locally

1. Install **Godot 4.7.2 stable (standard/GDScript)** and open `project.godot`.
2. Run the project with F5.
3. For headless project import and logic tests:

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_game_session.gd
```

The code is currently a *template smoke demo*. A successful headless check is not proof of playable rescue puzzles or Android device compatibility.

## Android APK / CI

Push to `main` (or `feat/**`), open a PR targeting `main`, or manually dispatch **Godot Game CI**. The workflow installs Godot **4.7.2** and matching Android export templates, runs headless checks and exports a **debug APK**.

Download the `rescue-team-debug-apk` artifact from the successful run in [Actions](https://github.com/spider-su/rescue-team/actions). The APK contains a temporary debug signature, regenerated on each CI run. Do **not** use it for Play publishing or update-over-install tests between runs.

See [Android release guide](docs/android-release.md) for release signing, AAB, device testing and privacy/store readiness. Release AAB and commercial billing are **not configured yet**.

## Template provenance and independence

Bootstrapped from [spider-su/mobile_template / game-template](https://github.com/spider-su/mobile_template/tree/game-template), based on the MIT-licensed code there. This repository owns its own product development; **do not merge the Expo app template or game-template branches into this repository**. Port upstream fixes deliberately after reviewing differences.

See [AGENTS.md](AGENTS.md) for implementation/testing rules.
