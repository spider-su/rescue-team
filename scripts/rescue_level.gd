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
