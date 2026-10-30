extends RefCounted
## Pure, deterministic demo session model. Replace with game-specific rules.

var score: int = 0
var best: int = 0
var paused: bool = false

func tap() -> bool:
	if paused:
		return false
	score += 1
	best = maxi(best, score)
	return true

func toggle_pause() -> void:
	paused = not paused

func restart() -> void:
	score = 0
	paused = false

func save_best(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"best": best}))
	return true

func load_best(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		var value: Variant = data.get("best")
		# Godot JSON parsing can represent integral numbers as floats.
		if (value is int or value is float) and value >= 0 and value == floor(value):
			best = int(value)
