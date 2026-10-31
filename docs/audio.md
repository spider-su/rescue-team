# Music and action audio

The game plays an original 40-second hopeful harbor theme across menus and missions, with twelve short synthesized effects. See [audio provenance and generation](../assets/audio/README.md). The score is shared by both locations in this first pass.

The mission menu offers independent **MUSIC: ON/OFF** and **SOUND: ON/OFF** controls. Preferences live in `user://rescue_audio_v1.cfg`, separate from campaign scores, and use a temporary file plus atomic rename. Invalid/missing preferences default to enabled. If a setting cannot be saved, it takes effect for the current session and a visible notice says it could not be saved.

`scripts/rescue_audio.gd` owns one looping music player and four reusable effect players. Scene actions call it only after the puzzle accepts a step or ability. Action differences choose fire, crate, gate, stun, civilian pickup or victory feedback; ordinary walking uses a quieter step. Rejected obstacle taps use a soft rate-limited warning; role selection, undo and restart have distinct cues. Random music/SFX choices never influence the deterministic rules, history or scores.

Application pause or focus loss suspends music and stops transient effects. Playback resumes only when both foreground and focus return, preserving the music position; effects are not replayed. Music mute stops its player, and sound mute stops all effect voices immediately. Music continues through scene navigation without stacked players.

## Verification

`tests/test_audio.gd` verifies imported stream data/duration, the complete loop range, bounded voices, independent mutes, settings reload/type fallback and lifecycle transitions. The production UI integration suite checks that real animated rescues emit all twelve semantic cues and that the menu controls work. These programmatic checks do not establish subjective sound quality or Android audio-focus behavior.

## Android listening scenario (pending)

1. Record device, OS, exact APK commit, speaker/headphone output and install/update result. Check Android media volume before starting.
2. Leave the menu open for at least 85 seconds: hear two complete loops without a loud click, accumulating layers or an unexpected silence. Enter and leave missions: the music should continue, without restarting or doubling.
3. Toggle music and sound independently, while the other is enabled; reopen the app offline and verify both saved states. Check that toggling sound off stops a playing victory cue immediately. Confirm the menu controls fit a small phone.
4. Play missions 04 and 11: hear selection, quiet steps, fire spray, crate movement, gate chime, ranger stun, civilian pickup and one victory cue. Undo, restart and tap blocked routes repeatedly; cues must be brief, understandable and comfortable relative to the music. No sound should imply an action succeeded when it was rejected.
5. During music and a movement/effect, press Home, lock/unlock, switch apps and return. There should be no background audio or replayed burst; enabled music should resume. Repeat with both settings muted. Exercise incoming-call/media-focus and headphone/Bluetooth changes separately: native interruption/routing behavior needs device evidence.
6. Complete/undo a rescue and reload progress to confirm audio preferences do not alter campaign scores or unlocks.

No Android device was connected during implementation. Native desktop rendering and source/CI playback checks remain distinct from these pending hardware tests.
