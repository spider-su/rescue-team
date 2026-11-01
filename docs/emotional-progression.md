# Crew and district recovery

The game now turns completed rescues into small, local signs of recovery without changing puzzle rules, star targets or saved scores.

- Maya (firefighter), Theo (engineer) and Nia (ranger) have short, original personality lines when selected and after a rescue. Obstacle guidance continues to use the selected hero's name.
- The active location's mission illustration contains one address for each mission. An address changes from damaged to restored only after that mission has a saved completion.
- Cosmetic crew insignia unlock from saved completions: Rescue ribbon after 1, Harbor colours after 5, Captain star after 10, and Floodworks crest after all three optional trials. They are visual only and do not alter gameplay, scores or unlocks.
- The selected insignia is stored separately in `user://rescue_crew_v1.cfg` using atomic replacement. A failed write is visible in the menu and the choice remains session-only.

## Verification and Android scenario

Headless coverage in `tests/test_crew_progression.gd` verifies reward thresholds, local persistence/failure handling, varied lines and the district-to-save mapping. `tests/test_rescue_ui.gd` verifies the first on-scene recovery, named victory line and equipped board/portrait emblem.

On an Android device, start with a fresh local save and complete Mission 01. Return to the mission list: address 01 should become restored, the Rescue ribbon should be selectable under **CREW**, and it should appear on portraits and board sprites. Close and reopen offline to confirm the selected insignia remains. Complete more missions to verify the 5- and 10-rescue rewards; finish trials 21–23 to verify the Floodworks crest. Record APK commit, device and Android version, whether the recovery art and picker remain readable at the smallest tested screen, and exact result. Automated checks do not establish hardware usability.
