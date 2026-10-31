# Rescue Team — game concept (working design)

**Status:** twenty original data-driven missions across Coastal District and Old Town Quarantine are implemented. The owner requested the second location and third specialist after trying the coastal UI. The new ranger contains zombie-like infected with a stun shield; there are no combat timers or damage systems. Sound, difficulty tuning and detailed device acceptance remain separate.

## Player promise

**Visual direction:** original illustrated human firefighter and engineer, recognizable equipment, cream-stone coastal workshops, terracotta roofs and teal harbor water. Keep the square puzzle grid readable and decoration outside interactive cells. Mission selection, play and completion are distinct screens; see [Coastal UI](coastal-ui.md).

Solve readable, bite-sized rescue emergencies by **combining specialist abilities** instead of reflex tapping or time management. Every level is a small tactical puzzle with a safe path to extraction and no mandatory monetization interruption.

## Core loop

1. Enter a compact level with a civilian, hazards, an extraction point and two or three rescuers.
2. Select a specialist; tap a tile/target to move or perform their ability.
3. Clear hazards and operate obstacles in the right order.
4. Get the civilian to a marked safe zone; celebrate success and unlock the next level.
5. Replay instantly, or undo the last deterministic action, if a plan fails.

Target session: approximately 1–3 minutes per level; slow, thoughtful play is valid (no arbitrary timer in prototype).

## Characters and first mechanics

| Role | Distinctive ability | Prototype examples |
| --- | --- | --- |
| Firefighter | Extinguish reachable fire | Clear a corridor so the civilian can pass |
| Engineer | Push/move objects and activate reachable switches | Shift a crate to a trigger, open a gate |
| Containment ranger (Old Town) | Stun adjacent infected blockers | Clear safe passages for the other specialists; undo restores infected |
| Civilian (NPC) | Needs rescue; controlled by simple transparent rules | Escort or lead to extraction once route is safe |

**Level elements:** walls, open tiles, fire hazard, movable crate, floor switch/gate, civilian, exit. Introduce one new rule at a time and clearly signal when a move is blocked.

Old Town adds stationary infected (`Z`) and one ranger (`R`) to its ten maps. Only the ranger clears infected; others and crates are blocked. All three abilities combine in authored crate-routing and rescue puzzles. Location tabs group the chapters; original saves unlock mission 11 after mission 10. See [Old Town walkthrough counts, gestures and device scenario](old-town.md).

**Current controls:** portrait grid with level picker, local saved unlocks and animated path preview. Select by portrait button or tapping a rescuer; tap a **distant reachable destination** to walk the shortest safe route, or tap fire/a crate to approach and interact. Movement is animated tile-by-tile; each tap is one UNDO step. Unreachable/locked locations remain blocked, and RESTART resets the level. The firefighter clears adjacent fire, the engineer pushes an adjacent crate one tile, stepping onto the civilian picks them up, and carrying them to EXIT wins. On missions with a gate, the crate powers its switch.

## Implemented Phase 1 level

**Mission 04 — The Locked Corridor** preserves the original cooperative prototype: engineer pushes a crate onto a switch; firefighter extinguishes the blocking fire and carries the civilian through the open gate to extraction. Its full solution is covered by deterministic headless and scene-integration tests.

## First five missions (implemented)

1. First Response — tap-to-rescue and exit.
2. Smoke Alley — clear a blocking fire.
3. Power the Gate — engineer activates a switch.
4. The Locked Corridor — original cooperative prototype.
5. Crossed Routes — two crate pushes and longer extraction.

## Ten-level vertical slice

The manifest now contains ten authored missions. The first five introduce rescue, fire, switches/gates and cooperation; the later missions vary route length, crate placement and action ordering. Tests verify a complete solution for every mission. Content breadth does not establish device usability or external-player engagement.

Ship only after every level has at least one verified solution and tests for unwinnable/invalid state handling. Favor manual, interesting designs over generated filler.

## MVP scope

**Included in the owner-approved expansion:** 3 playable rescuer types, civilian extraction, fire/objects/mechanisms/infected interactions, 20 hand-authored missions in two locations, pause/restart/undo, local progress, simple original 2D presentation, optional sound toggle, offline Android install.

**Not included:** online accounts, multiplayer, analytics, ad SDKs, IAP, leaderboards, AI level generation, energy/life systems, 3D, complex story or long campaigns.

## Commercial validation hypotheses

- Clear enough for an unfamiliar player to understand in under a minute.
- More fun with two specialists than a generic single-character Sokoban puzzle.
- Puzzle frustration is low thanks to generous controls and undo.
- Players willingly complete more than one level and ask for more.
- If validated, consider a free demo followed by a one-time chapter unlock, but no pricing or SDK commitment yet.

## IP

The project takes inspiration from an old **gameplay genre**, not original titles, mechanics implementation code, art, levels, names, dialogue or music. Use assets with documented commercial rights and license notices.
