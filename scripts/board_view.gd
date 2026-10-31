extends Control
## Illustrated, adaptive view of the same grid. Rotation changes presentation only.
signal cell_tapped(cell: Vector2i)
const UI = preload("res://scripts/coastal_style.gd")
var level: RefCounted
var hint_target := Vector2i(-1, -1)
var route_preview: Array[Vector2i] = []
var animated_role: String = ""
var animated_position: Vector2 = Vector2.ZERO
var art: Dictionary = {}
var action_cell := Vector2i(-1, -1)
var action_progress: float = 0
var action_role := ""
var walk_progress: float = 0.0
var facing: Dictionary = {}
var effect_kind: String = ""
var effect_progress: float = 0.0
var effect_role: String = ""
var effect_from: Vector2i = Vector2i(-1, -1)
var effect_to: Vector2i = Vector2i(-1, -1)
## Diagnostic counters used in the existing animated UI regression suite.
var animation_counts: Dictionary = {"walk": 0, "spray": 0, "push": 0, "pickup": 0, "celebrate": 0, "stun": 0, "valve": 0}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	for role in ["firefighter", "engineer", "ranger", "civilian", "infected"]:
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
	var backdrop: Texture2D = UI.OLD_TOWN if level.location_id == "old-town" else UI.BACKDROP
	var picture_size := backdrop.get_size()
	var cover_scale := maxf(size.x / picture_size.x, size.y / picture_size.y)
	var source_size := size / cover_scale
	draw_texture_rect_region(backdrop, Rect2(Vector2(2, 2), size - Vector2(4, 4)), Rect2((picture_size - source_size) / 2, source_size))
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
				_draw_flood_tile(tile, rect, center, step)
				if tile in ["switch", "gate", "open_gate", "exit"]:
					_draw_art(tile, center, step * 1.02)
					if tile == "exit":
						_draw_word(center + Vector2(0, step * 0.26), "EXIT", int(step * 0.18), Color.WHITE)
	if hint_target.x >= 0:
		var target: Vector2 = cell_center(Vector2(hint_target), metrics)
		draw_rect(Rect2(target - Vector2.ONE * step * 0.46, Vector2.ONE * step * 0.92), Color("#ffb522"), false, 4)
		_draw_word(target - Vector2(0, step * 0.18), "?", int(step * 0.4), Color("#fff5b5"))
	# Route follows the exact planned model cells, including on rotated boards.
	for cell in route_preview:
		draw_circle(cell_center(Vector2(cell), metrics), step * 0.075, Color("#2bb9bd"), true, -1, true)
	if level.has_fire and not level.fire_cleared:
		_draw_art("fire", cell_center(Vector2(level.fire_pos), metrics), step * 1.08)
	if level.has_crate:
		var crate_center: Vector2 = cell_center(Vector2(level.crate_pos), metrics)
		if effect_kind == "push":
			crate_center = cell_center(Vector2(effect_from).lerp(Vector2(effect_to), effect_progress), metrics)
			crate_center.y -= sin(effect_progress * PI) * step * 0.11
		_draw_art("crate", crate_center, step * 0.98)
	for cell in level.infected:
		_draw_person("infected", cell_center(Vector2(cell), metrics), step)
	if level.carrying_role.is_empty() and not level.rescued:
		_draw_person("civilian", cell_center(Vector2(level.civilian_pos), metrics), step)
	for role in level.positions:
		var position_on_grid: Vector2 = animated_position if animated_role == role else Vector2(level.positions[role])
		var center := cell_center(position_on_grid, metrics)
		if animated_role == role and effect_kind == "":
			center.y -= sin(walk_progress * PI * 2.0) * step * 0.065
		if level.selected == role:
			var ring := Color("#ffcd5c")
			draw_circle(center + Vector2(0, step * 0.23), step * 0.38, Color(ring, 0.3), true, -1, true)
			draw_arc(center + Vector2(0, step * 0.23), step * 0.38, 0, TAU, 32, ring, 3, true)
		_draw_facing_person(role, center, step)
		if level.carrying_role == role and effect_kind != "pickup":
			_draw_person("civilian", center + Vector2(step * 0.27, step * 0.1), step * 0.55)
	_draw_effects(metrics, step)

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


