extends RefCounted
## Monotonic local-only unlocks; progress does not depend on ephemeral CI debug keys.
const SAVE_PATH = "user://rescue_progress_v1.json"
var path: String
var best: Dictionary = {}

## Authored targets use the same step metric as existing version-1 best scores.
var star_targets: Dictionary = {}

func stars_for(level_id: String, actions: int) -> int:
	if not star_targets.has(level_id) or actions < 0:
		return 0
	var targets: Dictionary = star_targets[level_id]
	if actions <= targets["three"]:
		return 3
	return 2 if actions <= targets["two"] else 1

func earned_stars(level_id: String) -> int:
	if not best.has(level_id):
		return 0
	return stars_for(level_id, int(best[level_id]))

func total_stars() -> int:
	var total := 0
	for id in best:
		total += earned_stars(id)
	return total

func total_xp() -> int:
	return best.size() * 50 + total_stars() * 20

func rescuer_level() -> int:
	return int(total_xp() / 100) + 1

func rescuer_rank() -> String:
	var level: int = rescuer_level()
	if level >= 10:
		return "Rescue Captain"
	if level >= 6:
		return "Rescue Specialist"
	if level >= 3:
		return "Rescue Volunteer"
	return "Rescue Recruit"

func earned_badges() -> Array[String]:
	var result: Array[String] = []
	if best.size() > 0:
		result.append("First Rescue")
	var coastal := 0
	var perfect := 0
	for id in best:
		if String(id).to_int() <= 10:
			coastal += 1
		if earned_stars(id) == 3:
			perfect += 1
	if coastal >= 10:
		result.append("Harbor Guardian")
	if perfect > 0:
		result.append("Perfect Planner")
	if perfect >= 10:
		result.append("Master Rescuer")
	var old_town_complete := true
	for id in range(11, 21):
		old_town_complete = old_town_complete and best.has(str(id))
	if old_town_complete:
		result.append("Old Town Protector")
	return result


func _init(file_path: String = SAVE_PATH) -> void:
	var catalog = preload("res://scripts/level_catalog.gd").new()
	for i in range(catalog.count()):
		var data: Dictionary = catalog.load_level(i)
		star_targets[data["id"]] = {"three": data["three_star_moves"], "two": data["two_star_moves"]}
	path = file_path
	load_progress()

func load_progress() -> void:
	best.clear()
	if not FileAccess.file_exists(path):
		return
	var parser := JSON.new()
	# Parsing errors in user data are expected; avoid emitting engine error logs.
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return
	var parsed: Variant = parser.data
	if not parsed is Dictionary or parsed.get("version") != 1 or not parsed.get("best") is Dictionary:
		return
	var catalog = preload("res://scripts/level_catalog.gd").new()
	var valid_ids: Dictionary = {}
	for index in range(catalog.count()):
		var level_data: Dictionary = catalog.load_level(index)
		if not level_data.is_empty():
			valid_ids[level_data["id"]] = true
	for key in parsed["best"]:
		var value: Variant = parsed["best"][key]
		if valid_ids.has(key) and (value is float or value is int) and value >= 0 and value <= 100000 and value == floor(value):
			best[key] = int(value)

func is_complete(level_id: String) -> bool:
	return best.has(level_id)

func unlocked(index: int, catalog: RefCounted) -> bool:
	if index < 0 or index >= catalog.count():
		return false
	if index == 20:
		return is_complete("05") # Optional trials never block the original campaign.
	if index == 0:
		return true
	var prior: Dictionary = catalog.load_level(index - 1)
	return not prior.is_empty() and is_complete(prior["id"])

func record_victory(level_id: String, actions: int) -> bool:
	if actions < 0 or actions > 100000:
		return false
	var catalog = preload("res://scripts/level_catalog.gd").new()
	var known: bool = false
	for i in range(catalog.count()):
		var definition: Dictionary = catalog.load_level(i)
		if not definition.is_empty() and definition["id"] == level_id:
			known = true
	if not known:
		return false
	var previous_best := best.duplicate()
	if not best.has(level_id) or actions < best[level_id]:
		best[level_id] = actions
	if save_progress():
		return true
	best = previous_best
	return false

func save_progress() -> bool:
	# Keep the committed save intact until its replacement is fully written.
	# A sibling temporary file stays on the same filesystem for atomic rename.
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "best": best}))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error == OK:
		var rename_error := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(temporary_path), ProjectSettings.globalize_path(path)
		)
		if rename_error == OK:
			return true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
	return false
