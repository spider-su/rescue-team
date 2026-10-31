extends SceneTree
const Audio = preload("res://scripts/rescue_audio.gd")
const SETTINGS = "user://audio_regression_test.cfg"
var failed := false
var heard: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	var audio = Audio.new()
	audio.settings_path = SETTINGS
	root.add_child(audio)
	audio.cue_played.connect(func(cue: String): heard.append(cue))
	_check(audio.music_enabled and audio.effects_enabled and audio.music.playing, "First launch starts music and enables effects")
	var stream: AudioStreamWAV = audio.music.stream
	_check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_begin == 0 and stream.loop_end == stream.get_length() * stream.mix_rate, "Theme loops through complete imported PCM data")
	_check(is_equal_approx(stream.get_length(), 40.0), "Theme is a complete 16-bar 40-second phrase")
	for cue in audio.EFFECTS:
		var effect: AudioStreamWAV = audio.EFFECTS[cue]
		_check(effect.get_length() > .05 and effect.get_length() < 2 and not effect.data.is_empty(), "Effect loads as nonempty bounded audio: " + cue)
		audio.play_cue(cue)
	_check(heard.size() == 12 and audio.voices.size() == 4, "Every effect has playback and polyphony is bounded")
	audio.set_effects_enabled(false)
	for player in audio.voices:
		_check(not player.playing, "Muting effects stops active voices")
	var count := heard.size()
	audio.play_cue("victory")
	_check(heard.size() == count and audio.music.playing, "Effect mute suppresses cues without muting music")
	audio.set_music_enabled(false)
	_check(not audio.music.playing and audio.settings_saved, "Music toggle stops playback and persists")
	audio.queue_free()
	await create_timer(0.1).timeout
	var restored = Audio.new()
	restored.settings_path = SETTINGS
	root.add_child(restored)
	_check(not restored.music_enabled and not restored.effects_enabled and not restored.music.playing, "Both independent mutes survive scene recreation")
	restored.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	restored.set_music_enabled(true)
	restored.set_effects_enabled(true)
	_check(not restored.music.playing, "Changing settings while backgrounded cannot start audio")
	restored.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(restored.music.playing and not restored.music.stream_paused, "Resume restores enabled theme")
	restored.play_cue("victory")
	restored.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(restored.music.stream_paused, "Focus loss suspends theme")
	for player in restored.voices:
		_check(not player.playing, "Focus loss stops effects rather than replaying on resume")
	restored.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	restored.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_check(restored.music.stream_paused, "Focus return cannot override an application pause")
	restored.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(not restored.music.stream_paused, "Only a complete foreground return resumes music")
	restored.queue_free()
	await create_timer(0.1).timeout
	var invalid := ConfigFile.new()
	invalid.set_value("audio", "music", "false")
	invalid.set_value("audio", "effects", 42)
	invalid.save(SETTINGS)
	var fallback = Audio.new()
	fallback.settings_path = SETTINGS
	root.add_child(fallback)
	_check(fallback.music_enabled and fallback.effects_enabled, "Invalid stored preference types use safe defaults")
	fallback.settings_path = "user://missing_audio_test_directory/settings.cfg"
	fallback.set_music_enabled(false)
	_check(not fallback.settings_saved and not fallback.music_enabled and not fallback.music.playing, "Write failure keeps session mute and exposes unsaved status")
	fallback.queue_free()
	await create_timer(0.1).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	if not failed:
		print("PASS: audio resources, loop, bounded voices, independent persistent mutes and lifecycle suspension")
	quit(1 if failed else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: " + description)
