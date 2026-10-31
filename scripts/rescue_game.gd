extends Control
## Coastal campaign presentation. All actions still use the deterministic puzzle model.
const RescueLevel = preload("res://scripts/rescue_level.gd")
const BoardView = preload("res://scripts/board_view.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")
const CampaignProgress = preload("res://scripts/campaign_progress.gd")
const UI = preload("res://scripts/coastal_style.gd")
const ICONS = {
	"back": preload("res://assets/ui/back.svg"), "undo": preload("res://assets/ui/undo.svg"),
	"restart": preload("res://assets/ui/restart.svg"), "levels": preload("res://assets/ui/levels.svg"),
	"play": preload("res://assets/ui/play.svg"), "check": preload("res://assets/ui/check.svg"),
	"lock": preload("res://assets/ui/lock.svg"),
}
var catalog = LevelCatalog.new()
var progress = CampaignProgress.new()
var level = RescueLevel.new()
var current_index: int = 0
var moving: bool = false
var screen: String = "menu"
var board
var title_label: Label
var objective_label: Label
var status_label: Label
var firefighter_button: Button
var engineer_button: Button
var undo_button: Button
var restart_button: Button
var levels_button: Button
var next_button: Button
var menu_panel: VBoxContainer
var menu_scroll: ScrollContainer
var play_panel: VBoxContainer
var victory_panel: VBoxContainer
var victory_scroll: ScrollContainer
var level_buttons: Array[Button] = []
var profile_rank: Label
var profile_xp: Label
var profile_bar: ProgressBar
var profile_badges: Label
var completion_label: Label
var moves_label: Label
var moves_card: PanelContainer
var back_button: Button
var victory_moves: Label
var victory_stars: Label
var victory_best: Label
var victory_next: Label
var victory_message: Label
var victory_undo: Button
var status_portrait: TextureRect
var _safe_margin: MarginContainer
var _hero: TextureRect
var _victory_saved: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_build_ui()
	resized.connect(_update_safe_area)
	_update_safe_area()
	_show_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if screen == "menu":
			get_tree().quit()
		else:
			_show_menu()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = UI.PAPER
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var ui_theme := Theme.new()
	ui_theme.default_font = UI.FONT
	ui_theme.default_font_size = 25
	theme = ui_theme
	_safe_margin = MarginContainer.new()
	_safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_safe_margin)
	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 0)
	_safe_margin.add_child(shell)
	_build_header(shell)
	_build_menu(shell)
	_build_play(shell)
	_build_victory(shell)

func _build_header(shell: VBoxContainer) -> void:
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", UI.box(UI.NAVY, UI.NAVY, 0, 14))
	shell.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	header.add_child(row)
	back_button = _button("", "back", UI.NAVY)
	back_button.custom_minimum_size = Vector2(96, 96)
	back_button.tooltip_text = "Back to missions"
	back_button.pressed.connect(_show_menu)
	row.add_child(back_button)
	title_label = UI.label("RESCUE TEAM", 37, true, Color.WHITE)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(title_label)
	moves_card = PanelContainer.new()
	moves_card.add_theme_stylebox_override("panel", UI.box(Color("#e6eff0"), UI.NAVY, 12, 7))
	row.add_child(moves_card)
	moves_label = UI.label("Moves\n00", 25, true)
	moves_label.custom_minimum_size.x = 74
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_card.add_child(moves_label)

func _build_menu(shell: VBoxContainer) -> void:
	menu_panel = VBoxContainer.new()
	menu_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_panel.add_theme_constant_override("separation", 10)
	shell.add_child(menu_panel)
	var district := UI.label("COASTAL DISTRICT", 32, true)
	district.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_panel.add_child(district)
	completion_label = UI.label("", 23)
	completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_panel.add_child(completion_label)
	_build_profile(menu_panel)
	_hero = UI.picture(UI.HARBOR, 290)
	menu_panel.add_child(_hero)
	menu_scroll = ScrollContainer.new()
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.follow_focus = true
	menu_scroll.scroll_deadzone = 12
	menu_panel.add_child(menu_scroll)
	var list_margin := MarginContainer.new()
	list_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge in ["left", "right"]:
		list_margin.add_theme_constant_override("margin_" + edge, 16)
	menu_scroll.add_child(list_margin)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	list_margin.add_child(list)
	for index in range(catalog.count()):
		var button := _mission_card(index)
		button.pressed.connect(_start_level.bind(index))
		list.add_child(button)
		level_buttons.append(button)
	var footer := UI.label("Choose your next rescue.  •  Scroll for all 10 missions", 22, false, UI.MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.custom_minimum_size.y = 44
	menu_panel.add_child(footer)

func _build_profile(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(Color("#e6eff0"), UI.LINE, 18, 12))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 12)
	content.add_child(identity)
	var portrait := UI.picture(UI.portrait("firefighter"))
	portrait.custom_minimum_size = Vector2(92, 92)
	identity.add_child(portrait)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(details)
	profile_rank = UI.label("RESCUE RECRUIT", 29, true)
	details.add_child(profile_rank)
	profile_xp = UI.label("Level 1 · 0 XP", 22)
	details.add_child(profile_xp)
	profile_bar = ProgressBar.new()
	profile_bar.custom_minimum_size.y = 14
	profile_bar.max_value = 100
	profile_bar.show_percentage = false
	content.add_child(profile_bar)
	profile_badges = UI.label("", 20, false, UI.MUTED)
	profile_badges.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(profile_badges)

