extends SceneTree
const Catalog = preload("res://scripts/level_catalog.gd")
const Level = preload("res://scripts/rescue_level.gd")
const Progress = preload("res://scripts/campaign_progress.gd")
const Session = preload("res://scripts/mission_session.gd")
const Guidance = preload("res://scripts/mission_guidance.gd")
const PATH = "user://polish_session_test.json"
var failed := false

func _initialize() -> void:
	var catalog = Catalog.new()
	var progress = Progress.new("user://polish_progress_test.json")
	var fixtures: Dictionary = {}
	for chapter in ["coastal", "old_town", "floodworks"]:
		fixtures.merge(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/%s_solutions.json" % chapter)))
	for i in range(catalog.count()):
		var data: Dictionary = catalog.load_level(i)
		var level = Level.new(data)
		var commands: Array = []
		for step in fixtures[level.level_id]:
			_check(_tap(level, step, commands), "Verified winning path " + level.level_id)
		_check(level.rescued and progress.stars_for(level.level_id, level.actions) == 3, "Actual step score earns three stars on reference solution " + level.level_id)
		_check(progress.stars_for(level.level_id, data["three_star_moves"] + 1) == 2 and progress.stars_for(level.level_id, data["two_star_moves"] + 1) == 1, "Authored star tier boundaries " + level.level_id)
		if i >= 20:
			_check(level.water_drained, "Floodworks opens a water route")
			while not level.history.is_empty(): level.undo()
			_check(not level.water_drained and not level.bridge_built and level.actions == 0, "Whole trial undo restores flooded topology")
			level.reset()
			_check(not level.water_drained, "Trial restart floods route again")
	_test_flood_rules(catalog)
	_test_resume(catalog)
	progress.best = {"01": 4, "11": 42, "20": 106}
	_check(progress.earned_stars("01") == 3 and progress.earned_stars("11") == 3 and progress.earned_stars("20") == 3, "Existing step-unit saves derive corrected rewards without conversion")
	_check(not progress.unlocked(20, catalog), "Optional trials require coastal 05")
	progress.best["05"] = 13
	_check(progress.unlocked(20, catalog) and not progress.unlocked(21, catalog), "Optional chapter unlock does not depend on Old Town completion")
	progress.best = {}
	for i in range(1, 21):
		if i != 15: progress.best["%02d" % i] = 4
	progress.best["21"] = 8
	_check(not "Old Town Protector" in progress.earned_badges(), "Trial completions cannot stand in for missing Old Town missions")
	var broken := catalog.load_level(0)
	broken["two_star_moves"] = broken["three_star_moves"] - 1
	_check(not catalog.validate(broken).is_empty(), "Reject inverted authored reward targets")
	if not failed: print("PASS: 23 reference scores, layered goals, water/bridge cooperation and validated resumable undo journals")
	quit(1 if failed else 0)

func _test_flood_rules(catalog: RefCounted) -> void:
	var level = Level.new(catalog.load_level(21))
	_check(level.plan_route(Vector2i(3, 1)).is_empty(), "Cannot route onto undrained water")
	level.positions[level.FIREFIGHTER] = Vector2i(2, 3)
	_check(not level.act(level.valve_pos) and not level.water_drained and level.history.is_empty(), "Wrong role cannot turn valve")
	level.reset()
	level.selected = level.ENGINEER
	level.positions[level.ENGINEER] = Vector2i(4, 1)
	_check(not level.act(level.bridge_pos) and not level.bridge_built and level.actions == 0, "Bridge repair requires drainage first")
	level.positions[level.ENGINEER] = Vector2i(2, 3)
	_check(level.act(level.valve_pos) and level.water_drained and level.actions == 1, "Engineer drains water from adjacent approach")
	_check(not level.act(level.valve_pos) and level.actions == 1, "Already open valve does not award moves or history")
	level.positions[level.ENGINEER] = Vector2i(4, 1)
	_check(level.act(level.bridge_pos) and level.bridge_built and level.positions[level.ENGINEER] == Vector2i(4, 1), "Bridge repair stays on approach tile")
	_check(level.undo() and not level.bridge_built and level.water_drained, "Bridge undo preserves prior valve state")
	_check(level.undo() and not level.water_drained, "Valve undo restores all flooded cells")
	level.reset()
	_check(Guidance.goal(level)["key"] == "valve", "Guidance starts with prerequisite valve")
	level.water_drained = true
	_check(Guidance.goal(level)["key"] == "bridge", "Guidance advances to bridge after draining")
	level.bridge_built = true
	_check(Guidance.goal(level)["key"] == "fire", "Guidance advances to firefighter ability")

func _test_resume(catalog: RefCounted) -> void:
	var session = Session.new(PATH)
	session.clear()
	var level = Level.new(catalog.load_level(3))
	var commands: Array = []
	_check(_tap(level, ["engineer", 3, 3], commands), "Checkpoint gate operation")
	_check(_tap(level, ["firefighter", 3, 1], commands), "Checkpoint fire ability")
	_check(_tap(level, ["firefighter", 5, 1], commands), "Checkpoint collected civilian")
	_check(session.save_session(level, commands, 2), "Write bounded resume journal")
	var restored: Dictionary = Session.new(PATH).restore(catalog)
	_check(not restored.is_empty(), "Fresh session replays checkpoint")
	if restored.is_empty(): return
	var resumed = restored["level"]
	_check(resumed.positions == level.positions and resumed.actions == level.actions and resumed.fire_cleared and resumed.gate_is_open() and resumed.carrying_role == level.carrying_role and restored["hint_stage"] == 2, "Resume restores precise puzzle and UI state")
	_check(resumed.undo() and resumed.carrying_role.is_empty() and resumed.fire_cleared and resumed.history.size() == 2, "Resumed undo restores one entire destination tap")
	# A partial walking animation checkpoints only accepted cells in its tap.
	level = Level.new(catalog.load_level(0))
	level.act(Vector2i(2, 1))
	commands = [{"role": "firefighter", "cells": [[2, 1]]}]
	session.save_session(level, commands, 0)
	restored = session.restore(catalog)
	_check(restored["level"].positions["firefighter"] == Vector2i(2, 1) and restored["level"].undo() and restored["level"].actions == 0, "Partial animated tap remains resumable and undoable")
	# Topology changes and their undo boundaries are reconstructed, not trusted fields.
	var flood = Level.new(catalog.load_level(21))
	var flood_commands: Array = []
	_tap(flood, ["engineer", 3, 3], flood_commands)
	_tap(flood, ["engineer", 5, 1], flood_commands)
	_check(session.save_session(flood, flood_commands, 1), "Checkpoint repaired crossing")
	var crossing: Dictionary = session.restore(catalog)
	_check(crossing["level"].water_drained and crossing["level"].bridge_built and crossing["level"].undo() and not crossing["level"].bridge_built and crossing["level"].water_drained, "Resume preserves water topology and bridge undo")
	# Restore the earlier partial-walk fixture for corruption/failure checks.
	session.save_session(level, commands, 0)
	var original := FileAccess.get_file_as_string(PATH)
	var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	file.store_string("{partial")
	file.close()
	_check(not session.restore(catalog).is_empty(), "Interrupted temporary write leaves committed checkpoint")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
	_check(not session.save_session(level, commands, 0) and FileAccess.get_file_as_string(PATH) == original, "Checkpoint write failure preserves previous bytes")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
	var valid: Dictionary = JSON.parse_string(original)
	for fault in ["role", "layout", "teleport", "fraction", "hint", "version"]:
		var data := valid.duplicate(true)
		match fault:
			"role": data["selected"] = "wizard"
			"layout": data["layout"] = "other-map"
			"teleport": data["commands"][0]["cells"] = [[7, 1]]
			"fraction": data["commands"][0]["cells"] = [[2.5, 1]]
			"hint": data["hint_stage"] = "two"
			"version": data["version"] = 99
		_write(JSON.stringify(data))
		_check(session.restore(catalog).is_empty(), "Malformed checkpoint rejected: " + fault)
	_write("{broken")
	_check(session.restore(catalog).is_empty(), "Corrupt JSON falls back to menu")
	# Valid winning traces cannot turn resume into a progress-grant mechanism.
	level = Level.new(catalog.load_level(0))
	commands = []
	_tap(level, ["firefighter", 3, 1], commands)
	_tap(level, ["firefighter", 5, 1], commands)
	_check(not session.save_session(level, commands, 0), "Completed mission is not resumable")
	valid["commands"] = commands
	_write(JSON.stringify(valid))
	_check(session.restore(catalog).is_empty(), "Completed trace cannot grant a victory on load")
	_write(" ".repeat(Session.MAX_BYTES + 1))
	_check(session.restore(catalog).is_empty(), "Oversized checkpoint rejected before parsing")
	session.clear()
	_check(session.restore(catalog).is_empty(), "Discarded/completed checkpoint disappears")

func _tap(level: RefCounted, step: Array, commands: Array) -> bool:
	if not level.select_role(step[0]): return false
	var route: Array[Vector2i] = level.plan_route(Vector2i(step[1], step[2]))
	if route.is_empty(): return false
	var before: int = level.history.size()
	var batch := {"role": step[0], "cells": []}
	for cell in route:
		if not level.act(cell): return false
		batch["cells"].append([cell.x, cell.y])
	level.collapse_history(before)
	commands.append(batch)
	return true

func _write(text: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _check(condition: bool, description: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: " + description)
