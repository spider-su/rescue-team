extends RefCounted
## Deterministic puzzle rules: map content comes from validated JSON, not GDScript.
const LevelCatalog = preload("res://scripts/level_catalog.gd")
const FIREFIGHTER = "firefighter"
const ENGINEER = "engineer"
const RANGER = "ranger"

var width: int = 0
var height: int = 0
var walls: Dictionary = {}
var positions: Dictionary = {}
var infected: Dictionary = {}
var fire_pos: Vector2i = Vector2i(-1, -1)
var crate_pos: Vector2i = Vector2i(-1, -1)
var switch_pos: Vector2i = Vector2i(-1, -1)
var gate_pos: Vector2i = Vector2i(-1, -1)
var civilian_pos: Vector2i = Vector2i(-1, -1)
var exit_pos: Vector2i = Vector2i(-1, -1)
var fire_cleared: bool = false
var carrying_role: String = ""
var rescued: bool = false
var selected: String = FIREFIGHTER
var actions: int = 0
var message: String = ""
var blocked_reason: String = ""
var history: Array[Dictionary] = []
var level_id: String = ""
var location_id: String = "coast"
var title: String = ""
var hint: String = ""
var water: Dictionary = {}
var valve_pos := Vector2i(-1, -1)
var bridge_pos := Vector2i(-1, -1)
var water_drained := false
var bridge_built := false
var has_fire: bool = false
var has_crate: bool = false
var has_gate: bool = false
var _definition: Dictionary = {}

func _init(definition: Dictionary = {}) -> void:
	if definition.is_empty():
		definition = LevelCatalog.new().load_level(0)
	assert(LevelCatalog.new().validate(definition).is_empty(), "Invalid mission data")
	_definition = definition.duplicate(true)
	level_id = definition["id"]
	location_id = definition.get("location", "coast")
	title = definition["title"]
	hint = definition["hint"]
	reset()

func reset() -> void:
	blocked_reason = ""
	water.clear()
	valve_pos = Vector2i(-1, -1)
	bridge_pos = Vector2i(-1, -1)
	water_drained = false
	bridge_built = false
	walls.clear()
	positions.clear()
	infected.clear()
	fire_pos = Vector2i(-1, -1)
	crate_pos = Vector2i(-1, -1)
	switch_pos = Vector2i(-1, -1)
	gate_pos = Vector2i(-1, -1)
	civilian_pos = Vector2i(-1, -1)
	exit_pos = Vector2i(-1, -1)
	var rows: Array = _definition["rows"]
	height = rows.size()
	width = rows[0].length()
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			match rows[y].substr(x, 1):
				"V": valve_pos = cell
				"~": water[cell] = true
				"=": bridge_pos = cell
				"#": walls[cell] = true
				"F": positions[FIREFIGHTER] = cell
				"E": positions[ENGINEER] = cell
				"R": positions[RANGER] = cell
				"Z": infected[cell] = true
				"f": fire_pos = cell
				"B": crate_pos = cell
				"s": switch_pos = cell
				"G": gate_pos = cell
				"C": civilian_pos = cell
				"X": exit_pos = cell
	has_fire = fire_pos.x >= 0
	has_crate = crate_pos.x >= 0
	has_gate = gate_pos.x >= 0
	fire_cleared = not has_fire
	carrying_role = ""
	rescued = false
	selected = FIREFIGHTER
	actions = 0
	message = hint
	history.clear()

func gate_is_open() -> bool:
	return not has_gate or crate_pos == switch_pos

func select_role(role: String) -> bool:
	if rescued or not positions.has(role):
		return false
	selected = role
	message = {FIREFIGHTER: "Firefighter clears fire.", ENGINEER: ("Engineer turns valves and repairs bridges." if valve_pos.x >= 0 else "Engineer pushes crates."), RANGER: "Ranger stuns adjacent infected. Tap one to approach safely."}[role]
	return true


