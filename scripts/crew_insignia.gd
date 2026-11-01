extends Control
## Original vector accessories, shared by crew portraits and board sprites.
var style_id := "standard":
	set(value):
		style_id = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	paint(self, style_id, size / 2, minf(size.x, size.y) * 0.43)

static func paint(canvas: CanvasItem, style: String, center: Vector2, radius: float) -> void:
	if style == "standard": return
	var color := Color("#edba4d") if style in ["ribbon", "captain"] else Color("#57c4c9")
	canvas.draw_circle(center, radius, Color("#214f62"))
	canvas.draw_arc(center, radius * 0.87, 0, TAU, 24, color, maxf(1.0, radius * 0.15), true)
	if style == "captain":
		var points := PackedVector2Array()
		for i in range(10):
			points.append(center + Vector2.UP.rotated(float(i) * TAU / 10) * radius * (0.76 if i % 2 == 0 else 0.34))
		canvas.draw_colored_polygon(points, color)
	elif style == "floodworks":
		canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius * 0.7), center + Vector2(radius * 0.45, radius * 0.25), center + Vector2(-radius * 0.45, radius * 0.25)]), color)
		canvas.draw_circle(center + Vector2(0, radius * 0.2), radius * 0.45, color)
	elif style == "harbor":
		canvas.draw_line(center + Vector2(0, -radius * 0.6), center + Vector2(0, radius * 0.55), color, maxf(2, radius * 0.18))
		canvas.draw_arc(center, radius * 0.55, 0, PI, 16, color, maxf(2, radius * 0.18), true)
	else:
		canvas.draw_circle(center, radius * 0.42, color)
		for x in [-0.3, 0.3]:
			canvas.draw_line(center + Vector2(x, 0.25) * radius, center + Vector2(x * 1.2, 0.8) * radius, color, maxf(2, radius * 0.2))
