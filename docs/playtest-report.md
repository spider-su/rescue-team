# Rescue Team — Android playtest report

Use one copy of this report per device and candidate. Attach screenshots or a short screen recording only when they clarify a failure. Do not include personal account data.

Recorded emulator run: [2026-11-02 Android API 35 regression](evidence/2026-11-02-android-emulator/README.md) covers Coastal 01–10, Old Town 11 and Floodworks 21–23, checkpoint/cold-launch persistence, smaller-screen layouts and APK update-over-install. It records two copy defects and a layout observation; physical-device acceptance remains pending.

## Build and device

| Field | Result |
| --- | --- |
| Tester ID or initials | |
| Date / time zone | |
| Candidate version and version code | |
| Commit SHA / CI run URL | |
| Install source | Internal Play / stable-debug APK / other: |
| Install result | Clean install / update-over-install / failed (exact error): |
| Device model | |
| Android version | |
| Display size / refresh rate if known | |
| Audio route | Speaker / wired / Bluetooth |

## Required checks

Mark each item **PASS**, **FAIL** or **NOT TESTED** and give a short observation for anything other than PASS.

| Check | Result | Notes |
| --- | --- | --- |
| App launches and mission picker is usable | | |
| Mission-card scrolling works from cards, artwork and gaps | | |
| Tap target selection and a multi-tile walking route feel responsive | | |
| Firefighter, engineer and ranger actions animate clearly | | |
| A blocked fire, gate, crate and infected route shows a suitable hero message without blocking a valid tap | | |
| Undo and restart preserve the expected puzzle state | | |
| Complete Missions 01, 06, 08, 10, 11 and 20 or note the first blocker | | |
| Coastal to Old Town unlock/navigation works | | |
| Optional Floodworks trial opens after Mission 05 | | |
| Progress, best score, cosmetic selection and audio settings persist after force-stop and offline relaunch | | |
| Music/effects mute independently; Home/lock/return does not leave audio playing or replay a burst | | |
| Android Back, status/navigation bars and a small/tall screen keep actions reachable | | |
| A long route has steady pacing; immediate Undo after an effect remains correct | | |
| Fresh install and update-over-install preserve expected data | | |

## Player feedback

1. What did you think the objective and each hero could do before Mission 03?
2. Where, if anywhere, did controls, scrolling, text, animation or sound feel unclear or uncomfortable?
3. Which mission felt most satisfying and which felt frustrating? Why?
4. Did you choose to replay or continue after the first completed mission? Why?
5. Would you play another chapter? What would you want next?

## Defects

For each defect, record steps to reproduce, expected/actual behavior, frequency, severity, and evidence filename. Never report a defect as fixed until it is retested on the same affected condition.

## Previous owner's Android test (not candidate evidence)

Recorded from owner confirmation on 2026-11-01: **PASS**, earlier Android APK installed on a physical device and an initial rescue mission's end-to-end flow completed. The exact APK SHA, Android device/OS and original execution date are unknown. This is historical evidence only; leave the blank candidate fields and full current-device checklist above untouched until the current build is actually tested. In particular, the expanded 20-mission campaign and later UI changes are not covered by this pass.
