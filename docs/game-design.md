# Rescue Team — game concept (working design)

**Status:** five original data-driven levels implemented on the campaign branch; remaining five levels, art, sound and tuning are provisional.

## Player promise

Solve readable, bite-sized rescue emergencies by **combining two specialists** instead of reflex tapping or time management. Every level is a small tactical puzzle with a safe path to extraction and no mandatory monetization interruption.

## Core loop

1. Enter a compact level with a civilian, hazards, an extraction point and two rescuers.
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
| Civilian (NPC) | Needs rescue; controlled by simple transparent rules | Escort or lead to extraction once route is safe |

**Level elements:** walls, open tiles, fire hazard, movable crate, floor switch/gate, civilian, exit. Introduce one new rule at a time and clearly signal when a move is blocked.

**Current prototype controls:** portrait grid with level picker, local saved unlocks, animated path preview, movement tweening; , select by role button or tapping a rescuer, tap a **distant reachable destination** to automatically walk the shortest safe route, or tap FIRE/BOX to approach and interact. Movement is animated tile-by-tile; each tap is one UNDO step. Unreachable/locked locations remain blocked, and RESTART resets the level. Firefighter clears adjacent fire, engineer pushes an adjacent crate one tile, stepping onto the civilian tile picks them up, and a carrier reaching EXIT wins once the crate powers the gate.

## Implemented Phase 1 level

**Mission 01 — The Locked Corridor:** engineer pushes a crate onto a switch; firefighter extinguishes the fire blocking the upper passage; firefighter carries the civilian through the now-open gate to extraction. The full solution is covered by a deterministic headless test. Simple colored tiles are temporary art.

## First five missions (implemented)

1. First Response — tap-to-rescue and exit.
2. Smoke Alley — clear a blocking fire.
3. Power the Gate — engineer activates a switch.
4. The Locked Corridor — original cooperative prototype.
5. Crossed Routes — two crate pushes and longer extraction.

## Remaining vertical slice: 10 original levels

- 1–2: movement, character selection and exit.
- 3–4: fire hazard and firefighter ability.
- 5–6: movable obstacle and engineer ability.
- 7–8: switch/gate ordering.
- 9–10: combine both characters, civilian routing and a small multi-step solution.

Ship only after every level has at least one verified solution and tests for unwinnable/invalid state handling. Favor manual, interesting designs over generated filler.

## MVP scope

**Included:** 2 playable rescuer types, civilian extraction, 3 interactions (fire, objects, mechanisms), 10 hand-authored levels, pause/restart/undo, local progress, simple original 2D presentation, optional sound toggle, offline Android install.

**Not included:** online accounts, multiplayer, analytics, ad SDKs, IAP, leaderboards, AI level generation, energy/life systems, 3D, complex story or long campaigns.

## Commercial validation hypotheses

- Clear enough for an unfamiliar player to understand in under a minute.
- More fun with two specialists than a generic single-character Sokoban puzzle.
- Puzzle frustration is low thanks to generous controls and undo.
- Players willingly complete more than one level and ask for more.
- If validated, consider a free demo followed by a one-time chapter unlock, but no pricing or SDK commitment yet.

## IP

The project takes inspiration from an old **gameplay genre**, not original titles, mechanics implementation code, art, levels, names, dialogue or music. Use assets with documented commercial rights and license notices.
