# Rescue Team — Play Store listing draft

Use this as the source copy for the Play Console. Before publishing, replace every bracketed owner field and verify Play's current field limits and policy wording.

## Identity

| Field | Draft |
| --- | --- |
| App name | Rescue Team |
| Package | `com.spidersu.rescueteam` |
| Category | Puzzle |
| Developer name | [Developer legal/display name] |
| Support email | [Support email] |
| Privacy-policy URL | [Public HTTPS privacy-policy URL] |

## Short description

Plan smart rescues: clear hazards, save civilians and restore the city.

## Full description

Rescue Team is an original offline puzzle game about planning a safe route through a district in crisis.

Choose the right specialist, clear fires and obstacles, rescue civilians, and reach the exit. Each mission is a compact puzzle: you can undo a plan, restart instantly, and replay for a better score.

Features:

- 20 handcrafted campaign missions across Coastal District and Old Town Quarantine
- Three rescue specialists: firefighter, engineer and containment ranger
- Fires, flooded routes, bridges, gates, crates, switches and infected blockers
- Optional Floodworks trials for extra cooperative puzzles
- Contextual hints, clear obstacle messages and flexible undo/restart controls
- Named crew, restored neighbourhood addresses and cosmetic rescue rewards
- Original music and action sound effects with independent music and sound controls
- Offline play with local mission progress and no account required

Rescue Team contains no ads, in-app purchases, online account or time pressure.

## Screenshot plan

Capture final production-build images without debug overlays, device chrome or placeholder text. Select images that show the real shipped game and match the copy above.

1. Coastal District mission picker with visible restored address progression.
2. Clear puzzle board with firefighter, fire, civilian and exit.
3. Engineer operating a valve or bridge with the crew route visible.
4. Ranger containing an infected blocker in Old Town.
5. Completion screen with stars, best score and replay/next actions.
6. Crew/cosmetic screen or a location illustration showing recovery.

For each screenshot, record candidate version, device or rendered source, capture date and any crop/retouching. Do not use synthetic gameplay claims or artwork that is absent from the build.

## Console declarations to complete

- Content rating questionnaire
- Target audience and age assurance
- Data safety form, using [privacy-policy.md](privacy-policy.md) as the factual source
- Ads declaration: no ads
- App access: no account or restricted content
- Store contact and public privacy-policy link
- Countries/regions, pricing and distribution choices from the release owner

## Google Play App content — declaration worksheet (2026-11-02, draft)

For `com.spidersu.rescueteam`; this does **not** certify the release candidate or mean that Console forms were submitted. The existing [privacy policy](privacy-policy.md) is the only user-facing privacy source.

| Play Console item | Proposed answer / action | Evidence or unresolved decision |
| --- | --- | --- |
| Privacy policy URL | **Pending:** approve existing [privacy policy](privacy-policy.md), fill publisher/effective date/support and publish to a public read-only HTTPS webpage linked in app | Current draft lacks legal publisher name and support contact |
| Ads declaration | **No** | Release documentation and Godot export describe no advertising |
| App access | **All features accessible without login** | Offline game without an account or gated server content |
| Target audience | **Owner decision required** | Cartoony puzzle gameplay may appeal to children; choose intended ages truthfully and review Families obligations if children are included |
| Content rating | **Complete questionnaire in Console** | Fictional fires, disasters, infected blockers, rescue and containment actions; answer violence/fear questions based on actual visuals and gameplay, not a guessed numeric rating |
| Data safety | **Candidate: no app data collection/sharing** | Local progress/settings; no backend, ads, analytics or Internet permission in current export preset. Revalidate bundled components and signed AAB |
| Account deletion | **Not applicable** | No account creation in the documented game |

### Specific content/rights and data checks

- Local stored data: mission completion, move counts/best scores, unfinished checkpoint, audio preferences and crew cosmetic. Normal deletion is clear app storage/uninstall; account-deletion URL is unnecessary without accounts.
- No Internet permission in the inspected Godot export preset; verify final merged Android manifest, third-party plugins and actual runtime before selecting 'No data collected'.
- No advertisements or purchases appear in existing store copy; review changes before submission.
- Target audience and IARC rating are separate declarations. Discuss the portrayal of infected obstacles and hazards accurately even if the graphics are non-graphic and family-friendly.
- Verify ownership/licensing of generated assets and third-party font/music notices and the current screenshots before store approval.

### Console completion record

- [ ] Confirm legal publisher, effective date and support email in policy
- [ ] Publish public policy HTTPS page and link inside app
- [ ] Approve intended age groups after Families review
- [ ] Enter ads and app-access answers
- [ ] Submit content-rating questionnaire; retain assigned rating
- [ ] Validate exact AAB and complete Data Safety declaration
- [ ] Archive screenshot/answers, release SHA, AAB SHA-256 and review date

References: https://support.google.com/googleplay/android-developer/answer/9859455 and https://support.google.com/googleplay/android-developer/answer/9867159
