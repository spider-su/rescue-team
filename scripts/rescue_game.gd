extends Control
## Five-mission prototype: mission picker, automatic routing and local unlocks.
const RescueLevel = preload("res://scripts/rescue_level.gd")
const BoardView = preload("res://scripts/board_view.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")
const CampaignProgress = preload("res://scripts/campaign_progress.gd")

var catalog = LevelCatalog.new()
var progress = CampaignProgress.new()
var level = RescueLevel.new()
var current_index: int = 0
var moving: bool = false

var board
var title_label: Label
var subtitle_label: Label
var objective_label: Label
var status_label: Label
var hint_label: Label
var firefighter_button: Button
var engineer_button: Button
var undo_button: Button
var restart_button: Button
var next_button: Button
var menu_panel: VBoxContainer
var menu_scroll: ScrollContainer
var play_panel: VBoxContainer
var level_buttons: Array[Button] = []

func _ready() -> void:
	_build_ui()
	_show_menu()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#0e1727")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 22.0
	layout.offset_right = -22.0
	layout.offset_top = 46.0
	layout.offset_bottom = -64.0
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)

	title_label = Label.new()
	title_label.text = "RESCUE TEAM"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 37)
	layout.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 19)
	layout.add_child(subtitle_label)

	menu_scroll = ScrollContainer.new()
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(menu_scroll)
	menu_panel = VBoxContainer.new()
	menu_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_panel.add_theme_constant_override("separation", 14)
	menu_scroll.add_child(menu_panel)

	var instructions := Label.new()
	instructions.text = "Choose a mission. Complete one to unlock the next."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 23)
	instructions.custom_minimum_size.y = 92
	menu_panel.add_child(instructions)

	for index in range(catalog.count()):
		var button := Button.new()
		button.custom_minimum_size.y = 98
		button.add_theme_font_size_override("font_size", 23)
		button.pressed.connect(_start_level.bind(index))
		menu_panel.add_child(button)
		level_buttons.append(button)

	play_panel = VBoxContainer.new()
	play_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_panel.add_theme_constant_override("separation", 9)
	layout.add_child(play_panel)

	objective_label = Label.new()
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.y = 54
	objective_label.add_theme_font_size_override("font_size", 20)
	play_panel.add_child(objective_label)

	var roles := HBoxContainer.new()
	roles.add_theme_constant_override("separation", 10)
	play_panel.add_child(roles)
	firefighter_button = _button("FIREFIGHTER", roles)
	firefighter_button.pressed.connect(_on_role.bind(level.FIREFIGHTER))
	engineer_button = _button("ENGINEER", roles)
	engineer_button.pressed.connect(_on_role.bind(level.ENGINEER))

	board = BoardView.new()
	board.level = level
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(0, 355)
	board.cell_tapped.connect(_on_cell_tapped)
	play_panel.add_child(board)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 70
	status_label.add_theme_font_size_override("font_size", 20)
	play_panel.add_child(status_label)

	var commands := HBoxContainer.new()
	commands.add_theme_constant_override("separation", 8)
	play_panel.add_child(commands)
	undo_button = _button("UNDO", commands)
	undo_button.pressed.connect(_on_undo)
	restart_button = _button("RESTART", commands)
	restart_button.pressed.connect(_on_restart)
	var levels_button := _button("LEVELS", commands)
	levels_button.pressed.connect(_show_menu)

	next_button = Button.new()
	next_button.text = "NEXT MISSION"
	next_button.custom_minimum_size.y = 72
	next_button.add_theme_font_size_override("font_size", 21)
	next_button.pressed.connect(_next_level)
	play_panel.add_child(next_button)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size.y = 61
	hint_label.add_theme_font_size_override("font_size", 18)
	play_panel.add_child(hint_label)

func _button(label: String, container: HBoxContainer) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 76)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	container.add_child(button)
	return button

