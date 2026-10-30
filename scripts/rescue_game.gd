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

func _ready() -> void:
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

	var subtitle := Label.new()
	subtitle.text = "MISSION 01  /  THE LOCKED CORRIDOR"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 19)
	layout.add_child(subtitle)

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
	var undo_button := _create_button("UNDO", commands)
	undo_button.pressed.connect(_on_undo)
	var restart_button := _create_button("RESTART", commands)
	restart_button.pressed.connect(_on_restart)

	var hint := Label.new()
	hint.text = "Tap a specialist, then an adjacent square. F clears fire; E pushes BOX to the blue switch."
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
	level.select_role(role)
	_refresh()

func _on_cell_tapped(cell: Vector2i) -> void:
	for role in [level.FIREFIGHTER, level.ENGINEER]:
		if level.positions[role] == cell:
			level.select_role(role)
			_refresh()
			return
	level.act(cell)
	_refresh()

func _on_undo() -> void:
	level.undo()
	_refresh()

func _on_restart() -> void:
	level.reset()
	_refresh()

func _refresh() -> void:
	firefighter_button.text = ("● " if level.selected == level.FIREFIGHTER else "  ") + "FIREFIGHTER"
	engineer_button.text = ("● " if level.selected == level.ENGINEER else "  ") + "ENGINEER"
	firefighter_button.disabled = level.rescued
	engineer_button.disabled = level.rescued
	objective_label.text = "FIRE %s    |    GATE %s    |    CIVILIAN %s" % [
		"OUT" if level.fire_cleared else "ACTIVE",
		"OPEN" if level.gate_is_open() else "LOCKED",
		"SAFE" if level.rescued else ("CARRIED" if not level.carrying_role.is_empty() else "WAITING"),
	]
	status_label.text = level.message + "\nMoves: %d" % level.actions
	board.queue_redraw()
