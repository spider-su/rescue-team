# Rescue Team

**Original Android-first rescue puzzle game** in Godot 4.7.2 stable/GDScript, bootstrapped from [mobile_template/game-template](https://github.com/spider-su/mobile_template/tree/game-template).

**Status:** ten playable missions in the current vertical-slice PR; temporary vector-style art and movement animations. The original Mission 01 prototype was installed and completed on an Android device on October 30, 2026. The ten-mission build still needs device acceptance.

## How to play

Start from the mission selection screen. Only the first level is unlocked; finishing a mission records your best move count locally and unlocks the next mission. Tap a firefighter or engineer to select them; tap a **distant tile** to walk the safe shortest route. Tap a fire tile as the firefighter to extinguish it or a crate as the engineer to push it. Push crates onto blue switches to open gates, pick up the civilian, and carry them to EXIT. One tap is one undo action. Use **UNDO**, **RESTART**, **LEVELS** or **NEXT MISSION** to navigate.

| Mission | Mechanic introduced |
| --- | --- |
| 01 — First Response | Rescue and exit |
| 02 — Smoke Alley | Firefighter clears fire |
| 03 — Power the Gate | Engineer pushes crate onto switch |
| 04 — The Locked Corridor | Both specialists cooperate |
| 05 — Crossed Routes | Two crate pushes plus a longer rescue |

All mission maps are original \`levels/*.json\` files. The level format and validation are documented in [docs/level-format.md](docs/level-format.md). The standalone \`scripts/level_catalog.gd\` lists the playable mission manifest and validates each level before it is loaded. [docs/roadmap.md](docs/roadmap.md) tracks the remaining ten missions and polish.

## Development and tests

Install standard Godot 4.7.2, open \`project.godot\`, run F5.

\`\`\`bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_rescue_level.gd
godot --headless --path . --script res://tests/test_campaign.gd
godot --headless --path . --quit-after 5
\`\`\`

The \`Godot Game CI\` workflow builds an **arm64 Android debug APK**, runs both headless suites and a scene startup test, then uploads \`rescue-team-debug-apk\` as an Actions artifact. [Download builds from Actions](https://github.com/spider-su/rescue-team/actions).

CI uses a **new debug signing key per run**, so uninstall the previous build before installing a new APK. Release AAB, stable signing, ads, monetization, backend and cloud accounts are deliberately out of scope. See [docs/android-release.md](docs/android-release.md) before Google Play distribution.

## Project scope

- **Implemented:** ten validated mission maps, two roles, safe pathfinding, tile-step animations and route preview, undo/restart, level selection, offline saved progress and deterministic win-path tests.
- **Not yet completed:** ten-level campaign, professional original graphics/sound, broad real-device acceptance, 20–40 external playtesters and commercial validation.

Use original or properly licensed game assets only. Check [AGENTS.md](AGENTS.md), [docs/architecture.md](docs/architecture.md), and [docs/game-design.md](docs/game-design.md) before development.
