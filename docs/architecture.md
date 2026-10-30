# Architecture

## Runtime

- Godot **4.7.2 standard / GDScript**, GL Compatibility renderer, portrait 720×1280 viewport.
- `project.godot`: app identity, display/renderer and main scene.
- `export_presets.cfg`: `com.spidersu.rescueteam`, Android **debug APK** preset, arm64.
- `scenes/main.tscn`, `scripts/rescue_game.gd`, `scripts/board_view.gd`: Phase 1 original rescue puzzle scene, touch handlers and temporary tile rendering.
- `scripts/rescue_level.gd`, `tests/test_rescue_level.gd`: data-driven deterministic rules and headless tests of the original mission.
- `.github/workflows/godot-ci.yml`: pinned Godot/editor templates, Java 17, Android SDK, headless tests, debug APK artifact.
- `docs/game-design.md` and `docs/roadmap.md`: product scope, stage gates and test expectations.

## Gameplay boundaries (first level implemented)

1. **Pure puzzle domain:** deterministic grid, unit positions, hazards, actions, win/lose rules and undo; no dependency on graphics.
2. **Level content:** explicit JSON manifest in `scripts/level_catalog.gd`, five maps under `levels/`, validation and tested win paths.
3. **Presentation:** Godot scene rendering, touch input, feedback/audio, animations and Android lifecycle.
4. **Local persistence:** `scripts/campaign_progress.gd`, versioned `user://rescue_progress_v1.json`, best move counts and corrupt-data fallback.

Keep gameplay testable headlessly; avoid abstracting Godot physics, building a custom engine, introducing a backend, or installing SDKs until the project genuinely needs them. This repository is a product derived from the MIT-licensed [mobile_template game-template](https://github.com/spider-su/mobile_template/tree/game-template), **not** a template branch to merge with Expo.
