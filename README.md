# Rescue Team

An original Android-first rescue puzzle game in **Godot 4.7.2 stable / GDScript**.

Twenty hand-authored missions across two locations combine a firefighter, engineer and (in Old Town) a containment ranger to clear hazards, open routes and carry civilians to safety. The coastal UI uses original illustrated human characters, a harbor mission picker, an adaptive puzzle board and a dedicated completion screen. The original Mission 01 had an owner-reported Android happy-path playtest; **the new chapter and scrolling changes still need physical-device acceptance**.

## Play

Choose an unlocked mission. Tap a rescuer or their portrait to select them, then tap a destination to walk the safe shortest route. The firefighter extinguishes fire; the engineer pushes crates onto blue switches to open gates; the ranger stuns adjacent infected blockers in Old Town. Pick up the civilian and reach the green exit.

- Each destination tap is one undo step, even when it walks several tiles.
- Blocked routes show a short message from the selected hero, with varied obstacle-specific hints. The popup disappears after 4.5 seconds or your next action and never blocks tapping.
- **UNDO**, **RESTART** and **LEVELS** remain available during play, except while movement is animating.
- Completion shows actual move count, saved best, replay, undo rescue and the next unlocked mission. The final mission returns to the campaign.
- Original background music and action sounds have independent **MUSIC** / **SOUND** toggles in the mission menu; choices persist offline.
- Progress is saved offline through atomic replacement. A failed save is reported instead of announcing an unlock.
- Tall play areas may rotate a mission's visual grid clockwise; routes and taps use the original mission coordinates. No mission rules change.
- Location tabs group missions 01–10 (Coastal District) and 11–20 (Old Town Quarantine). Mission 10 unlocks the second location.
- Swipe over cards or the illustration to scroll with momentum. A drag cancels the card tap; existing coastal scores remain valid. Completion also scrolls on smaller displays.

## Develop and verify

Open `project.godot` in standard Godot 4.7.2 and run F5. From the repository root:

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_rescue_level.gd
godot --headless --path . --script res://tests/test_campaign.gd
godot --headless --path . --script res://tests/test_old_town.gd
godot --headless --path . --script res://tests/test_audio.gd
godot --headless --path . --script res://tests/test_rescue_ui.gd
godot --headless --path . --quit-after 5
```

To capture the actual scene using a graphical renderer and an isolated test save:

```bash
godot --path . --script res://tests/test_rescue_ui.gd -- --capture-dir=/absolute/path/to/screenshots
```

The UI suite verifies animated input, victory/undo/replay, next/final mission navigation, save failure feedback, tile picking in both orientations and portrait layouts. Screenshots from the suite use seeded prior completions in its test save; they do not modify a player's progress.

## Android builds

[Godot Game CI](https://github.com/spider-su/rescue-team/actions) runs the headless checks and exports an **arm64 debug APK**, uploaded as `rescue-team-debug-apk`. It uses a persistent debug keystore when configured, otherwise a temporary key that cannot update an earlier differently signed install. The package remains `com.spidersu.rescueteam`.

See [Android release and device scenarios](docs/android-release.md). APK export and desktop rendering do not establish physical-device usability. Release AAB, billing, ads, analytics, backend and cloud accounts are outside the current prototype scope.

## Design and assets

- [Music, effects and listening scenario](docs/audio.md); [original audio sources](assets/audio/README.md).
- [Game design](docs/game-design.md), [roadmap](docs/roadmap.md), [architecture](docs/architecture.md), [level format](docs/level-format.md).
- [Coastal UI specification and validation](docs/coastal-ui.md), [Old Town chapter, scroll fix and ranger rules](docs/old-town.md).
- [Artwork provenance and generation prompts](assets/coastal/README.md). [Old Town artwork and prompts](assets/old-town/README.md). Fonts include their SIL Open Font Licenses under `assets/fonts/`.
- All missions and product artwork are original. No protected legacy game assets are used.

Bootstrapped from the MIT-licensed [mobile_template/game-template](https://github.com/spider-su/mobile_template/tree/game-template). This is an independent product; port selected upstream fixes deliberately. Follow [AGENTS.md](AGENTS.md).
