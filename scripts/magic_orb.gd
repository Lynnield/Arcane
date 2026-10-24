class_name MagicOrb
extends Node2D
## Magic orb projectile. Direct hits only, no splash; disappears on its first
## collision with a wizard, enemy or solid obstacle.

signal impacted(orb: MagicOrb, collider: Object, at: Vector2)

var velocity := Vector2.ZERO
var mask := OrbPhysics.MASK_WORLD
var exclude: Array[RID] = []
var damage := Tuning.ORB_DAMAGE
var shooter: Node
var color := Color("8fe3ff")
## False on PvP phones: the host decides hits and health.
var apply_damage := true
var orb_id := -1
var owner_peer := 0

var _age := 0.0
var _trail := PackedVector2Array()


func setup(origin: Vector2, vel: Vector2, hit_mask: int, ignore: Array[RID], dmg: int, from: Node, tint: Color) -> void:
	position = origin
	velocity = vel
	mask = hit_mask
	exclude = ignore
	damage = dmg
	shooter = from
	color = tint


func _ready() -> void:
	z_index = 10


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > Tuning.ORB_MAX_LIFETIME:
		queue_free()
		return
	var next_vel := OrbPhysics.next_velocity(velocity, delta)
	var next_pos := global_position + next_vel * delta
	var hit := OrbPhysics.cast(get_world_2d().direct_space_state, global_position, next_pos, mask, exclude)
	_trail.append(global_position)
	if _trail.size() > 6:
		_trail.remove_at(0)
	if not hit.is_empty():
		explode(hit.position, hit.collider)
		return
	velocity = next_vel
	global_position = next_pos
	queue_redraw()


func explode(at: Vector2, collider: Object) -> void:
	if is_queued_for_deletion():
		return
	global_position = at
	if apply_damage and collider != null and collider.has_method("take_damage"):
		collider.take_damage(damage, shooter if is_instance_valid(shooter) else null)
	impacted.emit(self, collider, at)
	vanish()


## Removes the orb with an impact puff (also used when the PvP host says so).
func vanish() -> void:
	if is_queued_for_deletion():
		return
	Sfx.play("hit")
	var puff := Puff.new()
	puff.color = color
	puff.position = global_position
	get_parent().add_child(puff)
	queue_free()


func _draw() -> void:
	for i in _trail.size():
		var a := float(i + 1) / (_trail.size() + 1)
		draw_circle(_trail[i] - global_position, 1.0 + a * 1.5, Color(color, a * 0.5))
	draw_circle(Vector2.ZERO, 5.0, Color(color, 0.25))
	draw_circle(Vector2.ZERO, 3.0, color)
	draw_circle(Vector2.ZERO, 1.5, Color.WHITE)


class Puff extends Node2D:
	var color := Color.WHITE
	var _t := 0.0

	func _ready() -> void:
		z_index = 10

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.25:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := _t / 0.25
		draw_arc(Vector2.ZERO, 3.0 + k * 9.0, 0.0, TAU, 16, Color(color, 1.0 - k), 2.0)
