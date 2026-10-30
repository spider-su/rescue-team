extends Control
## Illustrated, adaptive view of the same grid. Rotation changes presentation only.
signal cell_tapped(cell: Vector2i)
const UI = preload("res://scripts/coastal_style.gd")
var level: RefCounted
var route_preview: Array[Vector2i] = []
var animated_role: String = ""
var animated_position: Vector2 = Vector2.ZERO
var art: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	for role in ["firefighter", "engineer", "civilian"]:
		art[role] = UI.sprite(role)
	for prop in ["fire", "crate", "switch", "gate", "open_gate", "exit"]:
		art[prop] = UI.prop(prop)

func _metrics() -> Dictionary:
	if level == null or size.x <= 0 or size.y <= 0:
		return {}
	# Tall screens can fit a wide mission vertically with larger touch targets.
	var rotated: bool = level.width > level.height and size.y > size.x * 0.82
	var columns: int = level.height if rotated else level.width
	var rows: int = level.width if rotated else level.height
	var cell_size := floorf(minf((size.x - 28) / columns, (size.y - 28) / rows))
	if cell_size < 12:
		return {}
	var origin := (size - Vector2(columns, rows) * cell_size) / 2
	return {"cell_size": cell_size, "origin": origin, "rotated": rotated, "columns": columns, "rows": rows}

func _display_cell(cell: Vector2, metrics: Dictionary) -> Vector2:
	return Vector2(level.height - 1 - cell.y, cell.x) if metrics["rotated"] else cell

func cell_center(cell: Vector2, metrics: Dictionary = {}) -> Vector2:
	if metrics.is_empty():
		metrics = _metrics()
	return metrics["origin"] + (_display_cell(cell, metrics) + Vector2(0.5, 0.5)) * metrics["cell_size"]

func cell_at_position(local_position: Vector2) -> Vector2i:
	var metrics := _metrics()
	if metrics.is_empty():
		return Vector2i(-1, -1)
	var local: Vector2 = (local_position - metrics["origin"]) / metrics["cell_size"]
	var display := Vector2i(floori(local.x), floori(local.y))
	if display.x < 0 or display.y < 0 or display.x >= metrics["columns"] or display.y >= metrics["rows"]:
		return Vector2i(-1, -1)
	return Vector2i(display.y, level.height - 1 - display.x) if metrics["rotated"] else display

func _draw() -> void:
	var metrics := _metrics()
	if metrics.is_empty():
		return
	var step: float = metrics["cell_size"]
	var origin: Vector2 = metrics["origin"]
	# Calm water frames the workshop, keeping decorative detail off walkable tiles.
	draw_style_box(UI.box(Color("#438d98"), Color("#357684"), 18, 0), Rect2(Vector2.ZERO, size))
	var picture_size := UI.BACKDROP.get_size()
	var cover_scale := maxf(size.x / picture_size.x, size.y / picture_size.y)
	var source_size := size / cover_scale
	draw_texture_rect_region(UI.BACKDROP, Rect2(Vector2(2, 2), size - Vector2(4, 4)), Rect2((picture_size - source_size) / 2, source_size))
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0.13, 0.36, 0.4, 0.18))
	var board_size := Vector2(metrics["columns"], metrics["rows"]) * step
	draw_style_box(UI.box(Color("#b29b78"), Color("#847456"), 8, 0), Rect2(origin - Vector2(6, 4), board_size + Vector2(12, 14)))
	for y in range(level.height):
		for x in range(level.width):
			var cell := Vector2i(x, y)
			var center := cell_center(Vector2(cell), metrics)
			var rect := Rect2(center - Vector2.ONE * step / 2, Vector2.ONE * step)
			var tile: String = level.tile_at(cell)
			if tile == "wall":
				_draw_wall(rect, x + y)
			else:
				_draw_floor(rect, x + y)
				if tile in ["switch", "gate", "open_gate", "exit"]:
					_draw_art(tile, center, step * 1.02)
					if tile == "exit":
						_draw_word(center + Vector2(0, step * 0.26), "EXIT", int(step * 0.18), Color.WHITE)
	# Route follows the exact planned model cells, including on rotated boards.
	for cell in route_preview:
		draw_circle(cell_center(Vector2(cell), metrics), step * 0.075, Color("#2bb9bd"), true, -1, true)
	if level.has_fire and not level.fire_cleared:
		_draw_art("fire", cell_center(Vector2(level.fire_pos), metrics), step * 1.08)
	if level.has_crate:
		_draw_art("crate", cell_center(Vector2(level.crate_pos), metrics), step * 0.98)
	if level.carrying_role.is_empty() and not level.rescued:
		_draw_person("civilian", cell_center(Vector2(level.civilian_pos), metrics), step)
	for role in [level.FIREFIGHTER, level.ENGINEER]:
		var position_on_grid: Vector2 = animated_position if animated_role == role else Vector2(level.positions[role])
		var center := cell_center(position_on_grid, metrics)
		if level.selected == role:
			var ring := Color("#ffcd5c")
			draw_circle(center + Vector2(0, step * 0.23), step * 0.38, Color(ring, 0.3), true, -1, true)
			draw_arc(center + Vector2(0, step * 0.23), step * 0.38, 0, TAU, 32, ring, 3, true)
		_draw_person(role, center, step)
		if level.carrying_role == role:
			_draw_person("civilian", center + Vector2(step * 0.27, step * 0.1), step * 0.55)

