extends Control
## Lightweight tile renderer without artwork or plugins; replace with original art later.
signal cell_tapped(cell: Vector2i)
var level: RefCounted
var route_preview: Array[Vector2i] = []
var animated_role: String = ""
var animated_position: Vector2 = Vector2.ZERO

const FLOOR = Color("#25384d")
const WALL = Color("#122334")
const GRID = Color("#32485e")
const TEXT = Color("#ffffff")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func _metrics() -> Dictionary:
	if level == null:
		return {}
	var cell_size: float = floorf(minf(size.x / float(level.width), size.y / float(level.height)))
	if cell_size < 12.0:
		return {}
	var origin: Vector2 = (size - Vector2(level.width, level.height) * cell_size) / 2.0
	return {"cell_size": cell_size, "origin": origin}

func _draw() -> void:
	var metrics: Dictionary = _metrics()
	if metrics.is_empty():
		return
	var step: float = metrics["cell_size"]
	var origin: Vector2 = metrics["origin"]
	for y in range(level.height):
		for x in range(level.width):
			var cell := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(x, y) * step + Vector2.ONE, Vector2.ONE * (step - 2.0))
			var tile: String = level.tile_at(cell)
			var color := FLOOR
			match tile:
				"wall": color = WALL
				"exit": color = Color("#24785c")
				"switch": color = Color("#245c92")
				"gate": color = Color("#923c49")
				"open_gate": color = Color("#36734c")
			draw_rect(rect, color, true)
			draw_rect(rect, GRID, false, 1.0)
			if tile == "wall":
				draw_line(rect.position + Vector2(3.0, 4.0), rect.position + Vector2(rect.size.x - 4.0, 4.0), Color("#2a465d"), 2.0)
			else:
				draw_circle(rect.position + rect.size * 0.24, step * 0.023, Color("#3d5267"))
			var center := rect.get_center()
			if tile == "switch":
				draw_arc(center, step * 0.28, 0.0, TAU, 28, Color("#8dd4ff"), 3.0)
			elif tile == "gate" or tile == "open_gate":
				_draw_gate(center, step, tile == "open_gate")
			elif tile == "exit":
				_draw_exit(center, step)

	# Route dots make one-tap movement visible before and during animation.
	for cell in route_preview:
		var dot: Vector2 = origin + (Vector2(cell) + Vector2(0.5, 0.5)) * step
		draw_circle(dot, step * 0.11, Color("#afe8ff", 0.70))
	if level.has_fire and not level.fire_cleared:
		_draw_marker(level.fire_pos, origin, step, Color("#e86440"), "!", false)
	if level.has_crate:
		_draw_marker(level.crate_pos, origin, step, Color("#c88a4a"), "BOX", true)
	if level.carrying_role.is_empty() and not level.rescued:
		_draw_marker(level.civilian_pos, origin, step, Color("#e3d9a0"), "C", false)
	for role in [level.FIREFIGHTER, level.ENGINEER]:
		var color := Color("#ed704b") if role == level.FIREFIGHTER else Color("#62abe9")
		var symbol := "F" if role == level.FIREFIGHTER else "E"
		var marker_pos: Vector2 = animated_position if animated_role == role else Vector2(level.positions[role])
		_draw_marker(marker_pos, origin, step, color, symbol, false)
		if level.selected == role:
			var center: Vector2 = origin + (marker_pos + Vector2(0.5, 0.5)) * step
			draw_arc(center, step * 0.43, 0.0, TAU, 32, Color.WHITE, 3.0)
		if level.carrying_role == role:
			var carrier_center: Vector2 = origin + (marker_pos + Vector2(0.5, 0.5)) * step
			draw_circle(carrier_center + Vector2(step * 0.23, -step * 0.23), step * 0.13, Color("#e3d9a0"))

