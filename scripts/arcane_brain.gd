class_name ArcaneBrain
extends CpuBrain
## The Arcane: bonus duel boss. On top of the normal CPU behaviour it predicts
## incoming orbs and escapes them by teleporting, dashing (untouchable) or
## jumping, fires telegraphed laser beams, and repositions by teleport.
## The laser shows an aiming line for LASER_CHARGE seconds and locks its aim
## LASER_LOCK seconds before firing, so moving out of the line dodges it.
## Designed to be almost unbeatable: only a tiny share of threats slip past.

## Chance that a newly spotted orb is ignored (the only way to land a hit).
const MISS_CHANCE := 0.04
## React to orbs predicted to arrive within this many seconds.
const REACT_TIME := 0.32

var _tp_cooldown := 1.0
var _dash_cooldown := 0.0
var _laser_cooldown := 1.5
var _laser_charge := -1.0
var _laser_dir := Vector2.RIGHT
var _reposition := 4.0
var _seen := {}
var _spots: Array[Vector2] = []


func _ready() -> void:
	_spots = _stand_spots()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_instance_valid(me) or not is_instance_valid(foe):
		return
	if not me.can_act or foe.health <= 0 or me.health <= 0:
		_cancel_laser()
		return
	_tp_cooldown -= delta
	_dash_cooldown -= delta
	_laser_cooldown -= delta
	_reposition -= delta

	var threat := _threat()
	if threat != null:
		_evade(threat)
	elif _reposition <= 0.0 and _tp_cooldown <= 0.0 and _laser_charge < 0.0:
		_reposition = randf_range(3.5, 6.0)
		_teleport()

	_update_laser(delta)


## The nearest enemy orb predicted to hit within REACT_TIME, or null.
func _threat() -> MagicOrb:
	var center := me.global_position + Vector2(0, -10)
	var step := 1.0 / Engine.physics_ticks_per_second
	var frames := int(REACT_TIME / step)
	for node in me.get_parent().get_children():
		var orb := node as MagicOrb
		if orb == null or orb.shooter == me or orb.is_queued_for_deletion():
			continue
		var id := orb.get_instance_id()
		if not _seen.has(id):
			_seen[id] = randf() < MISS_CHANCE
		if _seen[id]:
			continue
		var pos := orb.global_position
		var vel := orb.velocity
		for i in frames:
			vel = OrbPhysics.next_velocity(vel, step)
			pos += vel * step
			if pos.distance_to(center + me.velocity * step * i) < 16.0:
				return orb
	return null


func _evade(orb: MagicOrb) -> void:
	_cancel_laser()
	if _tp_cooldown <= 0.0:
		_teleport()
	elif _dash_cooldown <= 0.0:
		var away := signf(me.global_position.x - orb.global_position.x)
		if away == 0.0:
			away = 1.0
		if _wall_near(away):
			away = -away
		me.dash(away)
		_dash_cooldown = Tuning.DASH_COOLDOWN
	else:
		_jump = true


func _wall_near(direction: float) -> bool:
	var from := me.global_position + Vector2(0, -10)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(direction * 70.0, 0), OrbPhysics.MASK_WORLD)
	return not me.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _teleport() -> void:
	if _spots.is_empty():
		return
	var good: Array[Vector2] = []
	for spot in _spots:
		var d := spot.distance_to(foe.global_position)
		if d > 140.0 and d < 320.0 and spot.distance_to(me.global_position) > 60.0:
			good.append(spot)
	var target: Vector2 = good.pick_random() if not good.is_empty() else _spots.pick_random()
	var tint := Color.from_hsv(randf(), 0.8, 1.0)
	Vfx.sparkle(me.get_parent(), me.global_position + Vector2(0, -12), tint, 16)
	me.teleport(target)
	Vfx.sparkle(me.get_parent(), target + Vector2(0, -12), tint, 16)
	Sfx.play("teleport")
	_tp_cooldown = Tuning.TELEPORT_COOLDOWN


func _update_laser(delta: float) -> void:
	if _laser_charge >= 0.0:
		_laser_charge += delta
		var locked := _laser_charge >= Tuning.LASER_CHARGE - Tuning.LASER_LOCK
		if not locked:
			_laser_dir = _aim_dir()
		me.facing = 1 if _laser_dir.x >= 0.0 else -1
		me.special_charge = clampf(_laser_charge / Tuning.LASER_CHARGE, 0.0, 1.0)
		me.laser_aim = _laser_dir
		me.laser_locked = locked
		if _laser_charge >= Tuning.LASER_CHARGE:
			_fire_laser()
			_cancel_laser()
	elif _laser_cooldown <= 0.0 and not me.is_dashing() and _clear_line():
		_laser_charge = 0.0
		_laser_dir = _aim_dir()


func _cancel_laser() -> void:
	if _laser_charge >= 0.0:
		_laser_cooldown = randf_range(Tuning.LASER_COOLDOWN_MIN, Tuning.LASER_COOLDOWN_MAX)
	_laser_charge = -1.0
	me.special_charge = 0.0
	me.laser_aim = Vector2.ZERO
	me.laser_locked = false


## Direction from the wand tip to where the wizard is now.
func _aim_dir() -> Vector2:
	var aim := foe.global_position + Vector2(0, -10)
	return (aim - me.wand_tip(aim - me.global_position)).normalized()


func _aim_point() -> Vector2:
	return foe.global_position + Vector2(0, -10) + foe.velocity * 0.05


func _clear_line() -> bool:
	var from := me.wand_tip(_aim_point() - me.global_position)
	var query := PhysicsRayQueryParameters2D.create(from, _aim_point(), OrbPhysics.MASK_WORLD)
	return me.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Fires along the locked direction, so a wizard who moved out of the line is safe.
func _fire_laser() -> void:
	var dir := _laser_dir
	var from := me.wand_tip(dir)
	var exclude: Array[RID] = [me.get_rid()]
	var query := PhysicsRayQueryParameters2D.create(from, from + dir * 900.0, OrbPhysics.MASK_WORLD | OrbPhysics.MASK_PLAYER, exclude)
	var hit := me.get_world_2d().direct_space_state.intersect_ray(query)
	var end: Vector2 = hit.position if not hit.is_empty() else from + dir * 900.0
	if not hit.is_empty() and hit.collider == foe:
		foe.take_damage(Tuning.LASER_DAMAGE, me)
	LaserBeam.spawn(me.get_parent(), from, end, Color("ff3b5c"))
	Sfx.play("laser")


## Every tile top the boss can stand on in the arena (feet positions).
func _stand_spots() -> Array[Vector2]:
	var data := LevelData.arena()
	var width: int = data["width"]
	var solid := {}
	for s in data["solids"]:
		var h: int = s[3] if s[3] > 0 else LevelData.HEIGHT - s[1]
		for x in range(s[0], s[0] + s[2]):
			for y in range(s[1], s[1] + h):
				solid[Vector2i(x, y)] = true
	var spots: Array[Vector2] = []
	for cell in solid:
		var c: Vector2i = cell
		if c.x < 1 or c.x > width - 2:
			continue
		if not solid.has(c + Vector2i.UP) and not solid.has(c + Vector2i(0, -2)):
			spots.append(LevelData.foot(c + Vector2i.UP))
	return spots