func _draw_floor(rect: Rect2, variation: int) -> void:
	var floor_color := Color("#ecdec4") if variation % 2 == 0 else Color("#e4d3b5")
	draw_rect(rect, Color("#b2a185"))
	draw_rect(rect.grow(-1), floor_color)
	draw_line(rect.position + Vector2(2, 2), rect.position + Vector2(rect.size.x - 2, 2), Color("#fff1d9"), 2)
	if variation % 4 == 0:
		draw_line(rect.position + rect.size * Vector2(0.1, 0.75), rect.position + rect.size * Vector2(0.22, 0.7), Color("#cdbc9f"), 1)

func _draw_wall(rect: Rect2, variation: int) -> void:
	draw_rect(rect, Color("#897b64"))
	var top := rect.grow(-1)
	top.size.y -= maxf(3, rect.size.y * 0.12)
	draw_style_box(UI.box(Color("#c9b895") if variation % 2 == 0 else Color("#d5c4a3"), Color("#a18e6f"), 4, 0), top)
	draw_line(top.position + Vector2(3, 3), top.position + Vector2(top.size.x - 3, 3), Color("#efdfbf"), 3)
	var seam: float = top.position.y + top.size.y * 0.5
	draw_line(Vector2(top.position.x + 2, seam), Vector2(top.end.x - 2, seam), Color("#a99676"), 1)

func _draw_art(kind: String, center: Vector2, side: float) -> void:
	if art.has(kind):
		draw_texture_rect(art[kind], Rect2(center - Vector2.ONE * side / 2, Vector2.ONE * side), false)

func _draw_person(role: String, center: Vector2, step: float) -> void:
	if not art.has(role):
		return
	draw_circle(center + Vector2(0, step * 0.28), step * 0.22, Color(0.15, 0.2, 0.18, 0.18), true, -1, true)
	var dimensions := Vector2(step * 0.73, step * 1.02)
	draw_texture_rect(art[role], Rect2(center - dimensions / 2, dimensions), false)

func _draw_word(center: Vector2, text: String, font_size: int, color: Color) -> void:
	var width := UI.HEADING.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(UI.HEADING, center - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

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
	# Use emulated mouse only, so one touch cannot trigger two puzzle actions.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := cell_at_position(event.position)
		if cell != Vector2i(-1, -1):
			cell_tapped.emit(cell)
			accept_event()
