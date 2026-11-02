# Android emulator regression — 2026-11-02

Tested the CI APK for `c3d982afb54ab1d71c57d8dc274baa4c991d669d` (PR #29), using ADB touch input against the production Godot scene. The APK was downloaded from [successful run 41418375868](https://github.com/spider-su/rescue-team/actions/runs/41418375868). It was not rebuilt with test instrumentation. Full provenance is in `manifest.json` and `ci-source.json`.

## Environment and method

- Package `com.spidersu.rescueteam`; version `0.1.0`, code `1094`; arm64 debug APK.
- APK SHA-256: `09d8af430b34edf0ec515e68abb662335390b4adaca4f5fde78a9a2ebe25aecb`.
- AVD `world-maps-poc`, serial `emulator-5554`, `sdk_gphone64_arm64`, Android 15 / API 35. `ro.kernel.qemu=1` was checked before installing or changing settings.
- Original display 1080×2400 / 420 dpi / gesture navigation; additional layout check at 720×1280 / 280 dpi / three-button navigation. Display and navigation settings were restored afterwards.
- Windowed emulator startup failed on this host. The emulator ran with `-no-window -no-snapshot -gpu swiftshader -no-audio`; screenshots are actual Android framebuffer captures. Audible output and hardware performance are unverified.
- Used the World Maps `android-emulator-smoke` skill's target verification, source-matched install, navigation, persistence, screenshot and restoration workflow, adapted to Godot and Rescue Team's authored fixtures. No Expo build or World Maps gameplay assumptions were applied.
- Started without an installed Rescue Team package. All tested mission unlocks were earned through real taps; no completion data was seeded. Destination taps followed the checked-in fixture coordinates, transformed using the board's current layout. Screenshots were captured after each destination; persisted results were checked through the debug app's `run-as` access.

## Results

| Scenario | Result | Evidence / observation |
| --- | --- | --- |
| Clean install, offline launch and mission picker | PASS | `01-launch.png`; emulator was already in airplane mode. |
| Initial training prompt and target | FAIL — wording | `02-mission01-training.png` calls the civilian Maya, but the selected firefighter is Maya. The target outline and input function. |
| Multi-tile pickup, grouped undo and checkpoint resume | PASS | `03`–`06` screenshots; undo removed the complete destination group; force-stop/relaunch offered RESUME and restored carrying state. |
| Coastal 01–10 full winning paths and three-star reference scores | PASS | All ten completed naturally; persisted scores below. `07-mission01-victory.png` and `mission02`–`mission10` screenshots/save snapshots. |
| Wrong-role fire tap and obstacle message | PASS | `09-engineer-fire-rejected.png`; rejected engineer command left the action journal empty. Subsequent firefighter taps completed the mission. |
| Gate/crate and combined specialist puzzles | PASS | Missions 03–05/10 completed with the reference scores. |
| Valve, bridge and ranger actions | PASS | Missions 06–09 and trials 21–23 completed through input with their reference scores. Settled screenshots do not measure frame pacing. |
| Coastal → Old Town unlock/navigation | PASS — copy defect | `mission10-step07.png` offers NEXT LOCATION; it opens Mission 11 with three roles (`10-old-town-entry.png`). The message incorrectly says the ranger joins now, despite Mission 08 introducing the ranger. |
| Old Town 11 complete rescue | PASS | 42 moves; all three roles exercised, saved victory in `mission11-step09.png`. |
| Android Back, card swipes, locked cards and location tabs | PASS | `11-android-back-menu.png`, `12-old-town-scroll-bottom.png`, `13-floodworks-menu.png`; swipe stayed in the menu, and Floodworks 21 was available after earning Coastal 05. |
| Floodworks 21–23 completion | PASS | Scores 8/20/59; `mission21`–`mission23` screenshots and saved progress. |
| District recovery and earned insignia | PASS | `14`–`16` screenshots; all three trial addresses restored; Floodworks crest was selectable/equipped after their actual completion. |
| Independent mute controls and persisted local data | PASS | Music was turned off while sound remained on, then sound was turned off. Progress, both mute settings and selected crest were byte-identical after force-stop/relaunch; `before-relaunch-*` files and `17-cold-relaunch-saved-mutes.png`. |
| Small display / three-button layout and Back | PASS — layout smoke only | `18`–`20` screenshots show the menu and Mission 11 controls above system navigation. Smaller-screen mission completion was not replayed. |
| Small display / gesture layout | PASS — layout smoke only | `21-small-gesture-menu.png`. Settings were restored to original values afterwards. |
| Actual APK upgrade and save preservation | PASS | Prior CI code 1092 was installed with debug downgrade permission as test setup, then launched. Code 1094 was installed with ordinary `adb install -r`, without uninstalling or clearing data. Progress, audio, cosmetic and checkpoint files stayed byte-identical; see `upgrade-result.txt`, version records and `before-upgrade-*` / `after-upgrade-*`. |
| Old Town 12–20, full screen-reader coverage, native audio focus, audible music quality, physical device, Play AAB | NOT TESTED | These require additional focused runs; this evidence does not close their release gates. |

Reference scores observed: 01=4, 02=6, 03=8, 04=9, 05=13, 06=9, 07=20, 08=14, 09=11, 10=13, 11=42, 21=8, 22=20, 23=59. All match the checked-in three-star targets. Mission 01 completed before the scripted replay helper was introduced; its saved score is included in every later progress snapshot.

## Findings to resolve

1. **P2 — Civilian called Maya in onboarding:** start uncompleted Mission 01. Both its objective and hero prompt say to pick up Maya while the firefighter portrait is also named Maya. Expected: distinguish the civilian from the rescuer. Reproduced again on later pickup/exit goals; screenshot `02-mission01-training.png`.
2. **P3 — Ranger introduction copy is stale:** complete Mission 10 after playing Mission 08. The result says “Ranger joins the crew.” Expected: acknowledge the existing ranger and introduce the district. Screenshot `mission10-step07.png`.
3. **Layout observation:** the tall 1080×2400 display leaves substantial black space above/below the game. Controls remain visible; review aspect-ratio and safe-area use before calling the layout polished. The 720×1280 device simulation also leaves side margins.

No gameplay fixes were made during this evidence run. A general claim of release readiness is not supported by these results.

`runtime-log.txt` contains Godot/AndroidRuntime output. It records shader-cache recompilation warnings after cold launches; the captured log has no `SCRIPT ERROR` or `FATAL EXCEPTION`. Native screen-reader, light/dark adaptation, loading/error harnesses and audible interruption tests were not exercised. `replay-reference.py` preserves the exact destination-tap replay helper: manually open an uncompleted mission on the original 1080×2400 layout before invoking it with that mission ID. It uses fixed board bounds for this recorded device configuration and is not a general cross-device automation harness.
