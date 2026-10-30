extends Control
## Disposable tap-game example. No external artwork or backend.

const GameSession = preload("res://scripts/game_session.gd")
const SAVE_PATH = "user://rescue_team_template_demo.json"
var session = GameSession.new()
var score_label: Label
var state_label: Label
var target_button: Button
var pause_button: Button

func _ready() -> void:
	session.load_best(SAVE_PATH)
	_create_ui()
	_refresh()

func _create_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#101728")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 40.0
	content.offset_right = -40.0
	content.offset_top = 90.0
	content.offset_bottom = -90.0
	content.add_theme_constant_override("separation", 26)
	add_child(content)

	var title := Label.new()
	title.text = "RESCUE TEAM — SETUP DEMO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	content.add_child(title)

	var description := Label.new()
	description.text = "Technical demo only. Rescue puzzles are planned next."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 22)
	content.add_child(description)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 42)
	content.add_child(score_label)

	target_button = Button.new()
	target_button.text = "TAP TO SCORE"
	target_button.custom_minimum_size = Vector2(0, 330)
	target_button.add_theme_font_size_override("font_size", 36)
	target_button.pressed.connect(_on_target_pressed)
	content.add_child(target_button)

	state_label = Label.new()
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 24)
	content.add_child(state_label)

	pause_button = Button.new()
	pause_button.text = "PAUSE"
	pause_button.custom_minimum_size = Vector2(0, 86)
	pause_button.pressed.connect(_on_pause_pressed)
	content.add_child(pause_button)

	var restart_button := Button.new()
	restart_button.text = "RESTART ROUND"
	restart_button.custom_minimum_size = Vector2(0, 86)
	restart_button.pressed.connect(_on_restart_pressed)
	content.add_child(restart_button)

func _on_target_pressed() -> void:
	if session.tap():
		session.save_best(SAVE_PATH)
	_refresh()

func _on_pause_pressed() -> void:
	session.toggle_pause()
	_refresh()

func _on_restart_pressed() -> void:
	session.restart()
	_refresh()

func _refresh() -> void:
	score_label.text = "Score: %d   Best: %d" % [session.score, session.best]
	state_label.text = "PAUSED" if session.paused else "READY"
	target_button.disabled = session.paused
	pause_button.text = "RESUME" if session.paused else "PAUSE"
