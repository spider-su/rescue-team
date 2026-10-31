# Architecture

## Runtime

- Godot **4.7.2 standard / GDScript**, GL Compatibility renderer, portrait 720×1280 viewport.
- `project.godot`: app identity, display/renderer and main scene.
- `export_presets.cfg`: `com.spidersu.rescueteam`, Android **debug APK** preset, arm64.
- `scenes/main.tscn`, `scripts/rescue_game.gd`, `scripts/board_view.gd`: coastal mission picker, adaptive illustrated board, touch handlers and completion screen.
- `scripts/coastal_style.gd`, `assets/coastal/`, `assets/ui/`, `assets/fonts/`: shared presentation styles, original artwork, command icons and OFL typography. See `docs/coastal-ui.md` for layout, asset provenance, tests and device scenarios.
- `scripts/rescue_level.gd`, `tests/test_rescue_level.gd`: data-driven deterministic rules and headless tests of the original mission.
- `.github/workflows/godot-ci.yml`: pinned Godot/editor templates, Java 17, Android SDK, headless tests, debug APK artifact.
- `docs/game-design.md` and `docs/roadmap.md`: product scope, stage gates and test expectations.

## Gameplay boundaries

1. **Pure puzzle domain:** deterministic grid, unit positions, hazards, actions, win/lose rules and undo; no dependency on graphics.
2. **Level content:** explicit JSON manifest in `scripts/level_catalog.gd`, twenty maps in two locations, validation and tested win paths. `levels/old-town/` introduces the optional ranger and stationary infected; original IDs and maps are unchanged.
3. **Presentation:** Godot scene rendering, touch input, feedback/audio, animations and Android lifecycle.
4. **Local persistence:** `scripts/campaign_progress.gd`, versioned `user://rescue_progress_v1.json`, best move counts and corrupt-data fallback.
5. **UI integration:** `tests/test_rescue_ui.gd` drives the production scene with an isolated save; checks screen transitions, animated routes, persistence feedback, adaptive tile input and portrait layouts. Gameplay rules do not import presentation resources.
6. **Gestures and chapter expansion:** `scripts/mission_scroll.gd` handles card/illustration swipes before child controls, suppresses duplicate emulated input and cancels card presses on drag. `tests/test_old_town.gd` replays all ten new solutions and checks role restrictions, undo and old-save compatibility. See `docs/old-town.md`.

Keep gameplay testable headlessly; avoid abstracting Godot physics, building a custom engine, introducing a backend, or installing SDKs until the project genuinely needs them. This repository is a product derived from the MIT-licensed [mobile_template game-template](https://github.com/spider-su/mobile_template/tree/game-template), **not** a template branch to merge with Expo.