func _mission_card(index: int) -> Button:
	var data: Dictionary = catalog.load_level(index)
	var button := _button("")
	button.custom_minimum_size.y = 104
	button.tooltip_text = "Mission %s: %s" % [data["id"], data["title"]]
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -14
	row.offset_top = 12
	row.offset_bottom = -12
	row.add_theme_constant_override("separation", 16)
	button.add_child(row)
	var thumb := UI.picture(_mission_thumbnail(index))
	thumb.custom_minimum_size = Vector2(96, 74)
	row.add_child(thumb)
	var name_label := UI.label("%s   %s" % [data["id"], String(data["title"]).to_upper()], 30, true)
	name_label.name = "MissionTitle"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_label)
	var state := UI.picture(ICONS["lock"])
	state.name = "MissionState"
	state.custom_minimum_size = Vector2(42, 42)
	state.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(state)
	_ignore_mouse(row)
	return button

func _mission_thumbnail(index: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = UI.HARBOR
	texture.region = Rect2(600 + (index % 3) * 240, 140 + (index % 2) * 160, 360, 280)
	return texture

func _build_play(shell: VBoxContainer) -> void:
	play_panel = VBoxContainer.new()
	play_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_panel.add_theme_constant_override("separation", 12)
	shell.add_child(play_panel)
	objective_label = UI.label("Bring the civilian to the exit", 26)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.y = 44
	play_panel.add_child(objective_label)
	var roles := HBoxContainer.new()
	roles.add_theme_constant_override("separation", 12)
	play_panel.add_child(roles)
	firefighter_button = _role_button(level.FIREFIGHTER, roles)
	engineer_button = _role_button(level.ENGINEER, roles)
	board = BoardView.new()
	board.level = level
	board.custom_minimum_size.y = 300
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.cell_tapped.connect(_on_cell_tapped)
	play_panel.add_child(board)
	var feedback := PanelContainer.new()
	feedback.add_theme_stylebox_override("panel", UI.box(Color("#e2edf0"), Color("#c9dce1"), 16, 12))
	play_panel.add_child(feedback)
	var feedback_row := HBoxContainer.new()
	feedback_row.add_theme_constant_override("separation", 12)
	feedback.add_child(feedback_row)
	status_portrait = UI.picture(UI.portrait(level.FIREFIGHTER))
	status_portrait.custom_minimum_size = Vector2(64, 64)
	status_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	feedback_row.add_child(status_portrait)
	status_label = UI.label("", 24)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_row.add_child(status_label)
	var commands := HBoxContainer.new()
	commands.add_theme_constant_override("separation", 12)
	play_panel.add_child(commands)
	undo_button = _button("UNDO", "undo", UI.BLUE)
	undo_button.pressed.connect(_on_undo)
	restart_button = _button("RESTART", "restart", Color("#e1eaf0"))
	restart_button.pressed.connect(_on_restart)
	levels_button = _button("LEVELS", "levels", Color("#e1eaf0"))
	levels_button.pressed.connect(_show_menu)
	for command in [undo_button, restart_button, levels_button]:
		command.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		commands.add_child(command)
	var hint := UI.label("Tap a destination to walk. Tap a rescuer to switch.", 21, false, UI.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	play_panel.add_child(hint)

func _role_button(role: String, row: HBoxContainer) -> Button:
	var button := _button("")
	button.custom_minimum_size.y = 108
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = "Select " + role
	button.pressed.connect(_on_role.bind(role))
	row.add_child(button)
	var content := HBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 8
	content.offset_right = -8
	button.add_child(content)
	var portrait := UI.picture(UI.portrait(role))
	portrait.custom_minimum_size = Vector2(100, 100)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(portrait)
	var text := UI.label(role.to_upper(), 27, true)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(text)
	_ignore_mouse(content)
	return button

func _build_victory(shell: VBoxContainer) -> void:
	victory_scroll = ScrollContainer.new()
	victory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	victory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	victory_scroll.follow_focus = true
	shell.add_child(victory_scroll)
	victory_panel = VBoxContainer.new()
	victory_panel.add_theme_constant_override("separation", 14)
	victory_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	victory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	victory_scroll.add_child(victory_panel)
	var illustration := UI.picture(UI.VICTORY, 280)
	illustration.size_flags_vertical = Control.SIZE_EXPAND_FILL
	victory_panel.add_child(illustration)
	victory_message = UI.label("Everyone is safe.", 43, true)
	victory_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	victory_panel.add_child(victory_message)
	var results := PanelContainer.new()
	results.add_theme_stylebox_override("panel", UI.box(UI.PAPER, UI.LINE, 16, 16))
	victory_panel.add_child(results)
	var scores := HBoxContainer.new()
	results.add_child(scores)
	victory_moves = _score_column("Moves", scores)
	victory_stars = _score_column("Stars", scores)
	victory_best = _score_column("Best", scores)
	var upcoming := PanelContainer.new()
	upcoming.add_theme_stylebox_override("panel", UI.box(Color("#e6efdf"), Color("#adc7a6"), 14, 16))
	victory_panel.add_child(upcoming)
	victory_next = UI.label("", 27, true)
	victory_next.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upcoming.add_child(victory_next)
	next_button = _button("NEXT MISSION", "play", UI.TEAL)
	next_button.pressed.connect(_next_level)
	victory_panel.add_child(next_button)
	var replay := _button("REPLAY", "restart")
	replay.pressed.connect(_on_restart)
	victory_panel.add_child(replay)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	victory_panel.add_child(bottom)
	victory_undo = _button("UNDO RESCUE", "undo")
	victory_undo.pressed.connect(_on_undo)
	victory_undo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(victory_undo)
	var levels := _button("LEVELS", "levels")
	levels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels.pressed.connect(_show_menu)
	bottom.add_child(levels)

func _score_column(caption: String, row: HBoxContainer) -> Label:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	var name_label := UI.label(caption, 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	var number := UI.label("—", 51, true)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(number)
	return number

func _button(text: String, icon: String = "", color: Color = UI.PAPER) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 96
	if not icon.is_empty():
		result.icon = ICONS[icon]
	UI.button(result, color)
	return result

func _ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control:
			_ignore_mouse(child)

func _update_safe_area() -> void:
	if not is_instance_valid(_safe_margin):
		return
	var insets := Vector4(12, 12, 12, 16)
	if OS.get_name() == "Android":
		var safe := DisplayServer.get_display_safe_area()
		var window := DisplayServer.window_get_size()
		if window.x > 0 and window.y > 0 and safe.has_area():
			var scale := size / Vector2(window)
			insets.x += maxf(0, safe.position.x) * scale.x
			insets.y += maxf(0, safe.position.y) * scale.y
			insets.z += maxf(0, window.x - safe.end.x) * scale.x
			insets.w += maxf(0, window.y - safe.end.y) * scale.y
	for i in range(4):
		_safe_margin.add_theme_constant_override("margin_" + ["left", "top", "right", "bottom"][i], int(insets[i]))
	if is_instance_valid(_hero):
		_hero.custom_minimum_size.y = clampf(size.y * 0.23, 200, 310)

func _show_screen(next_screen: String) -> void:
	screen = next_screen
	menu_panel.visible = screen == "menu"
	play_panel.visible = screen == "play"
	victory_panel.visible = screen == "victory"
	victory_scroll.visible = screen == "victory"
	if screen == "victory":
		victory_scroll.scroll_vertical = 0
	back_button.visible = screen != "menu"
	moves_card.visible = screen == "play"
	if screen == "menu":
		title_label.text = "RESCUE TEAM"
	elif screen == "victory":
		title_label.text = "MISSION COMPLETE"
	else:
		title_label.text = "%s  %s" % [level.level_id, level.title.to_upper()]

func _show_menu() -> void:
	if moving:
		return
	_show_screen("menu")
	var completed := 0
	var first_available := -1
	for index in range(catalog.count()):
		var data: Dictionary = catalog.load_level(index)
		var button := level_buttons[index]
		var complete: bool = progress.is_complete(data["id"])
		button.disabled = not progress.unlocked(index, catalog)
		if complete:
			completed += 1
		elif not button.disabled and first_available < 0:
			first_available = index
		UI.button(button, Color("#ffedc3") if index == first_available and not complete else UI.PAPER, index == first_available and not complete)
		var badge: TextureRect = button.find_child("MissionState", true, false)
		badge.texture = ICONS["check" if complete else ("lock" if button.disabled else "play")]
		button.tooltip_text = "Mission %s: %s  •  %d/3 stars" % [data["id"], data["title"], progress.earned_stars(data["id"])]
		badge.modulate = UI.GREEN if complete else (UI.MUTED if button.disabled else UI.ORANGE)
		var name_label: Label = button.find_child("MissionTitle", true, false)
		name_label.modulate = Color("#7d8888") if button.disabled else Color.WHITE
	completion_label.text = "%d / %d rescued  •  ★ %d / %d" % [completed, catalog.count(), progress.total_stars(), catalog.count() * 3]
	var xp: int = progress.total_xp()
	profile_rank.text = progress.rescuer_rank().to_upper()
	profile_xp.text = "Level %d  ·  %d XP  ·  %d to next" % [progress.rescuer_level(), xp, 100 - xp % 100]
	profile_bar.value = xp % 100
	var badges := progress.earned_badges()
	profile_badges.text = "Badges: " + (", ".join(badges) if not badges.is_empty() else "Complete a rescue to earn your first badge")

func _start_level(index: int) -> void:
	if moving or not progress.unlocked(index, catalog):
		return
	var data: Dictionary = catalog.load_level(index)
	if data.is_empty():
		return
	current_index = index
	_victory_saved = false
	level = RescueLevel.new(data)
	board.level = level
	board.route_preview.clear()
	board.clear_animation()
	_show_screen("play")
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
			_on_role(role)
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
		_victory_saved = progress.record_victory(level.level_id, level.actions)
		if not _victory_saved:
			level.message = "Rescue complete, but saving progress failed. Replay to try again."
		_show_screen("victory")
	_refresh()

func _on_undo() -> void:
	if moving:
		return
	level.undo()
	board.route_preview.clear()
	_show_screen("play")
	_refresh()

func _on_restart() -> void:
	if moving:
		return
	level.reset()
	board.route_preview.clear()
	_show_screen("play")
	_refresh()

func _next_level() -> void:
	if moving:
		return
	if current_index + 1 < catalog.count() and progress.unlocked(current_index + 1, catalog):
		_start_level(current_index + 1)
	else:
		_show_menu()

func _refresh() -> void:
	for role_button in [firefighter_button, engineer_button]:
		var role: String = level.FIREFIGHTER if role_button == firefighter_button else level.ENGINEER
		var selected: bool = level.selected == role
		var color: Color = (UI.ORANGE if role == level.FIREFIGHTER else UI.BLUE) if selected else Color("#e0e8e7")
		UI.button(role_button, color, selected)
		# Disable repeated taps during motion without hiding the active specialist.
		role_button.add_theme_stylebox_override("disabled", UI.box(color, UI.ORANGE if selected else UI.LINE, 15, 12))
		var caption: Label = role_button.get_child(0).get_child(1)
		caption.add_theme_color_override("font_color", Color.WHITE if selected and role == level.ENGINEER else UI.INK)
		role_button.disabled = moving or level.rescued
	undo_button.disabled = moving or level.history.is_empty()
	restart_button.disabled = moving
	levels_button.disabled = moving
	back_button.disabled = moving
	moves_label.text = "Moves\n%02d" % level.actions
	objective_label.text = "Bring the civilian to the exit" if level.carrying_role.is_empty() else "Civilian on board. Reach the green exit."
	status_label.text = level.message
	status_portrait.texture = UI.portrait(level.selected)
	if screen == "victory":
		victory_moves.text = str(level.actions)
		victory_best.text = str(progress.best.get(level.level_id, "—"))
		victory_stars.text = ("★".repeat(progress.earned_stars(level.level_id)) + "☆".repeat(3 - progress.earned_stars(level.level_id))) if _victory_saved else "—"
		var saved: bool = _victory_saved
		victory_message.text = ("Perfect Rescue!" if progress.earned_stars(level.level_id) == 3 else "Everyone is safe.") if saved else level.message
		var has_next: bool = current_index + 1 < catalog.count()
		if saved and has_next:
			var next: Dictionary = catalog.load_level(current_index + 1)
			victory_next.text = "%s  %s\nNext mission available" % [next["id"], next["title"].to_upper()]
		elif saved:
			victory_next.text = "COASTAL DISTRICT COMPLETE\nAll 10 missions rescued. Well done!"
		else:
			victory_next.text = "Progress could not be saved. Please replay to try again."
		next_button.text = "NEXT MISSION" if has_next else "ALL MISSIONS"
		next_button.disabled = not saved
		victory_undo.disabled = level.history.is_empty()
	board.queue_redraw()
