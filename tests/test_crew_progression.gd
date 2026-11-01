extends SceneTree
## Verify local-only crew names, cosmetic milestones and district recovery state.
const Progress = preload("res://scripts/campaign_progress.gd")
const Crew = preload("res://scripts/crew_progression.gd")
const District = preload("res://scripts/district_recovery.gd")
const PATH = "user://crew_progression_test.cfg"
var failed := false

func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
	var progress = Progress.new("user://crew_progression_progress_test.json")
	progress.best = {}
	_check(Crew.unlocked(progress) == ["standard"], "A new crew starts with the field kit")
	progress.best["01"] = 3
	_check(Crew.unlocked(progress) == ["standard", "ribbon"], "First saved rescue unlocks the rescue ribbon")
	for id in ["02", "03", "04", "05"]:
		progress.best[id] = 8
	_check("harbor" in Crew.unlocked(progress) and "captain" not in Crew.unlocked(progress), "Five saved rescues unlock harbor colours")
	for id in ["06", "07", "08", "09", "10"]:
		progress.best[id] = 10
	_check("captain" in Crew.unlocked(progress), "Ten saved rescues unlock the captain star")
	for id in ["21", "22", "23"]:
		progress.best[id] = 12
	_check("floodworks" in Crew.unlocked(progress), "All optional trials unlock the Floodworks crest")
	var crew = Crew.new(PATH)
	_check(crew.equip("captain", progress), "Unlocked cosmetic choice saves locally")
	var restored = Crew.new(PATH)
	_check(restored.equipped == "captain", "Crew cosmetic choice survives a fresh load")
	progress.best = {}
	for id in ["01", "02", "03", "04", "05", "06", "07", "08", "09"]:
		progress.best[id] = 8
	restored.validate_equipped(progress)
	_check(restored.equipped == "standard", "Unavailable cosmetic selection resets safely")
	var first := restored.line("firefighter", "select")
	var second := restored.line("firefighter", "select")
	_check(first != second, "A hero does not repeat the same immediate selection line")
	var district = District.new()
	district.configure(progress, {"id": "coast", "first": 0, "count": 10})
	_check(district.repaired.size() == 10 and district.repaired.count(true) == 9 and not district.repaired[9], "District repair state follows each completed address")
	var fail_path := "user://crew_progression_blocked.cfg"
	var fail_temp := ProjectSettings.globalize_path(fail_path + ".tmp")
	DirAccess.remove_absolute(fail_temp)
	DirAccess.make_dir_absolute(fail_temp)
	var failing = Crew.new(fail_path)
	_check(not failing.equip("ribbon", progress) and not failing.settings_saved, "Cosmetic write failure is reported without pretending it saved")
	DirAccess.remove_absolute(fail_temp)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://crew_progression_progress_test.json"))
	if not failed:
		print("PASS: named crew, cosmetic milestones, local persistence and district recovery")
	quit(1 if failed else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: " + description)
