# Rescue Team — release handoff

This is the release checklist for the Android **0.1.0** vertical slice. It separates facts demonstrated by source/CI from evidence required before a closed test or public Play release. Do not mark a track ready solely because an APK exports.

## Current build facts

| Item | Current value |
| --- | --- |
| Application ID | `com.spidersu.rescueteam` |
| First Play upload candidate | `0.1.0` / version code `1`; debug APK codes follow a separate CI run counter |
| Delivery artifacts | arm64 debug APK; opt-in signed release AAB from manual `Godot Game CI` dispatch |
| Stable debug updates | Configured with the private `ANDROID_DEBUG_KEYSTORE_BASE64` Actions secret |
| Release upload signing | Separate upload key configured with three `ANDROID_RELEASE_KEYSTORE_*` Actions secrets |
| Content | 20 campaign missions and 3 optional Floodworks trials |
| Connectivity | No `INTERNET` permission; no account, ads, analytics, billing or backend |
| Local data | Mission progress, best scores, unfinished mission checkpoint, audio preferences and selected cosmetic |
| Automated proof | Godot import, deterministic gameplay/data/UI/audio/action tests and Android debug export in CI |

The debug signing key supports repeatable **test APK** upgrades. It is not a Play release key and must never be used for an AAB or production signing.

The first signed release bundle was built and verified in [run 41460812065](https://github.com/spider-su/rescue-team/actions/runs/41460812065), source `ea291a045ae142ce6809f2e179fa5540d184dea7`. It passed the eight existing suites, bundletool validation, JAR signature/certificate checks and package/version/ABI/non-debuggable/offline-manifest assertions. It has not been uploaded to Google Play or validated on physical devices as a release bundle. For future uploads, use a version code not previously used in Play.

## Release gates

### Before inviting closed-test players

- [ ] Set the candidate version name and increment `version/code` in `export_presets.cfg`.
- [x] Build and verify an initial signed AAB with a dedicated upload key; credentials remain outside the repository.
- [ ] Back up the upload keystore and credentials to separate secure owner-controlled storage before continuing Play releases.
- [ ] Confirm Play Console target-SDK and policy requirements for the build date.
- [ ] Run the full CI workflow at the candidate commit and retain its run URL and artifact/checksum.
- [ ] Run the scenarios in [Android release and device scenarios](android-release.md), [audio](audio.md#android-listening-scenario-pending), [Old Town](old-town.md#verification-and-device-scenario), [puzzle polish](puzzle-polish.md#validation-and-on-device-scenario), and [emotional progression](emotional-progression.md#verification-and-android-scenario).
- [ ] Record results using [the playtest report](playtest-report.md) on at least one small and one tall Android phone.
- [ ] Verify a new install and update-over-install from the immediately preceding candidate. A device installed with an older temporary-key APK must be uninstalled once before it can enter the stable-debug update chain.
- [ ] Complete all bracketed owner fields in the store listing, privacy policy and support route.

### Before public production release

- [ ] Close all release-blocking defects found in the closed test and rerun the affected scenarios.
- [ ] Review the final listing, screenshots, icon, feature graphic, content rating and data-safety form in Play Console.
- [ ] Confirm the privacy policy is published at a public, stable URL and its support contact works.
- [ ] Recheck asset attribution and commercial-use records in `assets/`; retain originals and license evidence privately.
- [ ] Verify crash-free launch, touch comfort, orientation/system bars, pause/resume, offline persistence, sound interruption and performance on the final AAB.
- [ ] Archive the exact AAB, SHA-256, CI run URL, Play version code, test evidence and signing-key recovery location in private release records.

## Candidate procedure

1. Choose the version and update `export_presets.cfg`, `CHANGELOG.md` and the store copy if player-visible scope changed.
2. Run the required Godot checks and CI. Record the commit SHA and result URLs in the playtest report.
3. Produce and sign the AAB in the controlled release environment. Verify its package ID, version code, signature and target ABI before upload.
4. Upload to an internal Play track first. Install it on clean devices, then test an update from the preceding internally distributed candidate.
5. Execute the scripted device scenarios and collect concise tester reports. Triage defects by reproducibility and player impact.
6. When the closed-test gate is met, fill the final Play listing from [store-listing.md](store-listing.md), publish [privacy-policy.md](privacy-policy.md) at the chosen URL, and submit the required console declarations.

## Known boundaries

- A signed AAB upload candidate exists, but Play submission, policy acceptance and release-bundle device validation remain pending.
- Existing automated and desktop-rendered evidence does not prove real-device ergonomics, interruption handling or subjective animation/audio quality.
- The project intentionally has no telemetry. Decisions from external validation therefore need consented qualitative reports rather than inferred analytics.
- Contact details, public privacy-policy hosting and Play Console declarations are owner-controlled inputs and remain incomplete until supplied and published.

## Historical real-device owner smoke (reported 2026-11-01)

**PASS (owner-reported):** an earlier Android build installed on a physical Android device and the primary rescue mission end-to-end happy path completed. The README independently records a Mission 01 owner test. Original device/OS/build hash/date were not recorded. This establishes an earlier install-and-play milestone, **not** physical-device validation of newer chapters, audio, hero dialogue, scroll behavior, release AAB or update-over-install. The release gates above remain open.

## Documentation and licensing alignment

Reuse the existing [privacy policy](privacy-policy.md), [store listing](store-listing.md), [playtest report](playtest-report.md) and asset provenance docs rather than making duplicate policies. Fill publication date, publisher legal name, public privacy URL and support email; inspect the final APK/AAB permissions and SDK inventory before asserting no transfer. Keep the existing MIT repository license and required asset/font notices. Check Google Play Data safety, target audience and content rating, even for an offline game without accounts or ads. A separate user-facing EULA is optional pending publisher/legal review; the MIT source license is not a substitute for user privacy disclosures.
