extends SceneTree
## Presentation-only action timing must always settle before another input is accepted.
const BoardView = preload("res://scripts/board_view.gd")
const Level = preload("res://scripts/rescue_level.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
var failed := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var facing_board = BoardView.new()
	facing_board.level = Level.new(Catalog.new().load_level(0))
	facing_board.size = Vector2(640, 760)
	root.add_child(facing_board)
	await process_frame
	_check(facing_board._metrics()["rotated"], "Tall board uses the rotated display layout")
	await facing_board.animate_step("firefighter", Vector2i(1, 1), Vector2i(1, 2))
	_check(facing_board.facing.get("firefighter") == -1, "A displayed leftward walk faces left on the rotated board")
	await facing_board.animate_step("firefighter", Vector2i(1, 2), Vector2i(2, 2))
	_check(facing_board.facing.get("firefighter") == -1, "A displayed vertical walk preserves the previous left/right facing")
	facing_board.queue_free()

	var board = BoardView.new()
	# Mission 11 includes all three specialists for the shared presentation pass.
	board.level = Level.new(Catalog.new().load_level(10))
	board.size = Vector2(640, 760)
	root.add_child(board)
	await process_frame
	await board.animate_step("firefighter", Vector2i(1, 1), Vector2i(2, 1))
	await board.animate_spray("firefighter", board.level.fire_pos)
	await board.animate_push("engineer", Vector2i(2, 3), board.level.crate_pos, board.level.crate_pos + Vector2i.RIGHT)
	await board.animate_pickup("firefighter", Vector2i(3, 1), board.level.civilian_pos)
	await board.animate_stun("ranger", Vector2i(4, 1))
	await board.animate_valve("engineer", Vector2i(3, 3))
	board.level.rescued = true
	await board.animate_victory("firefighter")
	for kind in ["walk", "spray", "push", "pickup", "stun", "valve", "celebrate"]:
		_check(board.animation_counts[kind] >= 1, "Action animation starts: " + kind)
	_check(board.effect_kind.is_empty() and board.animated_role.is_empty() and board.walk_progress == 0.0, "Every action clears its visual state")
	board.queue_free()
	if not failed:
		print("PASS: modern action presentation settles for every specialist action")
	quit(1 if failed else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: " + description)
