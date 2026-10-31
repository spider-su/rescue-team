extends RefCounted
## Contextual goals, not a solution playback system. Hints never act on the board.
static func goal(level: RefCounted) -> Dictionary:
	if level.valve_pos.x >= 0 and not level.water_drained:
		return _goal("valve", "engineer", level.valve_pos, "Drain the flooded route.", "Select ENGINEER, then tap the valve wheel.")
	if level.bridge_pos.x >= 0 and not level.bridge_built:
		return _goal("bridge", "engineer", level.bridge_pos, "The gap needs a safe crossing.", "Select ENGINEER, then tap the broken bridge to repair it.")
	if level.has_gate and not level.gate_is_open():
		return _goal("gate", "engineer", level.crate_pos, "The gate needs power from the blue switch.", "Select ENGINEER. Push the highlighted crate toward the blue switch. Leave room behind it.")
	if level.has_fire and not level.fire_cleared:
		return _goal("fire", "firefighter", level.fire_pos, "Make the burning passage safe first.", "Select FIREFIGHTER, then tap the flame. Your hero walks up safely and sprays it.")
	if not level.infected.is_empty():
		return _goal("infected", "ranger", level.infected.keys()[0], "Contain the infected blocking the passage.", "Select RANGER, then tap the highlighted infected to approach and stun it.")
	if level.carrying_role.is_empty():
		return _goal("civilian", level.selected, level.civilian_pos, "Reach the person waiting for help.", "Tap the highlighted civilian to walk over and collect them. UNDO reverses a whole tap.")
	return _goal("exit", level.carrying_role, level.exit_pos, "Bring the civilian to the green exit.", "Select the hero carrying the civilian, then tap the highlighted EXIT. If blocked, clear a passage first.")

static func _goal(key: String, role: String, target: Vector2i, nudge: String, detail: String) -> Dictionary:
	return {"key": key, "role": role, "target": target, "nudge": nudge, "detail": detail}
