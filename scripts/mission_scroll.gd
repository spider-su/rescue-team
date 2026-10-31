extends ScrollContainer
## Own pointer gestures before child cards consume them; a drag never clicks a card.
const DEADZONE = 10.0
var _pointer: int = -1
var _origin := Vector2.ZERO
var _previous := Vector2.ZERO
var _start_scroll: float = 0
var _dragging := false
var _velocity: float = 0
var _coast_position: float = 0
var _last_motion: int = 0
var _suppress_mouse_until: int = 0

func _ready() -> void:
	follow_focus = false
	get_v_scroll_bar().custom_minimum_size.x = 24

func is_dragging() -> bool:
	return _dragging

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		_pointer = -1
		_dragging = false
		_velocity = 0
		return
	if event is InputEventPanGesture or (event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]):
		_velocity = 0
		return # Native wheel/trackpad scrolling still works through card mouse pass-through.
	# Real touch is handled once; ignore its emulated mouse duplicate.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		if _pointer >= 0 or Time.get_ticks_msec() < _suppress_mouse_until:
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		_suppress_mouse_until = Time.get_ticks_msec() + 150
		if event.pressed:
			if _pointer == -1 and _inside_scroll(event.position):
				_begin(event.index, event.position)
		elif event.index == _pointer:
			_end()
	elif event is InputEventScreenDrag and event.index == _pointer:
		_motion(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _pointer == -1 and _inside_scroll(event.position):
			_begin(-2, event.position)
		elif not event.pressed and _pointer == -2:
			_end()
	elif event is InputEventMouseMotion and _pointer == -2:
		_motion(event.position)

func _inside_scroll(point: Vector2) -> bool:
	var area := get_global_rect()
	area.size.x -= 28 # Preserve native scrollbar dragging.
	return area.has_point(point)

func _begin(pointer: int, point: Vector2) -> void:
	var was_coasting := absf(_velocity) > 50
	_pointer = pointer
	_origin = point
	_previous = point
	_start_scroll = scroll_vertical
	_last_motion = Time.get_ticks_msec()
	_velocity = 0
	_dragging = was_coasting
	if _dragging:
		_cancel_cards()
		get_viewport().set_input_as_handled()

func _motion(point: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if not _dragging and absf(point.y - _origin.y) >= DEADZONE:
		_dragging = true
		_cancel_cards()
	if _dragging:
		scroll_vertical = roundi(_start_scroll - (point.y - _origin.y))
		var seconds := maxf(0.008, float(now - _last_motion) / 1000.0)
		_velocity = clampf((_previous.y - point.y) / seconds, -1800, 1800)
		get_viewport().set_input_as_handled()
	_previous = point
	_last_motion = now

func _end() -> void:
	if _dragging:
		# Consume release and cancel native button press attempts before GUI dispatch.
		_cancel_cards()
		get_viewport().set_input_as_handled()
	else:
		_velocity = 0
	if Time.get_ticks_msec() - _last_motion > 120:
		_velocity = 0
	_pointer = -1
	_dragging = false
	_coast_position = scroll_vertical

func _cancel_cards() -> void:
	get_viewport().gui_release_focus()
	propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)

func _process(delta: float) -> void:
	if _pointer != -1 or not is_visible_in_tree():
		return
	if absf(_velocity) < 20:
		_velocity = 0
		return
	var limit: float = maxf(0, get_v_scroll_bar().max_value - get_v_scroll_bar().page)
	_coast_position = clampf(_coast_position + _velocity * delta, 0, limit)
	scroll_vertical = roundi(_coast_position)
	_velocity *= exp(-7 * delta)
	if _coast_position <= 0 or _coast_position >= limit:
		_velocity = 0

func reset_scroll() -> void:
	stop_scrolling()
	scroll_vertical = 0

func stop_scrolling() -> void:
	_pointer = -1
	_dragging = false
	_velocity = 0
