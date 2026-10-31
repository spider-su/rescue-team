extends RefCounted
## Monotonic local-only unlocks; progress does not depend on ephemeral CI debug keys.
const SAVE_PATH = "user://rescue_progress_v1.json"
var path: String
const THREE_STAR_MOVES = {"01": 2, "02": 3, "03": 3, "04": 4, "05": 5, "06": 5, "07": 6, "08": 4, "09": 6, "10": 6}
var best: Dictionary = {}

func stars_for(level_id: String, actions: int) -> int:
	if not THREE_STAR_MOVES.has(level_id) or actions < 0:
		return 0
	var target: int = THREE_STAR_MOVES[level_id]
	if actions <= target:
		return 3
	if actions <= target + 2:
		return 2
	return 1

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
	return total_xp() / 100 + 1

func rescuer_rank() -> String:
	var level: int = rescuer_level()
	if level >= 10:
		return "Coastal Legend"
	if level >= 6:
		return "Rescue Captain"
	if level >= 3:
		return "Rescue Specialist"
	return "Rescue Recruit"

func earned_badges() -> Array[String]:
	var result: Array[String] = []
	if best.size() > 0:
		result.append("First Rescue")
	if best.size() >= 10:
		result.append("Harbor Guardian")
	var perfect := 0
	for id in best:
		if earned_stars(id) == 3:
			perfect += 1
	if perfect > 0:
		result.append("Perfect Planner")
	if perfect == 10:
		result.append("Master Rescuer")
	return result


func _init(file_path: String = SAVE_PATH) -> void:
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
