extends SceneTree
## Validate all shipped JSON missions and complete each using actual tap-to-move rules.
const Catalog = preload("res://scripts/level_catalog.gd")
const RescueLevel = preload("res://scripts/rescue_level.gd")
const Progress = preload("res://scripts/campaign_progress.gd")

func _initialize() -> void:
	var catalog = Catalog.new()
	if not _assert(catalog.count() == 23, "twenty campaign missions and three trials"):
		return
	var expected_ids := ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23"]
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
	var solutions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/coastal_solutions.json"))
	for index in range(solutions.size()):
		var mission = RescueLevel.new(catalog.load_level(index))
		if not _assert(mission.width > 0 and mission.height > 0, "loaded board dimensions %d" % index):
			return
		for item in solutions["%02d" % (index + 1)]:
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
	if not _assert(progress.stars_for("01", 4) == 3 and progress.stars_for("01", 6) == 2 and progress.stars_for("01", 7) == 1, "star tier boundaries"):
		return
	if not _assert(progress.stars_for("11", 42) == 3 and progress.stars_for("20", 126) == 2 and progress.stars_for("bogus", 1) == 0, "old town thresholds and unknown ids"):
		return
	if not _assert(progress.record_victory("01", 12), "write first completion"):
		return
	if not _assert(progress.unlocked(1, catalog) and not progress.unlocked(2, catalog), "only next mission unlocks"):
		return
	if not _assert(progress.record_victory("01", 16) and progress.best["01"] == 12 and progress.earned_stars("01") == 1, "worse replay preserves best and stars"):
		return
	if not _assert(not progress.record_victory("bogus", 1) and not progress.record_victory("02", -1), "reject unknown / negative progress"):
		return
	var reloaded = Progress.new(save_path)
	if not _assert(reloaded.is_complete("01") and reloaded.best["01"] == 12 and reloaded.earned_stars("01") == 1 and reloaded.unlocked(1, catalog), "stars derive from existing save after restart"):
		return
	if not _test_safe_saves(progress, catalog):
		return
	if not _assert(progress.record_victory("01", 2) and progress.earned_stars("01") == 3 and progress.total_stars() == 3 and progress.total_xp() == 110, "better replay upgrades stars and XP"):
		return
	reloaded = Progress.new(save_path)
	if not _assert(reloaded.best["01"] == 2 and reloaded.earned_stars("01") == 3, "upgraded stars derive from saved best after restart"):
		return
	var corrupt := FileAccess.open(save_path, FileAccess.WRITE)
	corrupt.store_string("{not json")
	corrupt.close()
	reloaded = Progress.new(save_path)
	if not _assert(reloaded.best.is_empty() and not reloaded.unlocked(1, catalog), "invalid progress falls back safely"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("PASS: ten validated/solvable missions, saved unlock progression and corrupt save handling")
	quit(0)

func _test_safe_saves(progress: RefCounted, catalog: RefCounted) -> bool:
	var save_path: String = progress.path
	var temp_path := save_path + ".tmp"
	# Simulate termination during a replacement write: the committed save wins.
	var interrupted := FileAccess.open(temp_path, FileAccess.WRITE)
	interrupted.store_string("{partial")
	interrupted.close()
	var reloaded = Progress.new(save_path)
	if not _assert(reloaded.best == progress.best and reloaded.unlocked(1, catalog), "partial temporary save preserves committed progress"):
		return false
	if not _assert(progress.record_victory("01", 10), "replace existing save after interrupted write"):
		return false
	reloaded = Progress.new(save_path)
	if not _assert(reloaded.best["01"] == 10 and not FileAccess.file_exists(temp_path), "replacement persists improved score and removes temporary file"):
		return false
	var original := FileAccess.get_file_as_string(save_path)
	# A directory at the temporary path forces an actual file-open failure.
	if not _assert(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(temp_path)) == OK, "prepare failed temporary write"):
		return false
	var saved: bool = progress.record_victory("02", 8)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	if not _assert(not saved and not progress.is_complete("02") and not progress.unlocked(2, catalog), "failed save does not grant an unpersisted unlock"):
		return false
	if not _assert(FileAccess.get_file_as_string(save_path) == original, "failed write preserves prior save bytes"):
		return false
	# A directory destination forces rename to fail after the write succeeds.
	var blocked_path := save_path + ".blocked"
	if not _assert(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocked_path)) == OK, "prepare failed save replacement"):
		return false
	var blocked = Progress.new(blocked_path)
	saved = blocked.record_victory("01", 3)
	var leftover := FileAccess.file_exists(blocked_path + ".tmp")
	var directory_preserved := DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(blocked_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_path + ".tmp"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_path))
	if not _assert(not saved and blocked.best.is_empty() and not leftover and directory_preserved, "failed replacement reports failure, rolls back and cleans temporary file"):
		return false
	return true

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
