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
- Show chapter milestones at 10, 20 and 30 stars for the first ten missions; rewards are cosmetic badges, never required to unlock missions.
- Initial badges: First Rescue (complete one), Harbor Guardian (complete ten), Perfect Planner (three-star one mission), Master Rescuer (three-star all ten).
- Badge unlocks are derived from saved best scores and validated thresholds, avoiding redundant mutable state.

## Visual feedback
- Completion: short staggered star reveal, expressive character celebration, subtle particle/confetti effect, optional sound/haptics, and reduced-motion fallback.
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
- UI tests cover star display, progress totals, badges, replay, small screens and reduced motion.
- Headless gameplay tests and Android APK CI stay green.

## Delivery
1. Add authored star thresholds to each level and validation/tests.
2. Derive reward state from saved best moves.
3. Integrate stars and new-best feedback in mission cards/completion.
4. Add campaign progress and cosmetic badges.
5. Add brief animation/sound and test on Android.

Do not add currency, shop, backend, ads, analytics, streaks, or time pressure in this milestone.

## Implementation note

The presentation layer now plays short, deterministic, skippable-on-screen-change tween sequences for walking, water spray, crate push, civilian pickup, ranger stun, and rescue celebration. The score thresholds for 11–20 use the tested reference completion routes; these are achievable, not proven optimal. Rewards retain the v1 save schema and are derived from saved best moves. Real-device animation comfort and reduced-motion accessibility are follow-up validation items.

## Corrected score units

The shipped reference thresholds previously used destination-tap counts against saved per-step scores. Targets now live in each map as `three_star_moves`/`two_star_moves`, using the actual saved counter, with all 23 full reference routes required to earn three stars. Existing v1 best values are retained and stars re-derived. Achievable reference routes are not optimality proofs. Optional trial completions cannot substitute for completing Old Town when deriving its badge. See `puzzle-polish.md`.
