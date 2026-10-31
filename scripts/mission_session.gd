extends RefCounted
## An unfinished mission is a bounded action journal, replayed through real rules.
const Level = preload("res://scripts/rescue_level.gd")
var path: String
const MAX_BYTES = 262144
const MAX_TAPS = 500
const MAX_STEPS = 10000

func _init(file_path: String = "user://rescue_session_v1.json") -> void:
	path = file_path

func save_session(level: RefCounted, commands: Array, hint_stage: int) -> bool:
	if level.rescued or commands.size() > MAX_TAPS:
		return false
	var step_count := 0
	for command in commands:
		step_count += command["cells"].size()
	if step_count > MAX_STEPS:
		return false
	var payload := {"version": 1, "id": level.level_id, "layout": JSON.stringify(level._definition["rows"]).sha256_text(),
		"commands": commands, "selected": level.selected, "hint_stage": hint_stage}
	var text := JSON.stringify(payload)
	if text.length() > MAX_BYTES:
		return false
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK and DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path)) == OK:
		return true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
	return false

func restore(catalog: RefCounted) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var data: Variant = parser.data
	if not data is Dictionary or data.get("version") != 1 or not data.get("commands") is Array:
		return {}
	var index := -1
	for i in range(catalog.count()):
		if catalog.load_level(i)["id"] == data.get("id"):
			index = i
	if index < 0 or data["commands"].size() > MAX_TAPS:
		return {}
	var definition: Dictionary = catalog.load_level(index)
	if data.get("layout") != JSON.stringify(definition["rows"]).sha256_text():
		return {} # Content changed: never apply old coordinates to a different map.
	var level = Level.new(definition)
	var steps := 0
	for command in data["commands"]:
		if not command is Dictionary or not command.get("cells") is Array or command["cells"].is_empty():
			return {}
		if not command.get("role") is String or not level.select_role(command["role"]):
			return {}
		var before: int = level.history.size()
		for point in command["cells"]:
			steps += 1
			if steps > MAX_STEPS or not point is Array or point.size() != 2:
				return {}
			if not _coordinate(point[0], level.width) or not _coordinate(point[1], level.height):
				return {}
			if not level.act(Vector2i(int(point[0]), int(point[1]))) or level.rescued:
				return {} # Resume cannot grant a victory or bypass rules.
		level.collapse_history(before)
	if not data.get("selected") is String or not level.select_role(data["selected"]):
		return {}
	var hints: Variant = data.get("hint_stage", 0)
	if not (hints is float or hints is int) or hints < 0 or hints > 2 or hints != floor(hints):
		return {}
	level.message = "Mission resumed. Your route and undo history are restored."
	return {"index": index, "level": level, "commands": data["commands"], "hint_stage": int(hints)}

func clear() -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

static func _coordinate(value: Variant, limit: int) -> bool:
	return (value is int or value is float) and value >= 0 and value < limit and value == floor(value)
