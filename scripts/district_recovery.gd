extends Control
## Original street diorama: one address restored for each unique saved rescue.
const UI = preload("res://scripts/coastal_style.gd")
var repaired: Array[bool] = []
var first_id := 1
var district := "coast"

func configure(progress: RefCounted, location: Dictionary) -> void:
	repaired.clear()
	first_id = location["first"] + 1
	district = location["id"]
	for i in range(location["count"]): repaired.append(progress.is_complete("%02d" % (first_id + i)))
	custom_minimum_size = Vector2.ZERO
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ZERO

func _draw() -> void:
	if repaired.is_empty(): return
	var columns := 5 if repaired.size() > 3 else 3
	var rows := ceili(float(repaired.size()) / columns)
	var slot := Vector2((size.x - 20) / columns, 85)
	draw_style_box(UI.box(Color("#e4eee2"), UI.LINE, 14, 0), Rect2(Vector2.ZERO, size))
	var count := repaired.count(true)
	draw_string(UI.HEADING, Vector2(14, 27), "DISTRICT RECOVERY  %d / %d" % [count, repaired.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 23, UI.INK)
	for row in range(rows):
		var y := 42 + (row + 1) * slot.y - 8
		draw_line(Vector2(10, y), Vector2(size.x - 10, y), Color("#bcb8a4"), 8)
	for i in range(repaired.size()):
		var base := Vector2(10 + (i % columns) * slot.x + slot.x * 0.5, 43 + (i / columns) * slot.y)
		var width := minf(66, slot.x * 0.67)
		var house := Rect2(base + Vector2(-width / 2, 14), Vector2(width, 48))
		var fixed: bool = repaired[i]
		draw_rect(house, Color("#e7c696") if fixed else Color("#9a9d96"))
		var roof_color := Color("#a76144") if district == "coast" else Color("#77618c")
		var roof := PackedVector2Array([base + Vector2(-width * 0.6, 15), base + Vector2(0, -3 if fixed else 7), base + Vector2(width * 0.6, 15)])
		draw_colored_polygon(roof, roof_color if fixed else Color("#666d69"))
		for x in [-0.24, 0.24]:
			var window := Rect2(base + Vector2(width * x - 5, 25), Vector2(10, 13))
			draw_rect(window, Color("#ffe492") if fixed else Color("#40565b"))
			if not fixed: draw_line(window.position, window.end, Color("#a18060"), 3)
		draw_rect(Rect2(base + Vector2(-5, 44), Vector2(10, 18)), Color("#697b70"))
		if fixed:
			var person := base + Vector2(width * 0.55, 56)
			draw_circle(person, 4, Color("#d5a27b"))
			draw_line(person + Vector2(0, 4), person + Vector2(0, 13), UI.TEAL, 5)
			for offset in [Vector2(-5, 0), Vector2(0, -4), Vector2(5, 0)]:
				draw_circle(base + Vector2(-width * 0.57, 53) + offset, 3, Color("#d897a8"))
		else:
			draw_line(base + Vector2(-width * 0.6, 57), base + Vector2(width * 0.6, 57), Color("#b88c53"), 4)
		var address := "%02d" % (first_id + i)
		draw_string(UI.FONT, base + Vector2(-9, 78), address, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UI.INK)