## Choose the shortest safe route through walkable cells. Hazard tiles are
## interactive destinations: move beside them, then use the existing act() rule.
## Obstacles are never bypassed and no switches/fire are solved automatically.
func plan_route(target: Vector2i) -> Array[Vector2i]:
	blocked_reason = ""
	if rescued:
		_reject("Rescue completed. Tap RESTART to play again.")
		return []
	if not _inside(target) or walls.has(target):
		_reject("A wall blocks that destination.", "wall")
		return []
	var start: Vector2i = positions[selected]
	if target == start:
		_reject("Already standing on that tile.")
		return []
	# Keep the current adjacent interaction semantics and their feedback.
	if absi(target.x - start.x) + absi(target.y - start.y) == 1:
		return [target]
	if target == valve_pos or (target == bridge_pos and not bridge_built):
		if selected != ENGINEER:
			_reject("The engineer operates valves and repairs bridges.", "valve" if target == valve_pos else "bridge")
			return []
		return _route_to_interaction(target, false)
	if infected.has(target):
		if selected != RANGER:
			_reject("Only the ranger can clear infected. Select the violet portrait.", "infected")
			return []
		return _route_to_interaction(target, false)
	if has_fire and target == fire_pos and not fire_cleared:
		if selected != FIREFIGHTER:
			_reject("Only the firefighter can extinguish flames.", "fire")
			return []
		return _route_to_interaction(target, false)
	if has_crate and target == crate_pos:
		if selected != ENGINEER:
			_reject("Only the engineer can move the crate.", "crate")
			return []
		return _route_to_interaction(target, true)
	if not _can_enter(target):
		if target == gate_pos and not gate_is_open():
			_reject("The gate needs the crate on the blue switch.", "gate")
		elif water.has(target) and not water_drained:
			_reject("Floodwater blocks that tile. Turn the valve first.", "water")
		else:
			_reject("That destination is blocked.", "rescuer")
		return []
	var route := _shortest_path(start, target)
	if route.is_empty():
		_reject("No safe route. Clear hazards or move another rescuer.", _route_blocker(target))
	return route

func _route_to_interaction(target: Vector2i, pushing_crate: bool) -> Array[Vector2i]:
	var start: Vector2i = positions[selected]
	var best: Array[Vector2i] = []
	var best_cost: int = 999999
	for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var beside: Vector2i = target - direction
		if beside != start and not _can_enter(beside):
			continue
		if pushing_crate:
			var beyond: Vector2i = target + direction
			if not _can_push_into(beyond):
				continue
		var route := _shortest_path(start, beside)
		if beside != start and route.is_empty():
			continue
		# When pushing a crate, prefer placing it on the switch over an
		# otherwise equally short push in another direction.
		var cost: int = route.size() * 10
		if pushing_crate and target + direction == switch_pos:
			cost -= 5
		if cost < best_cost:
			best_cost = cost
			best = route.duplicate()
			best.append(target)
	if best.is_empty():
		_reject("No safe approach. Move obstacles or choose another target.", "push" if pushing_crate else _route_blocker(target))
	return best

func _shortest_path(start: Vector2i, target: Vector2i) -> Array[Vector2i]:
	if start == target:
		return []
	if not _can_enter(target):
		return []
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	var cursor: int = 0
	while cursor < queue.size():
		var current: Vector2i = queue[cursor]
		cursor += 1
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = current + direction
			if previous.has(neighbor) or not _can_enter(neighbor):
				continue
			previous[neighbor] = current
			if neighbor == target:
				var reversed_path: Array[Vector2i] = []
				var step: Vector2i = target
				while step != start:
					reversed_path.append(step)
					step = previous[step]
				reversed_path.reverse()
				return reversed_path
			queue.append(neighbor)
	return []

## A single destination tap is one undoable action even if it walked 6 cells.
func collapse_history(from_index: int) -> void:
	if from_index < 0 or from_index >= history.size():
		return
	var before: Dictionary = history[from_index]
	history.resize(from_index)
	history.append(before)

func act(target: Vector2i) -> bool:
	blocked_reason = ""
	if rescued:
		return _reject("Rescue completed. Tap RESTART to play again.")
	var current: Vector2i = positions[selected]
	var direction := target - current
	if absi(direction.x) + absi(direction.y) != 1:
		return _reject("Tap an adjacent tile. Select a rescuer to switch.")
	if walls.has(target) or not _inside(target):
		return _reject("A wall blocks that route.", "wall")
	if target == valve_pos:
		if selected != ENGINEER:
			return _reject("Only the engineer can operate this valve.", "valve")
		if water_drained:
			return _reject("The valve is already open.")
		_record()
		water_drained = true
		actions += 1
		message = "Water drained! Flooded tiles are now safe."
		return true
	if target == bridge_pos and not bridge_built:
		if selected != ENGINEER:
			return _reject("Only the engineer can repair the bridge.", "bridge")
		if not water_drained:
			return _reject("Drain the water before repairing this bridge.", "water")
		_record()
		bridge_built = true
		actions += 1
		message = "Bridge repaired! Everyone can cross."
		return true
	if infected.has(target):
		if selected != RANGER:
			return _reject("Only the ranger can clear infected. Select the violet portrait.", "infected")
		_record()
		infected.erase(target)
		actions += 1
		message = "Infected contained. The tile is now safe for everyone."
		return true

	if target == fire_pos and not fire_cleared:
		if selected != FIREFIGHTER:
			return _reject("Only the firefighter can extinguish flames.", "fire")
		_record()
		fire_cleared = true
		message = "Fire cleared. Walk through the corridor!"
		return true

	if target == crate_pos:
		if selected != ENGINEER:
			return _reject("Only the engineer can move the crate.", "crate")
		var destination := target + direction
		if not _can_push_into(destination):
			return _reject("The crate cannot be pushed in that direction.", "push")
		_record()
		crate_pos = destination
		positions[selected] = target
		actions += 1
		message = "Gate powered!" if gate_is_open() else "Crate moved."
		return true

	if not _can_enter(target):
		if target == gate_pos and not gate_is_open():
			return _reject("The gate needs the crate on the blue switch.", "gate")
		if water.has(target) and not water_drained:
			return _reject("Floodwater blocks that tile. Turn the valve first.", "water")
		return _reject("That tile is blocked.", "rescuer")

	_record()
	positions[selected] = target
	actions += 1
	if target == civilian_pos and carrying_role.is_empty():
		carrying_role = selected
		message = "Civilian safe with %s. Reach EXIT!" % selected
	elif target == exit_pos and carrying_role == selected:
		rescued = true
		message = "RESCUE COMPLETE! All personnel accounted for."
	else:
		message = "Gate unlocked. Reach EXIT!" if gate_is_open() else "Keep going."
	return true

