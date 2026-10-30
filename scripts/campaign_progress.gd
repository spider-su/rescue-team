extends RefCounted
## Monotonic local-only unlocks; progress does not depend on ephemeral CI debug keys.
const SAVE_PATH = "user://rescue_progress_v1.json"
var path: String
var best: Dictionary = {}

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
	if not best.has(level_id) or actions < best[level_id]:
		best[level_id] = actions
	return save_progress()

func save_progress() -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "best": best}))
	file.close()
	return true
