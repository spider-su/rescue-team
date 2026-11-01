# Changelog

All notable product-facing changes are documented here. The project is pre-release; versioning follows the Android version name and code selected for each candidate.

## 0.1.0 — unreleased vertical slice

### Added

- Twenty authored campaign missions in Coastal District and Old Town Quarantine.
- Three optional Floodworks trials.
- Firefighter, engineer and containment ranger puzzle abilities.
- Contextual teaching, two-stage hints, undo/restart, resumable unfinished missions and local progress.
- Original human crew art, named heroes, district recovery and cosmetic insignia rewards.
- Original theme music, action effects, mute controls and lifecycle-aware audio handling.
- Clear obstacle feedback and specialist action animations.

### Changed

- Coastal Missions 06–09 now introduce valve/water, bridge and ranger mechanics one at a time before a short relay.
- Mission lists support touch drag scrolling with inertial coast and drag-to-tap cancellation.
- CI debug APKs now use a persistent repository signing key for repeatable test-device updates.

### Known release limitations

- The current CI artifact is an arm64 debug APK, not a Play-ready signed AAB.
- Android hardware acceptance for the expanded campaign, scrolling, audio, animations and lifecycle handling remains to be recorded.
