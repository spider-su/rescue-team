extends RefCounted
## Contextual goals, not a solution playback system. Hints never act on the board.
static func goal(level: RefCounted) -> Dictionary:
	if level.valve_pos.x >= 0 and not level.water_drained:
		return _goal("valve", "engineer", level.valve_pos, "Drain the flooded route.", "Select ENGINEER, then tap the valve wheel.")
	if level.bridge_pos.x >= 0 and not level.bridge_built:
		return _goal("bridge", "engineer", level.bridge_pos, "The gap needs a safe crossing.", "Select ENGINEER, then tap the broken bridge to repair it.")
	if level.has_gate and not level.gate_is_open():
		return _goal("gate", "engineer", level.crate_pos, "Theo can power the gate. Select ENGINEER, then tap the crate.", "Select ENGINEER. Push the highlighted crate toward the blue switch. Leave room behind it.")
	if level.has_fire and not level.fire_cleared:
		return _goal("fire", "firefighter", level.fire_pos, "Maya can clear the flame. Select FIREFIGHTER, then tap it.", "Select FIREFIGHTER, then tap the flame. Maya walks up safely and sprays it.")
	if not level.infected.is_empty():
		return _goal("infected", "ranger", level.infected.keys()[0], "Contain the infected blocking the passage.", "Select RANGER, then tap the highlighted infected to approach and stun it.")
	if level.carrying_role.is_empty():
		return _goal("civilian", level.selected, level.civilian_pos, "Maya needs help. Tap her to pick her up.", "Tap the highlighted civilian to walk over and collect Maya. UNDO reverses a whole tap.")
	return _goal("exit", level.carrying_role, level.exit_pos, "Maya is with you. Take her to the green exit.", "Select the hero carrying Maya, then tap the highlighted EXIT. If blocked, clear a passage first.")

static func _goal(key: String, role: String, target: Vector2i, nudge: String, detail: String) -> Dictionary:
	return {"key": key, "role": role, "target": target, "nudge": nudge, "detail": detail}