func _show_menu() -> void:
	if moving:
		return
	menu_scroll.visible = true
	play_panel.visible = false
	subtitle_label.text = "MISSIONS  /  FIELD OPERATIONS"
	for index in range(catalog.count()):
		var data: Dictionary = catalog.load_level(index)
		var button: Button = level_buttons[index]
		button.disabled = not progress.unlocked(index, catalog)
		var prefix := "✓" if progress.is_complete(data["id"]) else ("▶" if not button.disabled else "🔒")
		button.text = "%s  %s  —  %s" % [prefix, data["id"], data["title"]]

func _start_level(index: int) -> void:
	if moving or not progress.unlocked(index, catalog):
		return
	var data: Dictionary = catalog.load_level(index)
	if data.is_empty():
		return
	current_index = index
	level = RescueLevel.new(data)
	board.level = level
	board.route_preview.clear()
	board.clear_animation()
	menu_scroll.visible = false
	play_panel.visible = true
	subtitle_label.text = "MISSION %s  /  %s" % [level.level_id, level.title.to_upper()]
	hint_label.text = level.hint + "\nTap a distant tile to walk; select a rescuer to switch."
	_refresh()

func _on_role(role: String) -> void:
	if moving:
		return
	level.select_role(role)
	board.route_preview.clear()
	_refresh()

func _on_cell_tapped(cell: Vector2i) -> void:
	if moving or level.rescued:
		return
	for role in [level.FIREFIGHTER, level.ENGINEER]:
		if level.positions[role] == cell:
			level.select_role(role)
			board.route_preview.clear()
			_refresh()
			return
	var route: Array[Vector2i] = level.plan_route(cell)
	if route.is_empty():
		board.route_preview.clear()
		_refresh()
		return
	board.route_preview = route.duplicate()
	moving = true
	_refresh()
	_follow_route(route)

func _follow_route(route: Array[Vector2i]) -> void:
	var undo_from: int = level.history.size()
	for cell in route:
		var from: Vector2i = level.positions[level.selected]
		if not level.act(cell):
			break
		_refresh()
		if level.positions[level.selected] == from:
			await get_tree().create_timer(0.12).timeout
		else:
			await board.animate_step(level.selected, from, level.positions[level.selected])
		if not board.route_preview.is_empty():
			board.route_preview.pop_front()
	level.collapse_history(undo_from)
	board.route_preview.clear()
	moving = false
	if level.rescued:
		if not progress.record_victory(level.level_id, level.actions):
			level.message = "Rescue complete, but saving progress failed."
	_refresh()

func _on_undo() -> void:
	if moving:
		return
	level.undo()
	board.route_preview.clear()
	_refresh()

func _on_restart() -> void:
	if moving:
		return
	level.reset()
	board.route_preview.clear()
	_refresh()

func _next_level() -> void:
	if moving:
		return
	if current_index + 1 < catalog.count() and progress.unlocked(current_index + 1, catalog):
		_start_level(current_index + 1)
	else:
		_show_menu()

func _refresh() -> void:
	firefighter_button.text = ("● " if level.selected == level.FIREFIGHTER else "") + "FIREFIGHTER"
	engineer_button.text = ("● " if level.selected == level.ENGINEER else "") + "ENGINEER"
	firefighter_button.disabled = moving or level.rescued
	engineer_button.disabled = moving or level.rescued
	undo_button.disabled = moving or level.history.is_empty()
	restart_button.disabled = moving
	next_button.visible = level.rescued and not moving and current_index + 1 < catalog.count()
	var fire_status := "NONE" if not level.has_fire else ("OUT" if level.fire_cleared else "ACTIVE")
	var gate_status := "NONE" if not level.has_gate else ("OPEN" if level.gate_is_open() else "LOCKED")
	var person_status := "SAFE" if level.rescued else ("CARRIED" if not level.carrying_role.is_empty() else "WAITING")
	objective_label.text = "FIRE %s   |   GATE %s   |   CIVILIAN %s" % [fire_status, gate_status, person_status]
	status_label.text = "%s\nMoves: %d" % [level.message, level.actions]
	board.queue_redraw()
