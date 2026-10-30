extends SceneTree
## Validate all shipped JSON missions and complete each using actual tap-to-move rules.
const Catalog = preload("res://scripts/level_catalog.gd")
const RescueLevel = preload("res://scripts/rescue_level.gd")
const Progress = preload("res://scripts/campaign_progress.gd")

func _initialize() -> void:
	var catalog = Catalog.new()
	if not _assert(catalog.count() == 5, "five curated missions"):
		return
	var expected_ids := ["01", "02", "03", "04", "05"]
	for index in range(catalog.count()):
		var definition: Dictionary = catalog.load_level(index)
		if not _assert(not definition.is_empty() and definition["id"] == expected_ids[index], "mission identity / JSON %d" % index):
			return
		if not _assert(catalog.validate(definition).is_empty(), "mission schema %d" % index):
			return

	var broken: Dictionary = catalog.load_level(0).duplicate(true)
	broken["rows"][1] = "broken"
	if not _assert(not catalog.validate(broken).is_empty(), "reject unequal rows"):
		return
	broken = catalog.load_level(0).duplicate(true)
	broken["rows"][1] = broken["rows"][1].replace("F", ".")
	if not _assert(not catalog.validate(broken).is_empty(), "reject missing firefighter"):
		return

	# This covers the gradual learning curve (civilian, fire, crate/gate, both, two pushes).
	var actions_by_level: Array = [
		[["firefighter", 3, 1], ["firefighter", 5, 1]],
		[["firefighter", 3, 1], ["firefighter", 5, 1], ["firefighter", 7, 1]],
		[["engineer", 3, 3], ["firefighter", 4, 1], ["firefighter", 7, 1]],
		[["engineer", 3, 3], ["firefighter", 3, 1], ["firefighter", 5, 1], ["firefighter", 8, 1]],
		[["engineer", 4, 3], ["engineer", 5, 3], ["firefighter", 4, 1], ["firefighter", 7, 1], ["firefighter", 10, 1]],
	]
	for index in range(catalog.count()):
		var mission = RescueLevel.new(catalog.load_level(index))
		if not _assert(mission.width > 0 and mission.height > 0, "loaded board dimensions %d" % index):
			return
		for item in actions_by_level[index]:
			if not _assert(mission.select_role(item[0]), "select role in mission %d" % index):
				return
			if not _assert(_navigate(mission, Vector2i(item[1], item[2])), "legal solution for mission %d, target %s" % [index, Vector2i(item[1], item[2])]):
				return
		if not _assert(mission.rescued, "mission %d wins" % index):
			return

	var save_path := "user://rescue_campaign_test.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var progress = Progress.new(save_path)
	if not _assert(progress.unlocked(0, catalog) and not progress.unlocked(1, catalog), "only first mission initially unlocked"):
		return
	if not _assert(progress.record_victory("01", 12), "write first completion"):
		return
	if not _assert(progress.unlocked(1, catalog) and not progress.unlocked(2, catalog), "only next mission unlocks"):
		return
	if not _assert(progress.record_victory("01", 16) and progress.best["01"] == 12, "preserve best move count"):
		return
	if not _assert(not progress.record_victory("bogus", 1) and not progress.record_victory("02", -1), "reject unknown / negative progress"):
		return
	var reloaded = Progress.new(save_path)
	if not _assert(reloaded.is_complete("01") and reloaded.best["01"] == 12 and reloaded.unlocked(1, catalog), "progress survives app restart"):
		return
	var corrupt := FileAccess.open(save_path, FileAccess.WRITE)
	corrupt.store_string("{not json")
	corrupt.close()
	reloaded = Progress.new(save_path)
	if not _assert(reloaded.best.is_empty() and not reloaded.unlocked(1, catalog), "invalid progress falls back safely"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("PASS: five validated/solvable missions, saved unlock progression and corrupt save handling")
	quit(0)

func _navigate(mission: RefCounted, target: Vector2i) -> bool:
	var route: Array[Vector2i] = mission.plan_route(target)
	if route.is_empty():
		return false
	var from_index: int = mission.history.size()
	for step in route:
		if not mission.act(step):
			return false
	mission.collapse_history(from_index)
	return true

func _assert(condition: bool, description: String) -> bool:
	if condition:
		return true
	push_error("FAIL: " + description)
	quit(1)
	return false
