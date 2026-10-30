# Architecture

## Runtime

- Godot **4.7.2 standard / GDScript**, GL Compatibility renderer, portrait 720×1280 viewport.
- `project.godot`: app identity, display/renderer and main scene.
- `export_presets.cfg`: `com.spidersu.rescueteam`, Android **debug APK** preset, arm64.
- `scenes/main.tscn`, `scripts/demo_game.gd`: inherited **technical test scene**; replace during phase 1.
- `scripts/game_session.gd`, `tests/test_game_session.gd`: inherited score model/tests, not real rescue domain logic.
- `.github/workflows/godot-ci.yml`: pinned Godot/editor templates, Java 17, Android SDK, headless tests, debug APK artifact.
- `docs/game-design.md` and `docs/roadmap.md`: product scope, stage gates and test expectations.

## Planned gameplay boundaries (not yet implemented)

1. **Pure puzzle domain:** deterministic grid, unit positions, hazards, actions, win/lose rules and undo; no dependency on graphics.
2. **Level content:** data-driven 2D tile definitions and validation; simple human-readable format preferred.
3. **Presentation:** Godot scene rendering, touch input, feedback/audio, animations and Android lifecycle.
4. **Local persistence:** completed levels and optional settings; versioned storage and safe fallback for corrupt data.

Keep gameplay testable headlessly; avoid abstracting Godot physics, building a custom engine, introducing a backend, or installing SDKs until the project genuinely needs them. This repository is a product derived from the MIT-licensed [mobile_template game-template](https://github.com/spider-su/mobile_template/tree/game-template), **not** a template branch to merge with Expo.
