extends Node
## Presentation-only audio. Separate local preferences never touch campaign saves.
signal cue_played(cue: String)
const THEME = preload("res://assets/audio/harbor_theme.wav")
const EFFECTS = {
	"ui": preload("res://assets/audio/ui.wav"),
	"select": preload("res://assets/audio/select.wav"),
	"step": preload("res://assets/audio/step.wav"),
	"fire": preload("res://assets/audio/fire.wav"),
	"crate": preload("res://assets/audio/crate.wav"),
	"gate": preload("res://assets/audio/gate.wav"),
	"stun": preload("res://assets/audio/stun.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"victory": preload("res://assets/audio/victory.wav"),
	"blocked": preload("res://assets/audio/blocked.wav"),
	"undo": preload("res://assets/audio/undo.wav"),
	"restart": preload("res://assets/audio/restart.wav"),
}
var settings_path := "user://rescue_audio_v1.cfg"
var music_enabled := true
var effects_enabled := true
var settings_saved := true
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var _voice := 0
var _app_paused := false
var _focused := true
var _last_blocked := -1000

func _ready() -> void:
	_load_settings()
	music = AudioStreamPlayer.new()
	var loop: AudioStreamWAV = THEME.duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
	music.stream = loop
	music.volume_db = -17
	add_child(music)
	for i in range(4):
		var player := AudioStreamPlayer.new()
		player.volume_db = -7
		add_child(player)
		voices.append(player)
	_update_playback()

func _exit_tree() -> void:
	music.stop()
	for player in voices:
		player.stop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_app_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_app_paused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
	else:
		return
	if is_instance_valid(music):
		_update_playback()

func _update_playback() -> void:
	var suspended := _app_paused or not _focused
	if not music_enabled:
		music.stop()
	elif not music.playing and not suspended:
		music.play()
	music.stream_paused = suspended
	if suspended or not effects_enabled:
		for player in voices:
			player.stop()

func play_cue(cue: String) -> void:
	if not effects_enabled or _app_paused or not _focused or not EFFECTS.has(cue):
		return
	# Repeated blocked taps should not become a loud buzz.
	if cue == "blocked":
		var now := Time.get_ticks_msec()
		if now - _last_blocked < 180:
			return
		_last_blocked = now
	var player := voices[_voice]
	_voice = (_voice + 1) % voices.size()
	player.stream = EFFECTS[cue]
	player.play()
	cue_played.emit(cue)

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_update_playback()
	_save_settings()

func set_effects_enabled(enabled: bool) -> void:
	effects_enabled = enabled
	_update_playback()
	_save_settings()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var saved_music: Variant = config.get_value("audio", "music", true)
	var saved_effects: Variant = config.get_value("audio", "effects", true)
	music_enabled = saved_music if saved_music is bool else true
	effects_enabled = saved_effects if saved_effects is bool else true

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_enabled)
	config.set_value("audio", "effects", effects_enabled)
	var temporary := settings_path + ".tmp"
	settings_saved = config.save(temporary) == OK
	if settings_saved:
		settings_saved = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(settings_path)) == OK
	if not settings_saved:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))

static func snapshot(level: RefCounted) -> Dictionary:
	return {"position": level.positions[level.selected], "fire": level.fire_cleared,
		"crate": level.crate_pos, "gate": level.gate_is_open(), "infected": level.infected.size(),
		"drained": level.water_drained, "bridge": level.bridge_built, "carrying": level.carrying_role, "rescued": level.rescued}

func play_action(before: Dictionary, level: RefCounted) -> void:
	if not before["rescued"] and level.rescued:
		play_cue("victory")
	elif before["carrying"].is_empty() and not level.carrying_role.is_empty():
		play_cue("pickup")
	elif not before["gate"] and level.gate_is_open():
		play_cue("gate")
	elif not before["drained"] and level.water_drained:
		play_cue("gate")
	elif not before["bridge"] and level.bridge_built:
		play_cue("crate")
	elif before["crate"] != level.crate_pos:
		play_cue("crate")
	elif not before["fire"] and level.fire_cleared:
		play_cue("fire")
	elif before["infected"] > level.infected.size():
		play_cue("stun")
	elif before["position"] != level.positions[level.selected]:
		play_cue("step")
