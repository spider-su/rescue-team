extends SceneTree
## Pure headless rule verification for the first rescue level.
const RescueLevel = preload("res://scripts/rescue_level.gd")
const Catalog = preload("res://scripts/level_catalog.gd")

func _initialize() -> void:
	if not _test_blocked_reasons():
		return
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

	if not _test_civilian_push():
		return
	print("PASS: first Rescue Team puzzle, role restrictions, undo and full winning path")
	quit(0)

func _test_civilian_push() -> bool:
	var fixture := {
		"id": "civilian-push", "title": "Civilian protection", "hint": "",
		"rows": ["#########", "#F...X..#", "#########", "#E.BCsG.#", "#########"],
	}
	var mission = RescueLevel.new(fixture)
	mission.select_role(mission.ENGINEER)
	if not _check(mission.plan_route(mission.crate_pos).is_empty(), "Distant crate tap cannot push onto waiting civilian"):
		return false
	if not _check(mission.act(Vector2i(2, 3)), "Approach crate adjacent to civilian"):
		return false
	var actions_before: int = mission.actions
	var history_before: int = mission.history.size()
	if not _check(not mission.act(mission.crate_pos), "Adjacent crate push cannot overlap waiting civilian"):
		return false
	if not _check(mission.crate_pos == Vector2i(3, 3) and mission.positions[mission.ENGINEER] == Vector2i(2, 3) and mission.carrying_role.is_empty() and mission.actions == actions_before and mission.history.size() == history_before, "Rejected push preserves positions, civilian, moves and undo history"):
		return false
	# Once carried, the civilian no longer occupies the starting tile.
	mission.carrying_role = mission.FIREFIGHTER
	if not _check(mission.act(mission.crate_pos) and mission.crate_pos == mission.civilian_pos, "Collected civilian's former tile allows crate movement"):
		return false
	return _check(mission.undo() and mission.crate_pos == Vector2i(3, 3) and mission.carrying_role == mission.FIREFIGHTER, "Undo restores legal push without dropping civilian")

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

func _test_blocked_reasons() -> bool:
	for marker in ["f", "G", "B", "Z"]:
		var fixture := {"id": "blocked", "title": "Blocked route", "hint": "", "rows": ["###########", "#F.%s...CX.#" % marker, "###########", "#ER..BsGf.#", "###########"]}
		# Only one of each optional obstacle is supported.
		if marker == "f":
			fixture.rows[3] = "#ER..BsG..#"
		elif marker == "G":
			fixture.rows[3] = "#ER..Bs.f.#"
		elif marker == "B":
			fixture.rows[3] = "#ER...sGf.#"
		var mission = RescueLevel.new(fixture)
		var expected: String = {"f": "fire", "G": "gate", "B": "crate", "Z": "infected"}[marker]
		if not _check(mission.plan_route(Vector2i(7, 1)).is_empty() and mission.blocked_reason == expected, "Unreachable destination explains the blocking " + expected):
			return false
		if not _check(mission.actions == 0 and mission.history.is_empty() and mission.positions[mission.FIREFIGHTER] == Vector2i(1, 1), "Diagnostic does not mutate puzzle"):
			return false
		mission.plan_route(Vector2i(2, 1))
		if not _check(mission.blocked_reason.is_empty(), "Valid route clears stale rejection"):
			return false
	var lines = preload("res://scripts/hero_lines.gd").new()
	for reason in lines.LINES:
		var previous := ""
		for i in range(30):
			var line: String = lines.next_line(reason)
			if not _check(line in lines.LINES[reason] and line != previous, "Message variation stays relevant without immediate repeats"):
				return false
			previous = line
	return true
