# Rescue Team — delivery roadmap

This document describes **planned work**, not already implemented features. Follow the go/no-go gates; avoid building a full content library before the central mechanic is tested.

| Phase | Deliverable | Gate / acceptance |
| --- | --- | --- |
| 0. Bootstrap | Godot project, product identity, docs, headless checks, CI-generated Android debug APK | CI green, build artifact uploaded; real-device verification remains separate |
| 1. Core gameplay | One fully playable original rescue level, deterministic grid state and touch interactions | Select/move both rescuers; fire/objects/exit function; level winnable and restartable |
| 2. Interaction rules | Firefighter/engineer actions, fire, crate, gate/switch, civilian extraction, undo | Unit tests cover valid/invalid actions and undo; blocked states are explained |
| 3. Vertical slice | Ten curated levels with local unlock progress | Every level solvable, no state corruption after app restart, no network required |
| 4. Mobile polish | Original art/audio, onboarding, pause/resume, accessibility-sized touch targets, display/OS handling | Android device smoke checks, no blocked controls, responsive input |
| 5. External validation | 20–40 playtesters and qualitative/quantitative evidence | Majority understand controls; observe voluntary replay/multi-level engagement; decide go/no-go |
| 6. Commercial release (conditional) | Store listing, privacy/data-safety, stable signing, Android App Bundle, closed tests, optional full unlock | Evidence of demand and successful Android release tests, not just green source CI |

## Suggested implementation increments

1. **Game state model:** grid, positions, tile types, turn/action rules. Unit tests with hand-built fixtures.
2. **Level schema/loader:** serialize level, validate reachable exit and entities. Document schema.
3. **One scene:** draw grid, select rescuer, tap-to-move or interact, clear fire, reach civilian and exit.
4. **Undo/restart:** snapshot or reverse actions, preserve determinism and handle unwinnable puzzles.
5. **Level series:** introduce mechanics gradually, store completed/unlocked level state locally.
6. **Android UX:** touch targets, pause/resume, system bars, sound and device testing.

Prefer a small focused PR for each increment; do not combine all milestones in one large change.

## Quality and release criteria

- **Continuous:** Godot editor import, headless gameplay tests and Android debug APK CI remain green.
- **Prototype:** one actual rescue scenario is fun without rewards/ads; demo score-tapper is removed when the first level is playable.
- **Vertical slice:** ten distinct puzzles, expected solutions verified, no blockers, offline persistence on device.
- **Validation:** test with players who did not develop the game and compare against relevant rescue-puzzle competitors.
- **Release:** correct versioning, original licensed assets, store policy review, signed AAB and install/update tests on real devices.

## Current snapshot

- [x] Project bootstrapped from Godot game-template and identity set.
- [x] CI workflow configured for `main`, feature branches and pull requests.
- [ ] CI green **in this repository** (must be verified from Actions).
- [ ] Rescue puzzle gameplay implemented.
- [ ] On-device smoke test completed.
- [ ] Commercial metrics validated.
