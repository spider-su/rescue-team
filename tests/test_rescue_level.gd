extends SceneTree
## Pure headless rule verification for the first rescue level.
const RescueLevel = preload("res://scripts/rescue_level.gd")

func _initialize() -> void:
	var level = RescueLevel.new()
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
	if not _check(not level.act(Vector2i(1, 1)), "Other rescuer blocks tile"):
		return
	if not _check(level.act(Vector2i(2, 3)), "Walk to crate again"):
		return
	if not _check(level.select_role(level.FIREFIGHTER), "Switch to firefighter"):
		return
	if not _check(level.act(Vector2i(2, 1)), "Approach fire again"):
		return
	if not _check(level.act(Vector2i(3, 1)) and level.fire_cleared, "Extinguish action is allowed"):
		return
	if not _check(level.undo() and not level.fire_cleared, "Undo fire action"):
		return

	print("PASS: first Rescue Team puzzle, rules, undo and full winning path")
	quit(0)

func _check(condition: bool, description: String) -> bool:
	if condition:
		return true
	push_error("FAIL: " + description)
	quit(1)
	return false