func _draw_marker(cell: Vector2, origin: Vector2, step: float, color: Color, symbol: String, is_box: bool) -> void:
	var center := origin + (Vector2(cell) + Vector2(0.5, 0.5)) * step
	if is_box:
		draw_rect(Rect2(center - Vector2.ONE * step * 0.32, Vector2.ONE * step * 0.64), color, true)
	else:
		draw_circle(center, step * 0.33, color)
	if is_box:
		draw_rect(Rect2(center - Vector2.ONE * step * 0.25, Vector2.ONE * step * 0.50), Color("#e9b36c"), false, 2.5)
		draw_line(center + Vector2(-step * 0.23, -step * 0.23), center + Vector2(step * 0.23, step * 0.23), Color("#71442d"), 3.0)
	elif symbol == "!":
		var flame := PackedVector2Array([
			center + Vector2(-step * 0.22, step * 0.28),
			center + Vector2(-step * 0.19, -step * 0.06),
			center + Vector2(-step * 0.02, -step * 0.37),
			center + Vector2(step * 0.11, -step * 0.06),
			center + Vector2(step * 0.22, -step * 0.23),
			center + Vector2(step * 0.27, step * 0.20),
			center + Vector2(step * 0.06, step * 0.35)
		])
		draw_colored_polygon(flame, Color("#ffe39c"))
	elif symbol == "C":
		draw_circle(center + Vector2(0, -step * 0.12), step * 0.12, Color("#43372c"))
		draw_rect(Rect2(center + Vector2(-step * 0.15, 0), Vector2(step * 0.30, step * 0.20)), Color("#755a2b"))
	else:
		# Original simple responder helmet silhouettes, no third-party sprite assets.
		draw_arc(center + Vector2(0, -step * 0.05), step * 0.22, PI, TAU, 18, Color("#ffffff", 0.85), 3.0)
		draw_line(center + Vector2(-step * 0.26, -step * 0.08), center + Vector2(step * 0.26, -step * 0.08), Color("#f1f6ff"), 3.0)
		_draw_icon(center + Vector2(0, step * 0.09), symbol, step * 0.36)

func _draw_gate(center: Vector2, step: float, is_open: bool) -> void:
	var color := Color("#b5e9c5") if is_open else Color("#ffb0a2")
	draw_rect(Rect2(center - Vector2(step * 0.32, step * 0.34), Vector2(step * 0.64, step * 0.68)), color, false, 3.0)
	if is_open:
		draw_line(center + Vector2(-step * 0.10, 0), center + Vector2(step * 0.02, step * 0.12), color, 4.0)
		draw_line(center + Vector2(step * 0.02, step * 0.12), center + Vector2(step * 0.25, -step * 0.14), color, 4.0)
	else:
		for x in [-0.16, 0.0, 0.16]:
			draw_line(center + Vector2(step * x, -step * 0.28), center + Vector2(step * x, step * 0.28), color, 3.0)

func _draw_exit(center: Vector2, step: float) -> void:
	draw_circle(center, step * 0.30, Color("#3a9c76"))
	var arrow := PackedVector2Array([
		center + Vector2(-step * 0.16, -step * 0.18),
		center + Vector2(step * 0.16, 0),
		center + Vector2(-step * 0.16, step * 0.18)
	])
	draw_colored_polygon(arrow, Color("#ecfff2"))

func _draw_icon(center: Vector2, symbol: String, font_size: float) -> void:
	draw_string(ThemeDB.fallback_font, center + Vector2(0.0, font_size * 0.36), symbol, HORIZONTAL_ALIGNMENT_CENTER, -1.0, int(font_size), TEXT)

func animate_step(role: String, start: Vector2i, target: Vector2i) -> void:
	animated_role = role
	animated_position = Vector2(start)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_animated_position, Vector2(start), Vector2(target), 0.17)
	await tween.finished
	clear_animation()

func _set_animated_position(value: Vector2) -> void:
	animated_position = value
	queue_redraw()

func clear_animation() -> void:
	animated_role = ""
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	# Godot emulates mouse clicks for mobile touch; handle one event type to avoid duplicates.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var metrics: Dictionary = _metrics()
		if metrics.is_empty():
			return
		var step: float = metrics["cell_size"]
		var local: Vector2 = event.position - metrics["origin"]
		var cell := Vector2i(floori(local.x / step), floori(local.y / step))
		if cell.x >= 0 and cell.y >= 0 and cell.x < level.width and cell.y < level.height:
			cell_tapped.emit(cell)
			accept_event()