func _draw_facing_person(role: String, center: Vector2, step: float) -> void:
	var lean := 0.0
	if effect_kind == "push" and role == effect_role:
		lean = float(facing.get(role, 1)) * 0.09 * sin(effect_progress * PI)
	draw_set_transform(center, lean, Vector2(float(facing.get(role, 1)), 1.0))
	_draw_person(role, Vector2.ZERO, step)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_effects(metrics: Dictionary, step: float) -> void:
	if effect_kind.is_empty():
		return
	var center: Vector2 = cell_center(Vector2(effect_to), metrics)
	var fade: float = 1.0 - effect_progress
	match effect_kind:
		"spray":
			var source: Vector2 = cell_center(Vector2(level.positions[effect_role]), metrics)
			for i in range(5):
				var t: float = clampf(effect_progress * 1.45 - float(i) * 0.085, 0.0, 1.0)
				var p: Vector2 = source.lerp(center, t)
				var offset := Vector2(0, sin(t * PI * 2.0 + float(i) * 1.2) * step * 0.13)
				draw_circle(p + offset, step * (0.075 - float(i) * 0.007), Color("#6fdef7", fade * 0.9))
			for i in range(3):
				var steam: Vector2 = center + Vector2((i - 1) * step * 0.17, -effect_progress * step * 0.5)
				draw_arc(steam, step * 0.15, PI, TAU, 10, Color(0.93, 0.97, 1, fade), 2.4, true)
		"push":
			for i in range(3):
				var dust: Vector2 = center + Vector2((i - 1) * step * 0.17, step * 0.30)
				draw_circle(dust, step * 0.07 * (1.0 + effect_progress), Color("#e9d4aa", fade * 0.8))
		"pickup":
			var lift: Vector2 = center + Vector2(0, -sin(effect_progress * PI / 2.0) * step * 0.4)
			draw_set_transform(lift, 0.0, Vector2.ONE * (1.0 - effect_progress * 0.32))
			_draw_person("civilian", Vector2.ZERO, step)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"valve":
			draw_arc(center, step * (0.15 + effect_progress * 0.4), 0, TAU, 24, Color("#71dbe9", fade), 4, true)
		"stun":
			draw_arc(center, step * (0.2 + effect_progress * 0.38), 0, TAU, 28, Color(UI.VIOLET, fade), 4, true)
			for i in range(4):
				var angle: float = TAU * float(i) / 4.0 + effect_progress * 2.0
				draw_line(center + Vector2.RIGHT.rotated(angle) * step * 0.20, center + Vector2.RIGHT.rotated(angle) * step * 0.44, Color(UI.VIOLET, fade), 3, true)
		"celebrate":
			var source: Vector2 = cell_center(Vector2(level.positions[effect_role]), metrics)
			for i in range(12):
				var angle: float = TAU * float(i) / 12.0
				var distance: float = step * (0.12 + effect_progress * 1.0)
				var particle: Vector2 = source + Vector2.RIGHT.rotated(angle) * distance
				var hue: Color = Color("#f7ce5b") if i % 2 == 0 else Color("#56ca9c")
				draw_circle(particle, step * 0.08 * fade, Color(hue, fade))
			draw_arc(source, step * (0.35 + effect_progress * 0.2), 0, TAU, 32, Color("#f8dc87", fade), 3, true)

func animate_step(role: String, start: Vector2i, target: Vector2i) -> void:
	animation_counts["walk"] += 1
	facing[role] = -1 if target.x < start.x else (1 if target.x > start.x else int(facing.get(role, 1)))
	animated_role = role
	animated_position = Vector2(start)
	walk_progress = 0.0
	var tween := create_tween()
	tween.tween_method(_set_walk_progress.bind(start, target), 0.0, 1.0, 0.17).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	clear_animation()

