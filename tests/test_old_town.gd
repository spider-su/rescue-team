extends SceneTree
const Catalog = preload("res://scripts/level_catalog.gd")
const Level = preload("res://scripts/rescue_level.gd")
const Progress = preload("res://scripts/campaign_progress.gd")
var failed := false

func _initialize() -> void:
	var catalog = Catalog.new()
	var solutions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/old_town_solutions.json"))
	var layouts: Dictionary = {}
	_check(catalog.count() == 20 and solutions.size() == 10, "Two locations with ten missions each")
	for index in range(10, 20):
		var data: Dictionary = catalog.load_level(index)
		if data.is_empty():
			_check(false, "Valid old-town map")
			continue
		var mission = Level.new(data)
		var layout := "\n".join(data["rows"])
		_check(not layouts.has(layout), "Every Old Town map has distinct authored content")
		layouts[layout] = true
		var initial_infected: Dictionary = mission.infected.duplicate()
		_check(mission.positions.has(mission.RANGER) and not initial_infected.is_empty(), "Every new mission includes ranger and infected")
		var steps: Array = solutions[data["id"]]
		var minimum_z := initial_infected.size()
		for step in steps:
			mission.select_role(step[0])
			var target := Vector2i(step[1], step[2])
			var route: Array[Vector2i] = mission.plan_route(target)
			if route.is_empty():
				_check(false, "Mission %s: no route for %s to %s (%s)" % [data["id"], step[0], target, mission.message])
				break
			var before: int = mission.history.size()
			for cell in route:
				if not mission.act(cell):
					_check(false, "Mission %s: invalid step %s (%s)" % [data["id"], cell, mission.message])
					break
			mission.collapse_history(before)
		_check(mission.rescued and mission.infected.is_empty() and mission.fire_cleared and mission.gate_is_open(), "Mission %s full cooperative winning path" % data["id"])
		_check(mission.actions >= 30 and steps.size() >= 8, "New walkthrough combines abilities and multiple route decisions")
		print("Mission %s: %d destination taps, %d moves, %d infected" % [data["id"], steps.size(), mission.actions, minimum_z])
		while not mission.history.is_empty():
			mission.undo()
		_check(mission.infected == initial_infected and mission.actions == 0 and not mission.rescued and mission.carrying_role.is_empty() and not mission.gate_is_open(), "Whole solution undo restores hazards and initial state")
		mission.reset()
		_check(mission.infected == initial_infected and mission.positions.has(mission.RANGER), "Restart restores ranger and every infected")
	_test_rules(catalog)
	_test_progress(catalog)
	if not failed:
		print("PASS: ten Old Town solutions, third-role restrictions, infected undo/restart and save compatibility")
	quit(1 if failed else 0)

func _test_rules(catalog: RefCounted) -> void:
	var data: Dictionary = catalog.load_level(10)
	var invalid := data.duplicate(true)
	for i in range(invalid["rows"].size()):
		invalid["rows"][i] = invalid["rows"][i].replace("R", ".")
	_check(not catalog.validate(invalid).is_empty(), "Infected without ranger is invalid content")
	var level = Level.new(data)
	var target: Vector2i = level.infected.keys()[0]
	for role in [level.FIREFIGHTER, level.ENGINEER]:
		level.selected = role
		level.positions[role] = target - Vector2i.RIGHT
		_check(not level.act(target) and level.infected.has(target) and level.history.is_empty(), "Other specialists cannot remove or enter infected")
		level.reset()
	level.selected = level.RANGER
	level.positions[level.RANGER] = target - Vector2i.RIGHT
	_check(level.act(target) and not level.infected.has(target) and level.actions == 1, "Adjacent stun clears infected and counts one action")
	_check(level.positions[level.RANGER] == target - Vector2i.RIGHT, "Stun does not move ranger")
	_check(level.undo() and level.infected.has(target) and level.actions == 0, "Undo restores infected")
	level.positions[level.RANGER] = target - Vector2i(1, 1)
	_check(not level.act(target), "No diagonal or ranged stun")
	level.reset()
	level.selected = level.ENGINEER
	level.positions[level.ENGINEER] = level.crate_pos - Vector2i.RIGHT
	level.infected[level.crate_pos + Vector2i.RIGHT] = true
	_check(not level.act(level.crate_pos) and level.history.is_empty(), "Cannot push crate onto infected")
	level.reset()
	level.selected = level.RANGER
	level.positions[level.RANGER] = level.fire_pos - Vector2i.RIGHT
	_check(not level.act(level.fire_pos) and not level.fire_cleared, "Ranger cannot extinguish fire")
	level.positions[level.RANGER] = level.crate_pos - Vector2i.RIGHT
	_check(not level.act(level.crate_pos), "Ranger cannot push crates")

func _test_progress(catalog: RefCounted) -> void:
	var path := "user://old_town_progress_test.json"
	var records: Dictionary = {}
	for i in range(1, 11):
		records["%02d" % i] = i + 10
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "best": records}))
	file.close()
	var progress = Progress.new(path)
	_check(progress.best == records and progress.unlocked(10, catalog) and not progress.unlocked(11, catalog), "Existing ten-mission save preserves scores and unlocks only first Old Town mission")
	_check(progress.record_victory("11", 50), "New mission completion saves in existing format")
	var reloaded = Progress.new(path)
	_check(reloaded.best["01"] == 11 and reloaded.best["11"] == 50 and reloaded.unlocked(11, catalog) and not reloaded.unlocked(12, catalog), "Both locations persist without losing old scores")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, description: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: " + description)
