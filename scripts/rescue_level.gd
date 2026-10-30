extends RefCounted
## Deterministic one-level rescue puzzle. No Node, physics or rendering dependencies.
## F = firefighter, E = engineer, f = fire, B = crate, s = switch,
## G = locked gate, C = civilian, X = extraction, # = wall.
const ROWS = [
	"###########",
	"#F.f.C.GX##",
	"#.#.###.###",
	"#E.Bs.....#",
	"###########",
]
const FIREFIGHTER = "firefighter"
const ENGINEER = "engineer"

var width: int = 0
var height: int = 0
var walls: Dictionary = {}
var positions: Dictionary = {}
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
var history: Array[Dictionary] = []

func _init() -> void:
	reset()

func reset() -> void:
	walls.clear()
	positions.clear()
	height = ROWS.size()
	width = ROWS[0].length()
	for y in range(height):
		assert(ROWS[y].length() == width, "Every row must have the same width")
		for x in range(width):
			var cell := Vector2i(x, y)
			match ROWS[y].substr(x, 1):
				"#": walls[cell] = true
				"F": positions[FIREFIGHTER] = cell
				"E": positions[ENGINEER] = cell
				"f": fire_pos = cell
				"B": crate_pos = cell
				"s": switch_pos = cell
				"G": gate_pos = cell
				"C": civilian_pos = cell
				"X": exit_pos = cell
	fire_cleared = false
	carrying_role = ""
	rescued = false
	selected = FIREFIGHTER
	actions = 0
	message = "Clear fire, power the gate, then carry the civilian to EXIT."
	history.clear()

func gate_is_open() -> bool:
	return crate_pos == switch_pos

func select_role(role: String) -> bool:
	if rescued or not positions.has(role):
		return false
	selected = role
	message = "Firefighter clears fire." if role == FIREFIGHTER else "Engineer pushes crates."
	return true


## Choose the shortest safe route through walkable cells. Hazard tiles are
## interactive destinations: move beside them, then use the existing act() rule.
## Obstacles are never bypassed and no switches/fire are solved automatically.
func plan_route(target: Vector2i) -> Array[Vector2i]:
	if rescued:
		_reject("Rescue completed. Tap RESTART to play again.")
		return []
	if not _inside(target) or walls.has(target):
		_reject("A wall blocks that destination.")
		return []
	var start: Vector2i = positions[selected]
	if target == start:
		_reject("Already standing on that tile.")
		return []
	# Keep the current adjacent interaction semantics and their feedback.
	if absi(target.x - start.x) + absi(target.y - start.y) == 1:
		return [target]
	if target == fire_pos and not fire_cleared:
		if selected != FIREFIGHTER:
			_reject("Only the firefighter can extinguish flames.")
			return []
		return _route_to_interaction(target, false)
	if target == crate_pos:
		if selected != ENGINEER:
			_reject("Only the engineer can move the crate.")
			return []
		return _route_to_interaction(target, true)
	if not _can_enter(target):
		if target == gate_pos and not gate_is_open():
			_reject("The gate needs the crate on the blue switch.")
		else:
			_reject("That destination is blocked.")
		return []
	var route := _shortest_path(start, target)
	if route.is_empty():
		_reject("No safe route. Clear hazards or move another rescuer.")
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
			if beyond == exit_pos or (beyond == civilian_pos and carrying_role.is_empty()) or not _can_enter(beyond):
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
		_reject("No safe approach. Move obstacles or choose another target.")
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
	if rescued:
		return _reject("Rescue completed. Tap RESTART to play again.")
	var current: Vector2i = positions[selected]
	var direction := target - current
	if absi(direction.x) + absi(direction.y) != 1:
		return _reject("Tap an adjacent tile. Select a rescuer to switch.")
	if walls.has(target) or not _inside(target):
		return _reject("A wall blocks that route.")

	if target == fire_pos and not fire_cleared:
		if selected != FIREFIGHTER:
			return _reject("Only the firefighter can extinguish flames.")
		_record()
		fire_cleared = true
		message = "Fire cleared. Walk through the corridor!"
		return true

	if target == crate_pos:
		if selected != ENGINEER:
			return _reject("Only the engineer can move the crate.")
		var destination := target + direction
		if destination == exit_pos or not _can_enter(destination):
			return _reject("The crate cannot be pushed in that direction.")
		_record()
		crate_pos = destination
		positions[selected] = target
		actions += 1
		message = "Gate powered!" if gate_is_open() else "Crate moved."
		return true

	if not _can_enter(target):
		if target == gate_pos and not gate_is_open():
			return _reject("The gate needs the crate on the blue switch.")
		return _reject("That tile is blocked.")

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
	positions = previous["positions"].duplicate()
	crate_pos = previous["crate_pos"]
	fire_cleared = previous["fire_cleared"]
	carrying_role = previous["carrying_role"]
	rescued = previous["rescued"]
	selected = previous["selected"]
	actions = previous["actions"]
	message = "Last action undone."
	return true

func tile_at(cell: Vector2i) -> String:
	if walls.has(cell):
		return "wall"
	if cell == gate_pos:
		return "open_gate" if gate_is_open() else "gate"
	if cell == switch_pos:
		return "switch"
	if cell == exit_pos:
		return "exit"
	return "floor"

func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func _can_enter(cell: Vector2i) -> bool:
	if not _inside(cell) or walls.has(cell):
		return false
	if cell == crate_pos or (cell == fire_pos and not fire_cleared):
		return false
	if cell == gate_pos and not gate_is_open():
		return false
	if cell == civilian_pos and carrying_role.is_empty():
		return true
	for role in positions:
		if positions[role] == cell:
			return false
	return true

func _record() -> void:
	history.append({
		"positions": positions.duplicate(),
		"crate_pos": crate_pos,
		"fire_cleared": fire_cleared,
		"carrying_role": carrying_role,
		"rescued": rescued,
		"selected": selected,
		"actions": actions,
	})

func _reject(reason: String) -> bool:
	message = reason
	return false
