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

### Implemented and CI-verified

- [x] Original product identity, deterministic grid rules, undo/restart, local progress and safe corrupt-save fallback.
- [x] Twenty campaign missions: Coastal District 01–10 and Old Town Quarantine 11–20; three optional Floodworks trials 21–23. All 23 reference routes replay through the shipped model and earn their authored three-star scores.
- [x] Gradual content sequence: proactive guidance in Coastal 01–05; valve/water, bridge and ranger introductions in 06–09; a cooperative recap in 10; larger Old Town containment puzzles and optional Floodworks combinations afterwards.
- [x] Three specialists, fire/crate/gate/valve/bridge/infected rules, original art/audio, local audio preferences, named crew, cosmetic insignia and district recovery.
- [x] Mission-card swipe scrolling, adaptive portrait board, touch-sized controls, obstacle dialogue, action presentation, two-stage optional hints and validated unfinished-mission resume.
- [x] CI on `main` and pull requests: Godot import, eight headless suites and an arm64 debug APK. The most recent merged campaign/layout and guidance run passed on 2026-11-01: [Godot Game CI](https://github.com/spider-su/rescue-team/actions/runs/41357241491).
- [x] Stable CI debug signing and monotonic per-run Android version codes support update-over-install testing within the debug key chain. The debug APK is not a Play release artifact.

### Evidence recorded, but limited

- [x] Owner-reported Android Mission 01 happy-path completion (2026-10-30). Device model, Android version, APK commit and detailed observations were not recorded.
- [x] Desktop-rendered UI evidence and isolated production-scene regression coverage. Neither demonstrates physical-device ergonomics.

### Remaining before external pre-release testing

- [ ] Run the documented Android scenarios on at least one small and one tall physical phone: onboarding 01–05, mission scrolling, all three specialists, undo/restart, checkpoint resume, audio interruption, action pacing, Android Back and system bars.
- [ ] Record device model, Android version, commit/APK artifact, clean-install and update-over-install result, and each PASS/FAIL observation in `docs/playtest-report.md`.
- [ ] Build and validate a separately signed release AAB, then satisfy Play Console policy, listing, privacy, support and closed-track requirements.
- [ ] Conduct the Phase 5 external-player study (20–40 players) and use observed comprehension, friction and voluntary continuation to make the release decision.
