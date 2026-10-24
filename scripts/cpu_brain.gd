class_name CpuBrain
extends Node
## Drives the computer wizard in the offline duel. It exposes the same
## interface as TouchControls (move_axis / consume_jump / jump_held), so the
## computer plays by exactly the same movement and orb rules as the player.

signal fire_requested(drag: Vector2)

## Per difficulty: seconds between shots, aim error (px), chance to hop over
## an incoming orb, how much it leads a moving target, and how often it uses
## its double jump (dodging in mid-air, climbing toward the player, or at random),
## and random hops per second so it is a moving target.
const LEVELS := {
	1: {"name": "Easy", "cooldown": 1.8, "error": 28.0, "dodge": 0.15, "lead": 0.0, "double": 0.25, "hop": 0.15},
	2: {"name": "Normal", "cooldown": 1.15, "error": 12.0, "dodge": 0.45, "lead": 0.6, "double": 0.6, "hop": 0.35},
	3: {"name": "Hard", "cooldown": 0.65, "error": 4.0, "dodge": 0.8, "lead": 1.0, "double": 0.9, "hop": 0.55},
}

var me: Player
var foe: Player
var difficulty := 2
var jump_held := false

var _axis := 0.0
var _jump := false
var _fire_timer := 1.2
var _think := 0.0
var _strafe := 0.0
var _dodge_cooldown := 0.0
var _double_used := false
var _double_considered := false


static func level_name(level: int) -> String:
	return str(LEVELS[clampi(level, 1, 3)]["name"])


func move_axis() -> float:
	return _axis


func consume_jump() -> bool:
	var queued := _jump
	_jump = false
	return queued


func is_aiming() -> bool:
	return false


func aim_drag() -> Vector2:
	return Vector2.ZERO


func _physics_process(delta: float) -> void:
	_axis = 0.0
	if not is_instance_valid(me) or not is_instance_valid(foe) or not me.can_act or foe.health <= 0:
		return
	var cfg: Dictionary = LEVELS[clampi(difficulty, 1, 3)]
	var dx := foe.global_position.x - me.global_position.x
	var dist := absf(dx)
	var toward := signf(dx)

	# Keep a comfortable casting distance, drifting a little to stay hard to hit.
	_think -= delta
	if _think <= 0.0:
		_think = randf_range(0.3, 0.7)
		_strafe = randf_range(-0.6, 0.6)
	if dist > 230.0:
		_axis = toward
	elif dist < 110.0:
		_axis = -toward
	else:
		_axis = _strafe
	if me.is_on_floor() and (me.is_on_wall() or (foe.global_position.y < me.global_position.y - 40.0 and randf() < 0.02)):
		_jump = true
	elif me.is_on_floor() and randf() < float(cfg["hop"]) * delta:
		_jump = true

	_dodge_cooldown -= delta
	if _dodge_cooldown <= 0.0 and me.is_on_floor() and _orb_incoming():
		_dodge_cooldown = 0.8
		if randf() < cfg["dodge"]:
			_jump = true

	_think_double(cfg)

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = float(cfg["cooldown"]) * randf_range(0.8, 1.2) if _try_fire(cfg, dist) else 0.3


## Decides once per airborne arc, near the top of the jump, whether to spend
## the air jump: to dodge an orb, to reach a higher foe, or just to mix it up.
func _think_double(cfg: Dictionary) -> void:
	if me.is_on_floor():
		_double_used = false
		_double_considered = false
		return
	if _double_used or me.velocity.y < -80.0:
		return
	var chance := float(cfg["double"])
	if _orb_incoming():
		if randf() < chance:
			_jump = true
			_double_used = true
		return
	if _double_considered:
		return
	_double_considered = true
	var foe_above := foe.global_position.y < me.global_position.y - 24.0
	if (foe_above and randf() < chance) or randf() < chance * 0.3:
		_jump = true
		_double_used = true


func _orb_incoming() -> bool:
	var center := me.global_position + Vector2(0, -10)
	for node in me.get_parent().get_children():
		var orb := node as MagicOrb
		if orb == null or orb.shooter == me:
			continue
		var to_me := center - orb.global_position
		if to_me.length() < 90.0 and orb.velocity.dot(to_me) > 0.0:
			return true
	return false


func _try_fire(cfg: Dictionary, dist: float) -> bool:
	var target := foe.global_position + Vector2(0, -10)
	target += foe.velocity * float(cfg["lead"]) * (dist / Tuning.ORB_MAX_SPEED)
	target += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * float(cfg["error"])
	var exclude: Array[RID] = [me.get_rid()]
	var space := me.get_world_2d().direct_space_state
	for high_arc in [false, true]:
		var from := me.wand_tip(target - me.global_position)
		var vel := OrbPhysics.solve_launch(from, target, Tuning.ORB_MAX_SPEED, high_arc)
		if vel == Vector2.ZERO:
			continue
		# Skip shots that would only hit a platform on the way.
		var path := OrbPhysics.simulate(space, from, vel, me.orb_mask, exclude, 2.0)
		if path[path.size() - 1].distance_to(target) < 40.0:
			me.try_fire(-vel.normalized() * Tuning.MAX_PULL)
			return true
	return false
