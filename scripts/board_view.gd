extends Control
## Lightweight tile renderer without artwork or plugins; replace with original art later.
signal cell_tapped(cell: Vector2i)
var level: RefCounted
var route_preview: Array[Vector2i] = []
var animated_role: String = ""
var animated_position: Vector2 = Vector2.ZERO

const FLOOR = Color("#24374a")
const WALL = Color("#101927")
const GRID = Color("#172434")
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
			draw_rect(rect, GRID, false, 1.5)
			var center := rect.get_center()
			if tile == "switch":
				draw_arc(center, step * 0.28, 0.0, TAU, 28, Color("#8dd4ff"), 3.0)
			elif tile == "gate":
				_draw_icon(center, "LOCK", step * 0.24)
			elif tile == "open_gate":
				_draw_icon(center, "OPEN", step * 0.24)
			elif tile == "exit":
				_draw_icon(center, "EXIT", step * 0.23)

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
	_draw_icon(center, symbol, step * (0.22 if symbol.length() > 1 else 0.38))

func _draw_icon(center: Vector2, symbol: String, font_size: float) -> void:
	draw_string(ThemeDB.fallback_font, center + Vector2(0.0, font_size * 0.36), symbol, HORIZONTAL_ALIGNMENT_CENTER, -1.0, int(font_size), TEXT)

func animate_step(role: String, start: Vector2i, target: Vector2i) -> void:
	animated_role = role
	animated_position = Vector2(start)
	var tween := create_tween()
	tween.tween_method(_set_animated_position, Vector2(start), Vector2(target), 0.16)
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
