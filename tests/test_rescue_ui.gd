extends SceneTree
## Exercise the actual scene: navigation, animated actions, victory, undo and saves.
## Add -- --capture-dir=/absolute/path with a graphical renderer for real UI PNGs.
const MainScene = preload("res://scenes/main.tscn")
const Progress = preload("res://scripts/campaign_progress.gd")
const BoardView = preload("res://scripts/board_view.gd")
const Level = preload("res://scripts/rescue_level.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
var game
var viewport: SubViewport
var capture_dir := ""
var failed := false
const TEST_SAVE = "user://rescue_ui_test.json"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	_run.call_deferred()

func _run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	viewport = SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	game = MainScene.instantiate()
	game.progress = Progress.new(TEST_SAVE)
	viewport.add_child(game)
	await _settle()
	_check(game.screen == "menu" and game.level_buttons.size() == 10, "Mission picker starts with all ten cards")
	_check(game.level_buttons[1].disabled, "Uncompleted next mission is visibly locked")
	game._start_level(1)
	_check(game.screen == "menu", "Locked mission cannot be opened")
	game.level_buttons[0].pressed.emit()
	await _settle()
	_check(game.screen == "play", "Mission card starts the actual play scene")
	_check_controls_fit()
	await _tap(Vector2i(3, 1))
	_check(game.level.carrying_role == game.level.FIREFIGHTER, "Board tap walks and collects civilian")
	game.undo_button.pressed.emit()
	_check(game.level.carrying_role.is_empty() and game.level.actions == 0, "Undo button restores whole tap route")
	await _tap(Vector2i(3, 1))
	await _tap(Vector2i(5, 1))
	_check(game.screen == "victory" and game.victory_panel.is_visible_in_tree(), "Winning route opens completion screen")
	_check(not game.next_button.disabled and game.progress.unlocked(1, game.catalog), "Victory persists progress and enables next mission")
	_check(game.victory_best.text == str(game.level.actions), "Results show the actual saved best")
	game.victory_undo.pressed.emit()
	_check(game.screen == "play" and not game.level.rescued and game.progress.is_complete("01"), "Undo victory returns to play without revoking saved completion")
	game._on_restart()
	_check(game.level.actions == 0 and game.level.history.is_empty(), "Replay resets mission")
	_test_board_projection()
	# Seed prior completions only in this isolated test save for the showcase.
	for id in ["01", "02", "03"]:
		game.progress.record_victory(id, 12)
	game._show_menu()
	await _settle()
	await _capture("missions")
	game.level_buttons[3].pressed.emit()
	await _settle()
	await _capture("gameplay")
	game.engineer_button.pressed.emit()
	await _tap(Vector2i(3, 3), "gameplay-route")
	game.firefighter_button.pressed.emit()
	await _tap(Vector2i(3, 1))
	await _tap(Vector2i(5, 1))
	await _tap(Vector2i(8, 1))
	_check(game.screen == "victory" and game.progress.is_complete("04"), "Cooperative mission completes through animated UI")
	await _capture("complete")
	viewport.size = Vector2i(540, 960)
	await _settle()
	game.victory_scroll.scroll_vertical = 100000
	await _settle()
	_check(game.victory_scroll.get_global_rect().intersects(game.victory_undo.get_global_rect()), "Completion controls remain reachable on smaller screens")
	await _capture("complete-540x960-scrolled")
	viewport.size = Vector2i(720, 1280)
	game.next_button.pressed.emit()
	_check(game.current_index == 4 and game.screen == "play", "Next mission opens newly unlocked level")
	for dimensions in [Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(540, 960)]:
		viewport.size = dimensions
		await _settle()
		_check_controls_fit()
		await _capture("gameplay-%dx%d" % [dimensions.x, dimensions.y])
	game.levels_button.pressed.emit()
	await _settle()
	game.menu_scroll.scroll_vertical = 100000
	await _settle()
	var scroll_rect: Rect2 = game.menu_scroll.get_global_rect()
	_check(scroll_rect.intersects(game.level_buttons[9].get_global_rect()), "Last mission is reachable by scrolling")
	# The last level leads back to the campaign instead of a nonexistent mission.
	for id in ["05", "06", "07", "08", "09"]:
		game.progress.record_victory(id, 20)
	game._start_level(9)
	game.engineer_button.pressed.emit()
	for x in range(2, 6):
		await _tap(Vector2i(x, 3))
	game.firefighter_button.pressed.emit()
	for x in [5, 7, 10]:
		await _tap(Vector2i(x, 1))
	_check(game.screen == "victory" and game.next_button.text == "ALL MISSIONS", "Final rescue shows completed campaign action")
	game.next_button.pressed.emit()
	_check(game.screen == "menu" and game.completion_label.text == "10 / 10 complete", "Final completion returns to all ten completed missions")
	# A failed save must not be presented as a successful unlock, even on replay.
	viewport.size = Vector2i(720, 1280)
	game._start_level(0)
	var blocked_path := TEST_SAVE + ".blocked"
	var temporary_directory := ProjectSettings.globalize_path(blocked_path + ".tmp")
	DirAccess.make_dir_absolute(temporary_directory)
	game.progress.path = blocked_path
	await _tap(Vector2i(3, 1))
	await _tap(Vector2i(5, 1))
	_check(game.screen == "victory" and game.next_button.disabled and game.victory_message.text.contains("saving progress failed"), "Failed save is visible and cannot masquerade as a new unlock")
	DirAccess.remove_absolute(temporary_directory)
	game.queue_free()
	await process_frame
	viewport.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	if not failed:
		print("PASS: coastal UI, animated rescue, victory/undo/replay, unlocks, adaptive grid input and portrait layouts")
	quit(1 if failed else 0)

func _tap(cell: Vector2i, capture_name: String = "") -> void:
	await _settle()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.board.cell_center(Vector2(cell))
	game.board._gui_input(event)
	if not capture_name.is_empty():
		await _capture(capture_name)
	var deadline := Time.get_ticks_msec() + 5000
	while game.moving and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	_check(not game.moving, "Animated route completes within five seconds")
	await _settle()

func _test_board_projection() -> void:
	var probe := BoardView.new()
	viewport.add_child(probe)
	var catalog = Catalog.new()
	for index in range(catalog.count()):
		probe.level = Level.new(catalog.load_level(index))
		for dimensions in [Vector2(640, 760), Vector2(640, 300)]:
			probe.size = dimensions
			for y in range(probe.level.height):
				for x in range(probe.level.width):
					var cell := Vector2i(x, y)
					_check(probe.cell_at_position(probe.cell_center(Vector2(cell))) == cell, "Rendered tile center maps to original mission cell")
			_check(probe.cell_at_position(Vector2(-1, -1)) == Vector2i(-1, -1), "Water outside grid is not a puzzle target")
	probe.queue_free()

func _check_controls_fit() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(viewport.size))
	for control in [game.firefighter_button, game.engineer_button, game.undo_button, game.restart_button, game.levels_button]:
		var rect: Rect2 = control.get_global_rect()
		_check(bounds.encloses(rect) and rect.size.y >= 96, "Touch controls fit portrait viewport with large targets")
	_check(game.board.size.y >= 300, "Board retains a usable display area")

func _settle() -> void:
	for i in range(5):
		await process_frame

func _capture(name: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().save_png(capture_dir.path_join(name + ".png"))
	_check(result == OK, "Rendered screenshot saved")

func _check(condition: bool, description: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: " + description)
