# Reward system specification

## Goals
Make every rescue satisfying, reward mastery, and motivate replay without timers, ads, daily streaks, or online dependencies.

## Mission stars
- Completing a mission always awards at least one star and unlocks the next mission.
- Two and three stars depend on authored per-level move thresholds, not a universal formula.
- Thresholds must be validated against known solutions; 3-star threshold >= verified achievable minimum, 2-star threshold >= 3-star threshold.
- Display move count, prior best, earned stars, new-best indicator and next target on the completion screen.
- The best result and highest earned star tier are monotonic. Replays never reduce progress.
- No stars are awarded for an uncommitted victory if saving fails.

## Campaign
- Show total stars earned / 3 × mission count on the mission picker.
- Show location completion and stars in the mission picker, plus the total XP/rank profile.
- Cosmetic-only crew insignia unlock after 1, 5 and 10 completed missions; the Floodworks crest unlocks only after completing trials 21–23. No reward changes puzzle strength, access or score targets.
- Insignia unlocks are derived from committed completion records, avoiding redundant mutable state.

## Visual feedback
- Completion: expressive character celebration, confetti and a victory sound, with immediate Next, Replay, Undo rescue or Levels controls after the animation.
- Mission cards: earned stars and personal best; locked cards remain distinguishable.
- No blocking animation; allow immediate Next, Replay or Levels.

## Persistence and migration
- Existing `user://rescue_progress_v1.json` files must remain valid; retain best move counts.
- Prefer derived star counts from existing best values and authored thresholds. If schema extension is necessary, version and migrate safely.
- Preserve atomic write and rollback-on-failure behavior.

## Tests
- Exact boundary values for each star tier; no victory before completion.
- Replaying worse never lowers best/stars; better replay improves both.
- Existing saves load and derive appropriate rewards.
- Save failure never announces durable reward.
- UI tests cover star display, progress totals, insignia, replay, small screens and animated action cleanup.
- Headless gameplay tests and Android APK CI stay green.

## Delivery
1. Keep authored star thresholds and reference routes in sync when adding a map.
2. Preserve derived rewards when changing save or progression code.
3. Validate animation/audio comfort on Android hardware before treating presentation polish as accepted.

Do not add currency, shop, backend, ads, analytics, streaks, or time pressure in this milestone.

## Implementation note

The presentation layer now plays short, deterministic, skippable-on-screen-change tween sequences for walking, water spray, crate push, civilian pickup, ranger stun, and rescue celebration. The score thresholds for 11–20 use the tested reference completion routes; these are achievable, not proven optimal. Rewards retain the v1 save schema and are derived from saved best moves. Real-device animation comfort and reduced-motion accessibility are follow-up validation items.

## Corrected score units

The shipped reference thresholds previously used destination-tap counts against saved per-step scores. Targets now live in each map as `three_star_moves`/`two_star_moves`, using the actual saved counter, with all 23 full reference routes required to earn three stars. Existing v1 best values are retained and stars re-derived. Achievable reference routes are not optimality proofs. Optional trial completions cannot substitute for completing Old Town when deriving its badge. See `puzzle-polish.md`.
