class_name Player
extends CharacterBody2D
## The wizard. A local player reads TouchControls plus keyboard; a remote PvP
## player is driven by network state. Origin is at the feet.

signal health_changed(current: int, maximum: int)
signal hurt
signal jumped
signal double_jumped
signal respawned
signal died
signal fired(origin: Vector2, velocity: Vector2)

const ORB_SCENE := preload("res://scenes/magic_orb.tscn")
const HAND := Vector2(5, -11)
const WAND_LENGTH := 8.0

@export var robe_color := Color("6b4fd8")
@export var trim_color := Color("f2c14e")

var max_health := Tuning.PLAYER_MAX_HEALTH
var health := Tuning.PLAYER_MAX_HEALTH
## TouchControls for the player, or a CpuBrain for the computer wizard.
var controls: Node
## False for the computer wizard so the keyboard only moves the player.
var reads_keyboard := true
var is_local := true
var can_act := true
var show_marker := false
## Campaign: spawn orbs directly. PvP: only emit `fired`; the host spawns them.
var spawn_orbs_locally := true
var orb_mask := OrbPhysics.MASK_WORLD | OrbPhysics.MASK_ENEMY
var orb_damage := Tuning.ORB_DAMAGE
var orb_color := Color("8fe3ff")
var peer_id := 1

var facing := 1
var aiming := false
var aim_velocity := Vector2.ZERO
var invulnerable := 0.0
## Seconds left of the white hit flash (read by WizardVisual).
var hurt_flash := 0.0
var visual: WizardVisual

var _coyote := 0.0
var _air_jumps := 0
var _jump_buffer := 0.0
var _cooldown := 0.0
var _remote_target := Vector2.ZERO
var _exclude: Array[RID] = []
var _preview: TrajectoryPreview


func _ready() -> void:
	collision_layer = OrbPhysics.MASK_PLAYER
	collision_mask = OrbPhysics.MASK_WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 20)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	add_child(shape)
	_exclude.append(get_rid())
	_preview = TrajectoryPreview.new()
	add_child(_preview)
	visual = WizardVisual.new()
	visual.player = self
	add_child(visual)
	_remote_target = global_position
	if controls:
		controls.fire_requested.connect(try_fire)


func _physics_process(delta: float) -> void:
	invulnerable = maxf(invulnerable - delta, 0.0)
	hurt_flash = maxf(hurt_flash - delta, 0.0)
	_cooldown = maxf(_cooldown - delta, 0.0)
	modulate.a = 0.35 if invulnerable > 0.0 and int(invulnerable * 12.0) % 2 == 0 else 1.0

	if not is_local:
		global_position = global_position.lerp(_remote_target, minf(1.0, delta * 15.0))
		return

	var axis := 0.0
	var want_jump := false
	var holding_jump := false
	var touch_jump: bool = controls != null and controls.consume_jump()
	if can_act:
		if reads_keyboard:
			axis = Input.get_axis("move_left", "move_right")
			want_jump = Input.is_action_just_pressed("jump")
			holding_jump = Input.is_action_pressed("jump")
		if controls and is_zero_approx(axis):
			axis = controls.move_axis()
		want_jump = want_jump or touch_jump
		holding_jump = holding_jump or (controls != null and controls.jump_held)

	_jump_buffer = Tuning.JUMP_BUFFER if want_jump else _jump_buffer - delta
	_coyote = Tuning.COYOTE_TIME if is_on_floor() else _coyote - delta
	if is_on_floor():
		_air_jumps = Tuning.AIR_JUMPS

	var gravity := Tuning.PLAYER_GRAVITY
	if holding_jump and absf(velocity.y) < Tuning.APEX_HANG_SPEED:
		gravity *= Tuning.APEX_GRAVITY_SCALE
	velocity.y = minf(velocity.y + gravity * delta, Tuning.MAX_FALL_SPEED)
	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = Tuning.JUMP_VELOCITY
		_jump_buffer = 0.0
		_coyote = 0.0
		Sfx.play("jump")
		jumped.emit()
	elif want_jump and _coyote <= 0.0 and _air_jumps > 0:
		# A fresh press while airborne spends one air jump.
		velocity.y = Tuning.DOUBLE_JUMP_VELOCITY
		_air_jumps -= 1
		_jump_buffer = 0.0
		Sfx.play("double_jump")
		double_jumped.emit()
	# Releasing jump early gives a shorter hop.
	if velocity.y < 0.0 and not holding_jump:
		velocity.y += Tuning.PLAYER_GRAVITY * delta

	var accel := Tuning.PLAYER_ACCEL
	if absf(axis) > 0.1 and absf(velocity.x) > 1.0 and signf(axis) != signf(velocity.x):
		accel = Tuning.PLAYER_TURN_ACCEL
	elif absf(axis) <= 0.1 and is_on_floor():
		accel = Tuning.PLAYER_FRICTION
	velocity.x = move_toward(velocity.x, axis * Tuning.PLAYER_SPEED, accel * delta)
	move_and_slide()
	if absf(axis) > 0.1:
		facing = 1 if axis > 0.0 else -1
	_update_aim()


