extends SceneTree
## Godot built-in headless test runner; no external GUT dependency.
const GameSession = preload("res://scripts/game_session.gd")

func _initialize() -> void:
	var session = GameSession.new()
	if not session.tap() or session.score != 1 or session.best != 1:
		_fail("First tap must increment score and best.")
		return
	session.toggle_pause()
	if session.tap() or session.score != 1:
		_fail("Paused tap must not score.")
		return
	session.toggle_pause()
	session.tap()
	session.restart()
	if session.score != 0 or session.best != 2 or session.paused:
		_fail("Restart must preserve the best score.")
		return

	var save_path := "user://game_session_test.json"
	if not session.save_best(save_path):
		_fail("Could not write temporary test save.")
		return
	var loaded = GameSession.new()
	loaded.load_best(save_path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	if loaded.best != 2:
		_fail("Best score must survive save/load.")
		return
	print("PASS: GameSession score, pause, restart and persistence")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
