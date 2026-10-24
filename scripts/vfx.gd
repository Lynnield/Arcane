class_name Vfx
extends Node2D
## Lightweight one-shot particle bursts drawn as small pixel squares.
## Spawned into the world (not the character) so particles stay where they
## were emitted. Frees itself when every particle has faded.

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _life := PackedFloat32Array()
var _max_life := 0.5
var _gravity := 0.0
var _drag := 0.0
var _color := Color.WHITE
var _size := 2.0


## Dust kicked up by feet. `bias` pushes it sideways (-1 left, 1 right).
static func dust(parent: Node, at: Vector2, count: int, bias: float = 0.0) -> void:
	var v := _make(parent, at, Color(0.92, 0.88, 0.8, 0.8), 0.45, 0.0, 4.0, 2.0)
	for i in count:
		var dir := Vector2(randf_range(-1.0, 1.0) + bias, randf_range(-0.6, -0.1)).normalized()
		v._add(at + Vector2(randf_range(-3.0, 3.0), 0), dir * randf_range(15.0, 45.0))


## Small magic sparks drifting off a wand while aiming.
static func spark(parent: Node, at: Vector2, color: Color) -> void:
	var v := _make(parent, at, color, 0.35, -20.0, 2.0, 1.0)
	for i in 2:
		v._add(at, Vector2(randf_range(-20.0, 20.0), randf_range(-25.0, 5.0)))


## Ring of sparkles, e.g. when respawning at a checkpoint.
static func sparkle(parent: Node, at: Vector2, color: Color, count: int = 14) -> void:
	var v := _make(parent, at, color, 0.6, 30.0, 2.5, 2.0)
	for i in count:
		var a := TAU * i / count
		v._add(at, Vector2(cos(a), sin(a)) * randf_range(40.0, 70.0))


static func _make(parent: Node, at: Vector2, color: Color, life: float, gravity: float, drag: float, size: float) -> Vfx:
	var v := Vfx.new()
	v._color = color
	v._max_life = life
	v._gravity = gravity
	v._drag = drag
	v._size = size
	v.z_index = 15
	if is_instance_valid(parent):
		parent.add_child(v)
	return v


func _add(at: Vector2, vel: Vector2) -> void:
	_pos.append(at)
	_vel.append(vel)
	_life.append(_max_life * randf_range(0.7, 1.0))


func _process(delta: float) -> void:
	var alive := false
	for i in _pos.size():
		if _life[i] <= 0.0:
			continue
		alive = true
		_life[i] -= delta
		_vel[i] = (_vel[i] + Vector2(0, _gravity * delta)) * maxf(0.0, 1.0 - _drag * delta)
		_pos[i] += _vel[i] * delta
	if not alive:
		queue_free()
	queue_redraw()


func _draw() -> void:
	for i in _pos.size():
		if _life[i] <= 0.0:
			continue
		var k := _life[i] / _max_life
		var s := maxf(1.0, _size * k + 0.5)
		draw_rect(Rect2(_pos[i].floor() - Vector2(s, s) / 2.0, Vector2(s, s)), Color(_color, _color.a * k))
