class_name TouchControls
extends CanvasLayer
## Multitouch input: floating joystick (left), jump button (bottom right) and
## pull-back aiming (anywhere else on the right). A finger belongs to the
## control it started on until it lifts, so controls never steal each other's
## touches. The jump button area can never start an aim, and releasing an aim
## over it cancels the shot.

signal fire_requested(drag: Vector2)

const JOY_RADIUS := 36.0
const JUMP_RADIUS := 30.0
const LEFT_ZONE := 0.38
const PAUSE_CORNER := Vector2(60, 48)

var jump_held := false

var _joy_index := -1
var _joy_origin := Vector2.ZERO
var _joy_pos := Vector2.ZERO
var _jump_index := -1
var _jump_queued := false
var _aim_index := -1
var _aim_start := Vector2.ZERO
var _aim_pos := Vector2.ZERO
var _canvas: Control


func _ready() -> void:
	layer = 5
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)


func _process(_delta: float) -> void:
	_canvas.queue_redraw()


func move_axis() -> float:
	if _joy_index == -1:
		return 0.0
	var x := clampf((_joy_pos.x - _joy_origin.x) / JOY_RADIUS, -1.0, 1.0)
	return 0.0 if absf(x) < 0.2 else x


func consume_jump() -> bool:
	var queued := _jump_queued
	_jump_queued = false
	return queued


func is_aiming() -> bool:
	return _aim_index != -1


func aim_drag() -> Vector2:
	return _aim_pos - _aim_start


func cancel_all() -> void:
	_joy_index = -1
	_jump_index = -1
	_aim_index = -1
	_jump_queued = false
	jump_held = false


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_PAUSED:
			cancel_all()


func _screen() -> Vector2:
	return _canvas.get_viewport_rect().size


func _jump_center() -> Vector2:
	var s := _screen()
	return Vector2(s.x - 56, s.y - 52)


func _joy_home() -> Vector2:
	return Vector2(68, _screen().y - 64)


func _in_jump(p: Vector2) -> bool:
	return p.distance_to(_jump_center()) <= JUMP_RADIUS + 10.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_press(touch.index, touch.position)
		else:
			_release(touch.index, touch.position, touch.canceled)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_drag(drag.index, drag.position)


func _press(index: int, p: Vector2) -> void:
	var s := _screen()
	if p.x > s.x - PAUSE_CORNER.x and p.y < PAUSE_CORNER.y:
		return
	if _in_jump(p):
		if _jump_index == -1:
			_jump_index = index
			_jump_queued = true
			jump_held = true
	elif p.x < s.x * LEFT_ZONE:
		if _joy_index == -1:
			_joy_index = index
			_joy_origin = p
			_joy_pos = p
	elif _aim_index == -1:
		_aim_index = index
		_aim_start = p
		_aim_pos = p


func _drag(index: int, p: Vector2) -> void:
	if index == _joy_index:
		_joy_pos = p
		# The base follows a finger that slides past the rim.
		var offset := _joy_pos - _joy_origin
		if offset.length() > JOY_RADIUS:
			_joy_origin = _joy_pos - offset.normalized() * JOY_RADIUS
	elif index == _aim_index:
		_aim_pos = p


func _release(index: int, p: Vector2, canceled: bool) -> void:
	if index == _aim_index:
		_aim_pos = p
		var drag := aim_drag()
		_aim_index = -1
		if not canceled and not _in_jump(p):
			fire_requested.emit(drag)
	elif index == _joy_index:
		_joy_index = -1
	elif index == _jump_index:
		_jump_index = -1
		jump_held = false


func _draw_controls() -> void:
	var font := ThemeDB.fallback_font
	# Joystick
	var base := _joy_origin if _joy_index != -1 else _joy_home()
	var knob := _joy_pos if _joy_index != -1 else base
	if knob.distance_to(base) > JOY_RADIUS:
		knob = base + (knob - base).normalized() * JOY_RADIUS
	_canvas.draw_circle(base, JOY_RADIUS, Color(1, 1, 1, 0.1))
	_canvas.draw_arc(base, JOY_RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 2.0)
	_canvas.draw_circle(knob, 14.0, Color(1, 1, 1, 0.45 if _joy_index != -1 else 0.3))
	# Jump button
	var jc := _jump_center()
	_canvas.draw_circle(jc, JUMP_RADIUS, Color(0.37, 0.88, 0.6, 0.55 if jump_held else 0.28))
	_canvas.draw_arc(jc, JUMP_RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 2.0)
	_canvas.draw_string(font, jc + Vector2(-30, 5), "JUMP", HORIZONTAL_ALIGNMENT_CENTER, 60, 13, Color(1, 1, 1, 0.9))
	# Slingshot band while aiming
	if _aim_index != -1:
		var pull := aim_drag().limit_length(Tuning.MAX_PULL)
		var end := _aim_start + pull
		var strong := pull.length() >= Tuning.MIN_PULL
		_canvas.draw_circle(_aim_start, 6.0, Color(1, 1, 1, 0.35))
		_canvas.draw_line(_aim_start, end, Color(1, 0.9, 0.4, 0.8 if strong else 0.3), 2.0)
		_canvas.draw_circle(end, 9.0, Color(0.56, 0.89, 1.0, 0.5 if strong else 0.2))
