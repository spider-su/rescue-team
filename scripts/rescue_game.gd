extends Control
## Phase 1: one playable touch-first rescue puzzle; no network, plugins or ads.
const RescueLevel = preload("res://scripts/rescue_level.gd")
const BoardView = preload("res://scripts/board_view.gd")

var level = RescueLevel.new()
var board: Control
var firefighter_button: Button
var engineer_button: Button
var status_label: Label
var objective_label: Label
var undo_button: Button
var restart_button: Button
var previous_button: Button
var next_button: Button
var mission_label: Label
var moving: bool = false
var max_unlocked: int = 0
const PROGRESS_PATH = "user://rescue_progress.json"

func _ready() -> void:
	_load_progress()
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#0e1727")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 24.0
	layout.offset_right = -24.0
	layout.offset_top = 54.0
	layout.offset_bottom = -64.0
	layout.add_theme_constant_override("separation", 17)
	add_child(layout)

	var title := Label.new()
	title.text = "RESCUE TEAM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	layout.add_child(title)

	mission_label = Label.new()
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.add_theme_font_size_override("font_size", 19)
	layout.add_child(mission_label)

	var mission_navigation := HBoxContainer.new()
	layout.add_child(mission_navigation)
	previous_button = _create_button("PREVIOUS", mission_navigation)
	previous_button.pressed.connect(_change_mission.bind(-1))
	next_button = _create_button("NEXT", mission_navigation)
	next_button.pressed.connect(_change_mission.bind(1))

	objective_label = Label.new()
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.y = 75
	objective_label.add_theme_font_size_override("font_size", 22)
	layout.add_child(objective_label)

	var roles := HBoxContainer.new()
	roles.add_theme_constant_override("separation", 12)
	layout.add_child(roles)
	firefighter_button = _create_button("F  FIREFIGHTER", roles)
	firefighter_button.pressed.connect(_on_role.bind(level.FIREFIGHTER))
	engineer_button = _create_button("E  ENGINEER", roles)
	engineer_button.pressed.connect(_on_role.bind(level.ENGINEER))

	board = BoardView.new()
	board.level = level
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(0, 370)
	board.cell_tapped.connect(_on_cell_tapped)
	layout.add_child(board)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 76
	status_label.add_theme_font_size_override("font_size", 20)
	layout.add_child(status_label)

	var commands := HBoxContainer.new()
	commands.add_theme_constant_override("separation", 12)
	layout.add_child(commands)
	undo_button = _create_button("UNDO", commands)
	undo_button.pressed.connect(_on_undo)
	restart_button = _create_button("RESTART", commands)
	restart_button.pressed.connect(_on_restart)

	var hint := Label.new()
	hint.text = "Select a specialist and tap a destination to walk there. Tap FIRE or BOX to interact."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 17)
	layout.add_child(hint)

func _create_button(label: String, container: HBoxContainer) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 76)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 20)
	container.add_child(button)
	return button

func _on_role(role: String) -> void:
	if moving:
		return
	level.select_role(role)
	_refresh()

func _on_cell_tapped(cell: Vector2i) -> void:
	if moving:
		return
	for role in [level.FIREFIGHTER, level.ENGINEER]:
		if level.positions[role] == cell:
			level.select_role(role)
			_refresh()
			return
	var route: Array[Vector2i] = level.plan_route(cell)
	if route.is_empty():
		_refresh()
		return
	moving = true
	_refresh()
	_follow_route(route)

func _follow_route(route: Array[Vector2i]) -> void:
	var undo_from: int = level.history.size()
	for cell in route:
		if not level.act(cell):
			break
		_refresh()
		await get_tree().create_timer(0.13).timeout
	level.collapse_history(undo_from)
	if level.rescued and max_unlocked < level.MISSIONS.size() - 1:
		max_unlocked = maxi(max_unlocked, level.mission_index + 1)
		_save_progress()
	moving = false
	_refresh()

func _load_progress() -> void:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROGRESS_PATH))
	if parsed is Dictionary:
		var unlocked: Variant = parsed.get("max_unlocked")
		if unlocked is float or unlocked is int:
			max_unlocked = clampi(int(unlocked), 0, level.MISSIONS.size() - 1)

func _save_progress() -> void:
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"max_unlocked": max_unlocked}))

func _change_mission(delta: int) -> void:
	if moving:
		return
	var target: int = level.mission_index + delta
	if target >= 0 and target <= max_unlocked and level.load_mission(target):
		_refresh()

func _on_undo() -> void:
	if moving:
		return
	level.undo()
	_refresh()

func _on_restart() -> void:
	if moving:
		return
	level.reset()
	_refresh()

func _refresh() -> void:
	mission_label.text = "MISSION %02d  /  %s" % [level.mission_index + 1, level.MISSIONS[level.mission_index]["title"]]
	previous_button.disabled = moving or level.mission_index == 0
	next_button.disabled = moving or level.mission_index >= max_unlocked
	firefighter_button.text = ("● " if level.selected == level.FIREFIGHTER else "  ") + "FIREFIGHTER"
	engineer_button.text = ("● " if level.selected == level.ENGINEER else "  ") + "ENGINEER"
	firefighter_button.disabled = level.rescued or moving
	engineer_button.disabled = level.rescued or moving
	objective_label.text = "FIRE %s    |    GATE %s    |    CIVILIAN %s" % [
		"OUT" if level.fire_cleared else "ACTIVE",
		"OPEN" if level.gate_is_open() else "LOCKED",
		"SAFE" if level.rescued else ("CARRIED" if not level.carrying_role.is_empty() else "WAITING"),
	]
	undo_button.disabled = moving
	restart_button.disabled = moving
	status_label.text = level.message + "\nMoves: %d" % level.actions
	board.queue_redraw()
