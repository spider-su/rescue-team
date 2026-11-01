# Old Town Quarantine expansion

Two locations now group 20 missions: Coastal District (01–10) and Old Town Quarantine (11–20). Location tabs can preview both chapters; mission 11 unlocks after completing mission 10. Existing version-1 progress, IDs 01–10 and best scores remain valid. Mission 10 offers NEXT LOCATION; mission 20 returns to the completed second chapter.

The owner reported that the prior UI worked but mission scrolling was difficult (2026-10-31); device model/OS and detailed evidence were not provided. This revision addresses scrolling and expands the campaign. Its hardware acceptance remains separate.

## Mission scrolling

`mission_scroll.gd` owns touch and mouse drag gestures before card controls can consume them. A 10-unit vertical threshold distinguishes taps from drags. Crossing the threshold cancels card press attempts, consumes the drag/release, and applies a short inertial coast. A tap stops active coasting before a subsequent tap can launch a mission. Emulated mouse events from real touches are suppressed during the gesture to prevent duplicate actions.

The chapter illustration now sits inside the scroll content instead of permanently consuming list space. Swipes can start over cards, locked cards, the illustration or gaps. A wider scrollbar remains usable. Focus-following is disabled to prevent a card pulling the list back after a drag. Changing location resets to its banner/first mission; starting play stops momentum.

## New specialist and rule

- **Ranger:** violet portrait/uniform and a nonlethal stun shield. Tapping an infected target plans a safe route to an adjacent tile and clears that target in one action. The ranger remains on the approach tile; the cleared tile is then ordinary floor.
- **Infected (`Z`):** stationary blocked tiles. They do not attack, move, cause damage or introduce timing. Only the ranger can clear them; firefighter/engineer movement and crate pushes cannot enter an occupied infected tile.
- **Firefighter/engineer:** their existing abilities remain unchanged. Rangers cannot extinguish fire or push crates. All rescuers can carry the civilian.
- Undo restores every infected tile, positions, carrying state and counter. A complete auto-walk/stun tap remains one undo step. Restart restores the authored map.
- New Old Town maps include one ranger (`R`) and one to five infected; validation supports at most one ranger and six infected, and rejects infected without a ranger. Coastal Mission 08 is the earlier one-blocker ranger preview; Old Town remains the full containment chapter.

## Ten authored puzzles

These are static, original JSON maps with explicit walkthroughs in `tests/fixtures/old_town_solutions.json`; no runtime procedural generator was added. Every solution is replayed against the actual pathfinder/action rules and then fully undone. Counts below describe the verified walkthrough, not a proven optimal solution.

| ID | Mission | Planning focus | Taps / moves / infected |
| --- | --- | --- | --- |
| 11 | First Containment | Introduce ranger; clear fire, contain infected, power gate, escort | 9 / 42 / 1 |
| 12 | East Gate Supply | Work from the opposite side before opening the east gate | 11 / 51 / 2 |
| 13 | Courtyard Turn | A north-south courtyard changes the crate and ranger approaches | 11 / 52 / 3 |
| 14 | Southbound Delivery | Start at the far end and stage the crate before the long rescue | 13 / 57 / 2 |
| 15 | Market Return | Reverse the market flow, then bring the crate home | 14 / 68 / 3 |
| 16 | Lantern Relay | A diagonal street separates the three specialists before the gate | 18 / 62 / 3 |
| 17 | Recessed Switch | Reach the recessed switch from the opposite side of the block | 17 / 72 / 3 |
| 18 | Clocktower Crossroads | Right-angle lanes change the order of the crate route | 17 / 72 / 3 |
| 19 | Northern Approach | A flipped district makes the rescue lane the final commitment | 14 / 68 / 3 |
| 20 | Last Light Evacuation | Interleave ranger, engineer and firefighter; turn the crate and reverse its direction | 24 / 106 / 5 |

The larger boards and ability ordering make the verified routes longer than the original chapter. Player-perceived difficulty still needs playtesting; walkthrough length is not a difficulty measurement by itself.

## Verification and device scenario

CI runs rule, original campaign, Old Town and UI suites. The Old Town suite checks all ten winning paths, invalid roles/ranged actions, crate/infected blocking, full undo/reset and old-save compatibility. The UI suite sends touch and mouse events through the real viewport: card swipes must scroll without launching a mission; ordinary taps must still work. It tests both chapter groups, 10→11 progression, three-portrait layouts and complete animated missions 11/20.

Rendered desktop evidence is under `docs/evidence/2026-10-31-old-town/`. The UI test uses an isolated save with seeded prior completions. Desktop rendering and green export do not establish Android ergonomics.

Pending on-device scenario:

1. Record device, OS, exact APK commit and install/update result. Keep an existing completed coastal save when possible.
2. Swipe repeatedly on available/locked cards and the illustration, quickly reverse direction, stop a fling, then tap a card. Verify smooth movement, no snap-back and no accidental launch. Check all ten cards in each group and both tabs.
3. With Coastal 10 complete, enter Old Town 11. Select the ranger by portrait and sprite; tap the infected from far away. Verify safe approach, stun pulse, feedback and cleared passage. Try the other roles: they must remain blocked.
4. Undo the entire ranger tap, restoring the infected and original position; restart. Complete 11, reopen the app offline, and verify both old scores and the new unlock.
5. Complete the ordering puzzle in 20 using all three specialists. Check undo after several ability switches and final completion navigation. Check portrait selection/grid targets on a smaller phone, background/resume and Android Back.

Artwork is original built-in ImageGen output under `assets/old-town/`; its README records prompts and atlas usage. No health bars, ammunition, combat timers, accounts, ads or billing were introduced.