func undo() -> bool:
	if history.is_empty():
		return _reject("Nothing to undo.")
	var previous: Dictionary = history.pop_back()
	water_drained = previous["water_drained"]
	bridge_built = previous["bridge_built"]
	positions = previous["positions"].duplicate()
	infected = previous["infected"].duplicate()
	crate_pos = previous["crate_pos"]
	fire_cleared = previous["fire_cleared"]
	carrying_role = previous["carrying_role"]
	rescued = previous["rescued"]
	selected = previous["selected"]
	actions = previous["actions"]
	message = "Last action undone."
	return true

func tile_at(cell: Vector2i) -> String:
	if cell == valve_pos:
		return "valve_open" if water_drained else "valve"
	if cell == bridge_pos:
		return "bridge" if bridge_built else "broken_bridge"
	if water.has(cell) and not water_drained:
		return "water"
	if walls.has(cell):
		return "wall"
	if cell == gate_pos:
		return "open_gate" if gate_is_open() else "gate"
	if has_crate and cell == switch_pos:
		return "switch"
	if cell == exit_pos:
		return "exit"
	return "floor"

func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func _can_enter(cell: Vector2i) -> bool:
	if not _inside(cell) or walls.has(cell):
		return false
	if cell == valve_pos or (cell == bridge_pos and not bridge_built) or (water.has(cell) and not water_drained):
		return false
	if infected.has(cell):
		return false
	if (has_crate and cell == crate_pos) or (has_fire and cell == fire_pos and not fire_cleared):
		return false
	if cell == gate_pos and not gate_is_open():
		return false
	if cell == civilian_pos and carrying_role.is_empty():
		return true
	for role in positions:
		if positions[role] == cell:
			return false
	return true

func _can_push_into(cell: Vector2i) -> bool:
	return cell != exit_pos and not (cell == civilian_pos and carrying_role.is_empty()) and _can_enter(cell)

func _record() -> void:
	history.append({
		"water_drained": water_drained, "bridge_built": bridge_built,
		"positions": positions.duplicate(),
		"infected": infected.duplicate(),
		"crate_pos": crate_pos,
		"fire_cleared": fire_cleared,
		"carrying_role": carrying_role,
		"rescued": rescued,
		"selected": selected,
		"actions": actions,
	})

func _reject(reason: String, obstacle: String = "") -> bool:
	blocked_reason = obstacle
	message = reason
	return false

## Explain an unreachable destination using the first blocker on a shortest
## wall-respecting corridor. This diagnostic never changes the playable route.
func _route_blocker(target: Vector2i) -> String:
	var start: Vector2i = positions[selected]
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	var cursor := 0
	while cursor < queue.size() and not previous.has(target):
		var current := queue[cursor]
		cursor += 1
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = current + direction
			if not _inside(neighbor) or walls.has(neighbor) or previous.has(neighbor):
				continue
			previous[neighbor] = current
			queue.append(neighbor)
	if not previous.has(target):
		return "route"
	var path: Array[Vector2i] = []
	var cell := target
	while cell != start:
		path.push_front(cell)
		cell = previous[cell]
	for step in path:
		if water.has(step) and not water_drained:
			return "water"
		if step == bridge_pos and not bridge_built:
			return "bridge"
		if step == valve_pos:
			return "valve"
		if has_fire and step == fire_pos and not fire_cleared:
			return "fire"
		if has_gate and step == gate_pos and not gate_is_open():
			return "gate"
		if infected.has(step):
			return "infected"
		if has_crate and step == crate_pos:
			return "crate"
		if not _can_enter(step):
			return "rescuer"
	return "route"