func _update_aim() -> void:
	aiming = can_act and controls != null and controls.is_aiming()
	aim_velocity = OrbPhysics.launch_velocity(controls.aim_drag()) if aiming else Vector2.ZERO
	if aim_velocity == Vector2.ZERO:
		_preview.clear()
		return
	if absf(aim_velocity.x) > 1.0:
		facing = 1 if aim_velocity.x > 0.0 else -1
	_preview.show_path(wand_tip(aim_velocity), aim_velocity, orb_mask, _exclude)


## Where the orb spawns: the tip of the wand, pointing along `direction`.
func wand_tip(direction: Vector2) -> Vector2:
	var f := facing
	if absf(direction.x) > 1.0:
		f = 1 if direction.x > 0.0 else -1
	return global_position + Vector2(HAND.x * f, HAND.y) + direction.normalized() * WAND_LENGTH


func try_fire(drag: Vector2) -> void:
	if not can_act or _cooldown > 0.0 or health <= 0:
		return
	var vel := OrbPhysics.launch_velocity(drag)
	if vel == Vector2.ZERO:
		return
	if absf(vel.x) > 1.0:
		facing = 1 if vel.x > 0.0 else -1
	_cooldown = Tuning.FIRE_COOLDOWN
	var origin := wand_tip(vel)
	Sfx.play("shoot")
	fired.emit(origin, vel)
	if spawn_orbs_locally:
		var orb := ORB_SCENE.instantiate() as MagicOrb
		orb.setup(origin, vel, orb_mask, _exclude, orb_damage, self, orb_color)
		get_parent().add_child(orb)


func take_damage(amount: int, _source: Node = null) -> void:
	if invulnerable > 0.0 or health <= 0:
		return
	set_health(health - amount)


func set_health(value: int) -> void:
	var previous := health
	health = clampi(value, 0, max_health)
	if health < previous:
		hurt_flash = 0.15
		Sfx.play("hurt")
		hurt.emit()
	health_changed.emit(health, max_health)
	if health == 0 and previous > 0:
		died.emit()


func reset_health() -> void:
	health = max_health
	health_changed.emit(health, max_health)


func respawn(at: Vector2) -> void:
	teleport(at)
	invulnerable = Tuning.RESPAWN_PROTECTION
	respawned.emit()


func teleport(at: Vector2) -> void:
	global_position = at
	_remote_target = at
	velocity = Vector2.ZERO
	_air_jumps = Tuning.AIR_JUMPS


func set_remote_state(pos: Vector2, vel: Vector2, new_facing: int, is_aiming: bool, aim_vel: Vector2) -> void:
	_remote_target = pos
	velocity = vel
	facing = 1 if new_facing >= 0 else -1
	aiming = is_aiming
	aim_velocity = aim_vel
