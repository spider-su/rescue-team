# Fair mastery, guidance and resumable puzzles

Owner-approved next increment from the 2026-10-31 market/requirements review: correct scoring, contextual teaching and layered hints for the first five missions, unfinished-mission resume, and three puzzles prototyping one interacting environmental system. The original twenty maps keep their geometry, IDs and saved scores.

## Fair stars

The old star table used reference destination-tap counts while the actual saved counter counts individual walking steps, pushes and stuns. A reference solution for mission 11 saved 42, compared with a three-star target of 9; mission 20 saved 106 against 24. Both incorrectly earned one star.

Every shipped JSON now authors `three_star_moves` and `two_star_moves` in the existing saved metric. All 23 full reference solutions replay through the real model and must earn three stars. For example, 01 targets 4/6, 11 targets 42/62 and 20 targets 106/126. These are achievable reference scores, not proofs of optimality. Fire extinguishing remains zero moves to retain the existing score definition; walking, crate pushes, stuns and new valve/bridge actions each count one. A destination tap can contain multiple moves but still undoes as one group.

Version-1 best values remain unchanged. Stars and XP are re-derived from those existing step scores using the corrected targets; no tap-count conversion is attempted. Completion shows the three-star target when it has not yet been reached. Full-solution-to-stars assertions supplement boundary tests, preventing a repeat of the unit mismatch.

## Guidance and hints

Uncompleted missions 01–05 show a short contextual objective that advances through gate/fire/civilian/exit goals. Existing maps and controls teach walking/collection in 01, fire in 02, switching to the engineer in 03, cooperation in 04 and repeated crate pushes in 05.

Every mission offers HINT in the portrait feedback row. First tap gives a strategic nudge; SHOW gives a more specific action/role and outlines the relevant object on the actual grid (including rotated boards). REPEAT reopens that explanation. Goals track the current puzzle state and clear the highlight when the goal changes. Hints do not move pieces, charge currency, require ads or reduce rewards. They explain the current objective rather than solving an arbitrary deadlock: a crate pushed into a corner may still require UNDO/RESTART.

## Resume

The menu offers RESUME for a valid, unlocked unfinished mission. Picking another mission replaces that checkpoint; restart writes a fresh state. An empty first-state checkpoint can also be resumed.

`scripts/mission_session.gd` stores a separate version-1 `user://rescue_session_v1.json`: map ID/layout fingerprint, selected hero, hint stage and accepted grid actions grouped by destination tap. Each accepted step/ability checkpoints before its animation; an interruption mid-walk restores those accepted cells as one undo group, without replaying animation or effects. Undo and role/hint changes also update the checkpoint. A successful rescue clears it; restoring a completed trace cannot grant progress.

Loading replays every action through `RescueLevel`, rebuilding positions, hazards, carrying state, counters and undo history. It does not assign serialized model fields. Unknown roles, invalid coordinates/actions, changed layouts, completed traces, unsupported versions, corrupt JSON and oversized files fall back to the mission menu. Limits are 256 KiB, 500 destination groups and 10,000 cells. Writes use a sibling temporary file, flush and atomic rename; failed writes preserve the last committed checkpoint and show a resume-save warning. Campaign scores and audio preferences remain separate. Abrupt power-loss durability is unverified.

## Optional Floodworks trials

Trials 21–23 unlock after Coastal mission 05; each trial unlocks the next. They do not block Old Town or change the original 10→11 transition. Old Town 20 and trial 23 return to their chapter menus.

- **21 — Open the Sluice:** the engineer approaches and turns a valve (`V`), draining all flooded tiles (`~`) into ordinary walkable floor. Reference: 8 moves.
- **22 — Bridge the Gap:** after drainage, the engineer approaches a broken bridge (`=`) and repairs it, opening a shared crossing to the firefighter's rescue route. Reference: 20 moves.
- **23 — The Floodworks Relay:** combine valve/bridge ordering, fire clearing, ranger containment and crate-powered extraction. Reference: 59 moves.

Only the engineer operates valves/builds bridges, from orthogonally adjacent tiles, without moving onto the target. These actions cost one move and undo independently or with their auto-walk tap. Water blocks heroes and crates before drainage; broken bridges remain blocked until repair, which requires drainage. Valves stay occupied machinery after opening. There is no flood simulation, timer, damage or reflooding mechanic. New water/wheel/bridge visuals are original code-drawn shapes; existing action audio is reused.

## Validation and on-device scenario

CI adds `tests/test_puzzle_polish.gd` to the existing five suites. It verifies all 23 winning paths against actual star targets, legacy score interpretation, goal transitions, optional unlocks, water/bridge restrictions, full undo/restart, journal replay/corruption/write failure, carried civilians and partial walks. Production UI tests cover HINT→SHOW, progress reset, menu resume, restored undo, all three animated trials and three-star results. Test saves/preferences/checkpoints are isolated.

Desktop graphical launch is currently blocked by the host's NSXPC/LaunchServices failure before engine startup. No new native screenshot or hardware acceptance is claimed; headless UI geometry and input checks remain available.

Pending Android scenario:

1. Record device, OS, exact APK commit and install/update result. Preserve a real version-1 coastal score save if available; confirm IDs, scores and unlocks remain and corrected stars derive without replay.
2. Start 01 with a fresh test save. Follow short teaching prompts, use HINT then SHOW, and verify an outlined civilian/exit. Repeat in 02–05 for fire, engineer selection and crate/switch objectives. Check small-screen portrait controls and both grid orientations.
3. Collect a civilian, reveal a hint, background/force-stop and reopen offline. Tap RESUME. Verify exact state/selected role and undo the entire previous tap. Interrupt a longer walk: accepted steps must restore as one undo group. Check restart, switching missions and a completed rescue removing resume.
4. Complete 05 and enter Floodworks. In 21 drain water with the engineer; try another role first. In 22 try bridge repair before drainage, then drain/build/cross. Undo repair and drainage, resume a repaired crossing after app restart, then solve again.
5. Complete 23 with all three roles and check the three-star score (59 or fewer), replay/undo and return to trials. Ensure optional trials do not substitute for completing an Old Town badge.
6. Observe 20–40 external players as a later validation gate: comprehension, stuck points, hint use, satisfying discoveries and voluntary continuation. No analytics SDK is introduced by this increment.

District-recovery illustrations, richer character stories/cosmetics and reduced-motion settings remain later proposals from the review, not implemented claims in this increment.