func _set_walk_progress(value: float, start: Vector2i, target: Vector2i) -> void:
	walk_progress = value
	animated_position = Vector2(start).lerp(Vector2(target), value)
	queue_redraw()

func clear_animation() -> void:
	animated_role = ""
	action_cell = Vector2i(-1, -1)
	effect_kind = ""
	effect_progress = 0.0
	walk_progress = 0.0
	queue_redraw()

func animate_action(cell: Vector2i, role: String) -> void:
	await animate_stun(role, cell)

func animate_spray(role: String, target: Vector2i) -> void:
	await _animate_effect("spray", role, target, target, 0.30)

func animate_push(role: String, actor_from: Vector2i, crate_from: Vector2i, crate_to: Vector2i) -> void:
	facing[role] = -1 if crate_from.x < actor_from.x else (1 if crate_from.x > actor_from.x else int(facing.get(role, 1)))
	animated_role = role
	animated_position = Vector2(actor_from)
	await _animate_effect("push", role, crate_from, crate_to, 0.24)

func animate_pickup(role: String, actor_from: Vector2i, civilian_at: Vector2i) -> void:
	animated_role = role
	animated_position = Vector2(actor_from)
	await _animate_effect("pickup", role, actor_from, civilian_at, 0.28)

func animate_stun(role: String, target: Vector2i) -> void:
	await _animate_effect("stun", role, target, target, 0.24)

func animate_victory(role: String) -> void:
	if not level.rescued:
		return
	await _animate_effect("celebrate", role, level.exit_pos, level.exit_pos, 0.65)

func _animate_effect(kind: String, role: String, from: Vector2i, to: Vector2i, duration: float) -> void:
	animation_counts[kind] += 1
	effect_kind = kind
	effect_role = role
	effect_from = from
	effect_to = to
	effect_progress = 0.0
	var tween := create_tween()
	tween.tween_method(_set_effect_progress, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	clear_animation()

func _set_effect_progress(value: float) -> void:
	effect_progress = value
	if effect_kind == "push":
		animated_position = Vector2(effect_from).lerp(Vector2(level.positions[effect_role]), value)
	elif effect_kind == "pickup":
		animated_position = Vector2(effect_from).lerp(Vector2(effect_to), value)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	# Use emulated mouse only, so one touch cannot trigger two puzzle actions.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := cell_at_position(event.position)
		if cell != Vector2i(-1, -1):
			cell_tapped.emit(cell)
			accept_event()

func _draw_flood_tile(tile: String, rect: Rect2, center: Vector2, step: float) -> void:
	if tile == "water":
		draw_rect(rect.grow(-1), Color("#3b9bbb"))
		for i in range(3):
			draw_arc(center + Vector2((i - 1) * step * 0.22, step * 0.05), step * 0.18, 0.1, 2.8, 12, Color("#a4e9ee"), 2, true)
	elif tile in ["valve", "valve_open"]:
		draw_circle(center, step * 0.34, Color("#456875"))
		draw_arc(center, step * 0.27, 0, TAU, 24, Color("#79dbb0") if tile == "valve_open" else Color("#f4ae51"), 4, true)
		for direction in [Vector2.RIGHT, Vector2.DOWN]:
			draw_line(center - direction * step * 0.25, center + direction * step * 0.25, Color("#eaf3e7"), 3, true)
	elif tile in ["bridge", "broken_bridge"]:
		draw_rect(rect.grow(-1), Color("#39819c"))
		for i in range(4):
			if tile == "broken_bridge" and i in [1, 2]:
				continue
			draw_rect(Rect2(rect.position + Vector2(step * 0.1, step * (0.12 + i * 0.2)), Vector2(step * 0.8, step * 0.16)), Color("#bf8d50"))
		if tile == "broken_bridge":
			_draw_word(center + Vector2(0, step * 0.18), "!", int(step * 0.45), Color("#fff0c1"))

func animate_valve(role: String, target: Vector2i) -> void:
	await _animate_effect("valve", role, target, target, 0.3)
