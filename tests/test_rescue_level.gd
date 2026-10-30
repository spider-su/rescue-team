extends SceneTree
## Pure headless rule verification for the first rescue level.
const RescueLevel = preload("res://scripts/rescue_level.gd")
const Catalog = preload("res://scripts/level_catalog.gd")

func _initialize() -> void:
	var level = RescueLevel.new(Catalog.new().load_level(3))
	if not _check(level.width == 11 and level.height == 5, "Board dimensions"):
		return
	if not _check(not level.gate_is_open() and not level.fire_cleared and not level.rescued, "Initial hazards"):
		return
	if not _check(level.positions[level.FIREFIGHTER] == Vector2i(1, 1), "Firefighter spawn"):
		return

	# Wrong role, wall, diagonal moves, occupancy and locked gate are rejected.
	if not _check(not level.act(Vector2i(3, 1)) and level.actions == 0, "Nonadjacent move rejected"):
		return
	if not _check(not level.act(Vector2i(1, 0)), "Wall blocked"):
		return
	if not _check(level.select_role(level.ENGINEER), "Engineer selected"):
		return
	if not _check(level.act(Vector2i(2, 3)), "Engineer approaches crate"):
		return
	if not _check(level.act(Vector2i(3, 3)), "Engineer pushes crate"):
		return
	if not _check(level.crate_pos == level.switch_pos and level.gate_is_open(), "Switch opens gate"):
		return
	if not _check(level.undo() and not level.gate_is_open() and level.crate_pos == Vector2i(3, 3), "Undo restores crate and gate"):
		return
	if not _check(level.act(Vector2i(3, 3)) and level.gate_is_open(), "Crate can be repositioned"):
		return

	if not _check(level.select_role(level.FIREFIGHTER), "Firefighter selected"):
		return
	if not _check(level.act(Vector2i(2, 1)), "Firefighter approaches fire"):
		return
	if not _check(level.act(Vector2i(3, 1)) and level.fire_cleared, "Fire extinguished"):
		return
	if not _check(level.undo() and not level.fire_cleared, "Undo restores fire"):
		return
	if not _check(level.act(Vector2i(3, 1)) and level.fire_cleared, "Fire can be cleared again"):
		return
	if not _check(level.act(Vector2i(3, 1)), "Enter cleared tile"):
		return
	if not _check(level.act(Vector2i(4, 1)), "Walk toward civilian"):
		return
	if not _check(level.act(Vector2i(5, 1)) and level.carrying_role == level.FIREFIGHTER, "Pick up civilian"):
		return
	if not _check(level.act(Vector2i(6, 1)), "Carry toward gate"):
		return
	if not _check(level.act(Vector2i(7, 1)) and level.gate_is_open(), "Pass open gate"):
		return
	if not _check(level.act(Vector2i(8, 1)) and level.rescued, "Civilian rescued at exit"):
		return
	if not _check(not level.act(Vector2i(7, 1)), "No moves after victory"):
		return
	if not _check(level.undo() and not level.rescued and level.carrying_role == level.FIREFIGHTER, "Undo victory"):
		return
	level.reset()
	if not _check(level.actions == 0 and level.history.is_empty() and not level.gate_is_open() and not level.rescued, "Restart restores initial puzzle"):
		return

	# Engineer cannot clear fire; firefighter cannot push crates; occupants block movement.
	if not _check(level.select_role(level.ENGINEER), "Select engineer for invalid-action checks"):
		return
	if not _check(level.act(Vector2i(1, 2)), "Engineer walks toward firefighter"):
		return
	if not _check(not level.act(Vector2i(1, 1)), "Other rescuer blocks adjacent tile"):
		return
	if not _check(level.act(Vector2i(1, 3)) and level.act(Vector2i(2, 3)), "Return to crate corridor"):
		return
	if not _check(level.select_role(level.FIREFIGHTER), "Switch to firefighter"):
		return
	if not _check(level.act(Vector2i(2, 1)), "Approach fire again"):
		return
	if not _check(level.act(Vector2i(3, 1)) and level.fire_cleared, "Extinguish action is allowed"):
		return
	if not _check(level.undo() and not level.fire_cleared, "Undo fire action"):
		return

	# Isolate role restrictions and the locked gate without changing the scenario.
	var restrictions = RescueLevel.new(Catalog.new().load_level(3))
	restrictions.positions[restrictions.ENGINEER] = Vector2i(2, 1)
	restrictions.select_role(restrictions.ENGINEER)
	if not _check(not restrictions.act(Vector2i(3, 1)) and not restrictions.fire_cleared, "Engineer cannot extinguish fire"):
		return
	restrictions.positions[restrictions.FIREFIGHTER] = Vector2i(2, 3)
	restrictions.select_role(restrictions.FIREFIGHTER)
	if not _check(not restrictions.act(Vector2i(3, 3)) and restrictions.crate_pos == Vector2i(3, 3), "Firefighter cannot push crate"):
		return
	restrictions.positions[restrictions.FIREFIGHTER] = Vector2i(6, 1)
	if not _check(not restrictions.act(Vector2i(7, 1)) and not restrictions.gate_is_open(), "Locked gate blocks movement"):
		return


	# Tap-to-destination is a shortest safe path, not teleportation.
	var navigation = RescueLevel.new(Catalog.new().load_level(3))
	if not _check(navigation.plan_route(Vector2i(5, 1)).is_empty(), "Fire blocks path to civilian"):
		return
	if not _check(navigation.positions[navigation.FIREFIGHTER] == Vector2i(1, 1) and navigation.history.is_empty(), "Failed route has no state changes"):
		return
	navigation.select_role(navigation.ENGINEER)
	if not _check(_navigate(navigation, Vector2i(3, 3)), "Engineer taps distant crate"):
		return
	if not _check(navigation.gate_is_open() and navigation.positions[navigation.ENGINEER] == Vector2i(3, 3), "Crate pushed onto switch using auto-route"):
		return
	if not _check(navigation.history.size() == 1 and navigation.actions == 2, "Walking path is one undo step"):
		return
	if not _check(navigation.undo() and not navigation.gate_is_open() and navigation.positions[navigation.ENGINEER] == Vector2i(1, 3), "Undo restores entire route"):
		return
	if not _check(_navigate(navigation, Vector2i(3, 3)), "Reapply engineer route"):
		return
	navigation.select_role(navigation.FIREFIGHTER)
	if not _check(_navigate(navigation, Vector2i(3, 1)) and navigation.fire_cleared, "Fire tap automatically approaches and extinguishes"):
		return
	if not _check(_navigate(navigation, Vector2i(5, 1)) and navigation.carrying_role == navigation.FIREFIGHTER, "Civilian tap automatically walks and picks up"):
		return
	if not _check(_navigate(navigation, Vector2i(8, 1)) and navigation.rescued, "Exit tap automatically walks and completes mission"):
		return
	if not _check(navigation.history.size() == 4, "Four destination taps remain four undo steps"):
		return
	if not _check(navigation.undo() and not navigation.rescued and navigation.positions[navigation.FIREFIGHTER] == Vector2i(5, 1), "Undo distant exit trip in one step"):
		return
	if not _check(navigation.plan_route(Vector2i(0, 0)).is_empty(), "Cannot path through walls"):
		return
	var closed = RescueLevel.new(Catalog.new().load_level(3))
	closed.positions[closed.FIREFIGHTER] = Vector2i(6, 1)
	if not _check(closed.plan_route(Vector2i(8, 1)).is_empty(), "Cannot path through a closed gate"):
		return
	if not _check(closed.plan_route(Vector2i(1, 3)).is_empty(), "Cannot navigate into other rescuer"):
		return

	print("PASS: first Rescue Team puzzle, role restrictions, undo and full winning path")
	quit(0)

func _navigate(level: RefCounted, target: Vector2i) -> bool:
	var route: Array[Vector2i] = level.plan_route(target)
	if route.is_empty():
		return false
	var undo_from: int = level.history.size()
	for cell in route:
		if not level.act(cell):
			return false
	level.collapse_history(undo_from)
	return true

func _check(condition: bool, description: String) -> bool:
	if condition:
		return true
	push_error("FAIL: " + description)
	quit(1)
	return false
