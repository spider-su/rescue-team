extends RefCounted
## Explicit manifest: only curated, reviewed level files are loaded.
const PATHS = [
	"res://levels/01.json",
	"res://levels/02.json",
	"res://levels/03.json",
	"res://levels/04.json",
	"res://levels/05.json",
	"res://levels/6.json",
	"res://levels/7.json",
	"res://levels/8.json",
	"res://levels/9.json",
	"res://levels/10.json",
	"res://levels/old-town/11.json",
	"res://levels/old-town/12.json",
	"res://levels/old-town/13.json",
	"res://levels/old-town/14.json",
	"res://levels/old-town/15.json",
	"res://levels/old-town/16.json",
	"res://levels/old-town/17.json",
	"res://levels/old-town/18.json",
	"res://levels/old-town/19.json",
	"res://levels/old-town/20.json",
	"res://levels/floodworks/21.json",
	"res://levels/floodworks/22.json",
	"res://levels/floodworks/23.json",
]
const LOCATIONS = [
	{"id": "coast", "title": "Coastal District", "first": 0, "count": 10},
	{"id": "old-town", "title": "Old Town Quarantine", "first": 10, "count": 10},
	{"id": "floodworks", "title": "Floodworks Trials", "first": 20, "count": 3},
]
const ALLOWED = ".#FERCXfBsGZV~="

func location_for(index: int) -> int:
	return 0 if index < 10 else (1 if index < 20 else 2)

func count() -> int:
	return PATHS.size()

func load_level(index: int) -> Dictionary:
	if index < 0 or index >= PATHS.size():
		push_error("Invalid mission index: %d" % index)
		return {}
	var file := FileAccess.open(PATHS[index], FileAccess.READ)
	if file == null:
		push_error("Cannot read mission: " + PATHS[index])
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	if not value is Dictionary:
		push_error("Invalid mission JSON: " + PATHS[index])
		return {}
	var error := validate(value)
	if not error.is_empty():
		push_error("Invalid mission %s: %s" % [PATHS[index], error])
		return {}
	return value

func validate(data: Dictionary) -> String:
	for key in ["id", "title", "hint", "rows"]:
		if not data.has(key):
			return "missing " + key
	if not data["id"] is String or String(data["id"]).is_empty():
		return "invalid id"
	if data.get("location", "coast") not in ["coast", "old-town", "floodworks"]:
		return "unknown location"
	if not data["title"] is String or String(data["title"]).is_empty():
		return "invalid title"
	if not data["hint"] is String or not data["rows"] is Array:
		return "invalid hint or rows"
	if data.has("three_star_moves") or data.has("two_star_moves"):
		var three: Variant = data.get("three_star_moves", -1)
		var two: Variant = data.get("two_star_moves", -1)
		if not (three is int or three is float) or not (two is int or two is float):
			return "star targets must be numbers"
		if three < 0 or two < three or two > 100000 or three != floor(three) or two != floor(two):
			return "invalid star targets"
	var rows: Array = data["rows"]
	if rows.size() < 3 or rows.size() > 24:
		return "board height must be 3..24"
	if not rows[0] is String:
		return "row must be text"
	var width: int = rows[0].length()
	if width < 5 or width > 24:
		return "board width must be 5..24"
	var counts: Dictionary = {}
	for y in range(rows.size()):
		if not rows[y] is String or rows[y].length() != width:
			return "unequal row widths"
		for x in range(width):
			var symbol: String = rows[y].substr(x, 1)
			if not ALLOWED.contains(symbol):
				return "unknown tile: " + symbol
			if y == 0 or y == rows.size() - 1 or x == 0 or x == width - 1:
				if symbol != "#":
					return "map border must be walls"
			counts[symbol] = counts.get(symbol, 0) + 1
	for marker in ["F", "E", "C", "X"]:
		if counts.get(marker, 0) != 1:
			return "expected exactly one " + marker
	for marker in ["f", "B", "s", "G", "V", "="]:
		if counts.get(marker, 0) > 1:
			return "multiple " + marker + " tiles unsupported"
	if counts.get("R", 0) > 1 or counts.get("Z", 0) > 6:
		return "at most one ranger and six infected supported"
	if counts.get("Z", 0) > 0 and counts.get("R", 0) != 1:
		return "infected require a ranger"
	if (counts.get("~", 0) > 0 or counts.get("=", 0) > 0) and counts.get("V", 0) != 1:
		return "flooded routes and bridges require one valve"
	var any_gate: bool = counts.get("B", 0) > 0 or counts.get("s", 0) > 0 or counts.get("G", 0) > 0
	if any_gate and not (counts.get("B", 0) == 1 and counts.get("s", 0) == 1 and counts.get("G", 0) == 1):
		return "crate, switch and gate must be specified together"
	return ""
