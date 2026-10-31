# Original Rescue Team audio

All audio in this directory was composed and synthesized for Rescue Team on 2026-10-31 using the repository's `tools/generate_audio.py`. No third-party recordings, sample packs, existing songs, AI music service, or legacy game audio were used. These original assets are included under the repository's MIT license.

Run `python3 tools/generate_audio.py` to reproduce the mono 22,050 Hz / 16-bit PCM WAV source files using only Python's standard library. Godot imports/compresses the WAVs for playback. The runtime duplicates the theme stream and loops its complete 40-second sample range; it does not synthesize audio on the phone.

- **Harbor theme:** original 16-bar melody, 96 BPM, C major; soft flute-like lead, plucked arpeggios and warm bass, with a small circular room echo. One shared, quiet loop accompanies the menu and both locations without restarting on navigation.
- **UI/select:** short plucked notes for mission entry, settings and role selection.
- **Step:** quiet, short tap for each completed walking step.
- **Fire/crate/stun:** synthesized spray, wooden thud and electronic shield pulse.
- **Gate/pickup/victory:** ascending chimes for opening a gate, collecting a civilian and completing a rescue. Gate and victory cues take priority over the ordinary movement/crate cue on that action.
- **Blocked/undo/restart:** soft descending warning, rewind-like notes and a reset cue. Rejected taps are rate-limited to one cue per 180 ms.

The full theme peaks below 0.22 of full scale; all effect sources peak below 0.36. Runtime music is further attenuated by 17 dB and effects by 7 dB. Four effect voices bound overlap. This is a first synthesized audio pass; subjective mix, looping and Android interruption behavior need listening tests on hardware.
