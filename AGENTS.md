# Rescue Team — development instructions

This repository is a product, not the upstream game-template. **Godot 4.7.2 stable / GDScript / Android-first**. Use the inherited template's tested CI workflow as the baseline.

## Read before modifying

1. `README.md` and `docs/game-design.md` for goals and deliberately excluded features.
2. `docs/roadmap.md` for milestone gates and acceptance criteria.
3. `docs/architecture.md` and `docs/android-release.md` for technical and native constraints.
4. Actual scripts/scenes/tests; documentation does not override source.

## Engineering rules

- Start with **one playable rescue puzzle** and then a ten-level vertical slice. No speculative generic framework, multiplayer, backend, cloud saves, auth, procedural generation or billing.
- Use Godot built-in 2D tilemaps/physics only as required. Prefer deterministic grid/turn-based puzzle rules separated from scene rendering, with headless tests.
- For input, favor forgiving touch selection, explicit undo/restart, visual feedback and large targets. Validate on real Android hardware.
- Keep every asset, character, level, name, story and sound original or properly licensed. Do not extract or reuse protected Java ME game assets.
- Keep package ID `com.spidersu.rescueteam` stable for this product. Never commit keys or tokens.
- Do not add ads/IAP/analytics before the relevant roadmap gate.
- New gameplay requires tests for the deterministic rules and at least one documented on-device playtest scenario.

## Quality gate

Run `godot --headless --path . --editor --import --quit`, `godot --headless --path . --script res://tests/test_rescue_level.gd` and the Android APK CI workflow. Add assertions for new rule variations; CI must keep the full winning path executable. A green CI does **not** establish real-device usability.

For PRs: record scope, scene/script changes, tests and exact results, APK link, Android device or emulator evidence, known limitations and roadmap milestone. Keep changes focused.
