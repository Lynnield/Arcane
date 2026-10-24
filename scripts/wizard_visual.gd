class_name WizardVisual
extends Node2D
## Draws and animates a Player. Purely visual: it reads the player's state and
## never changes physics, so the hitbox and the orb spawn point stay the same.
## The wand is always drawn through Player.wand_tip(), so the orb appears
## exactly where the wand points.
##
## Animations: idle breathing and blinking, run cycle with lean and robe trail,
## jump stretch, fall billow, landing squash with dust, turn squash, aim glow
## and sparks, cast recoil and flash, hurt knock-back tilt, respawn sparkles,
## and a twirl with a sparkle burst on double jump.

const SKIN := Color("f1c7a0")
const EYE := Color("1b1530")
const BEARD := Color("e8e4f0")
const BOOT := Color("2a1f3d")
const WAND := Color("8a5a32")
const SQUASH_LIMIT := 0.3
const TWIRL_TIME := 0.35

var player: Player

var _t := 0.0
var _scale := Vector2.ONE
var _scale_vel := Vector2.ZERO
var _tilt := 0.0
var _hurt_tilt := 0.0
var _run_phase := 0.0
var _blink := 0.0
var _next_blink := 2.5
var _recoil := 0.0
var _cast_flash := 0.0
var _respawn_glow := 0.0
var _spark_timer := 0.0
var _last_facing := 1
var _was_grounded := true
var _fall_speed := 0.0
var _prev_vy := 0.0
var _twirl := 0.0
var _was_ceiling := false


func _ready() -> void:
	_last_facing = player.facing
	player.jumped.connect(_on_jumped)
	player.hurt.connect(_on_hurt)
	player.fired.connect(_on_fired)
	player.respawned.connect(_on_respawned)


func _grounded() -> bool:
	if player.is_local:
		return player.is_on_floor()
	return absf(player.velocity.y) < 20.0


func _world() -> Node:
	return player.get_parent()


func _process(delta: float) -> void:
	var p := player
	_t += delta
	var grounded := _grounded()
	var speed := clampf(absf(p.velocity.x) / Tuning.PLAYER_SPEED, 0.0, 1.0)

	if grounded and not _was_grounded:
		var impact := clampf(_fall_speed / Tuning.MAX_FALL_SPEED, 0.25, 1.0)
		_kick(Vector2(1.0 + 0.25 * impact, 1.0 - 0.25 * impact))
		Vfx.dust(_world(), p.global_position, int(3 + 6 * impact))
	# A sudden upward kick while already airborne is a double jump. Detecting it
	# from velocity also animates the other phone's wizard in online duels.
	if not grounded and not _was_grounded and p.velocity.y < _prev_vy - 150.0:
		_on_double_jump()
	_prev_vy = p.velocity.y
	var ceiling := p.is_local and p.is_on_ceiling()
	if ceiling and not _was_ceiling:
		_kick(Vector2(1.15, 0.85))
		Vfx.dust(_world(), p.global_position + Vector2(0, -21), 3)
	_was_ceiling = ceiling
	_twirl = maxf(_twirl - delta, 0.0)
	if not grounded:
		_fall_speed = maxf(p.velocity.y, 0.0)
	_was_grounded = grounded

	if p.facing != _last_facing:
		_last_facing = p.facing
		_kick(Vector2(0.78, 1.05))

	if grounded and speed > 0.1:
		var before := _run_phase
		_run_phase += delta * (7.0 + 9.0 * speed)
		if speed > 0.6 and floori(before / PI) != floori(_run_phase / PI):
			Vfx.dust(_world(), p.global_position, 2, -float(p.facing))
	else:
		_run_phase = 0.0

	var target := Vector2.ONE
	if not grounded:
		var rise := clampf(-p.velocity.y / absf(Tuning.JUMP_VELOCITY), -1.0, 1.0)
		target = Vector2(1.0 - rise * 0.08, 1.0 + rise * 0.12) if rise > 0.0 else Vector2(1.04, 0.98)
	elif speed < 0.1:
		target = Vector2(1.0, 1.0 + 0.025 * sin(_t * 2.6))
	_scale_vel += ((target - _scale) * 260.0 - _scale_vel * 16.0) * delta
	_scale += _scale_vel * delta
	_scale = _scale.clamp(Vector2.ONE * (1.0 - SQUASH_LIMIT), Vector2.ONE * (1.0 + SQUASH_LIMIT))

	var lean := 0.1 * speed * p.facing if grounded else 0.05 * clampf(p.velocity.x / Tuning.PLAYER_SPEED, -1.0, 1.0)
	_hurt_tilt = move_toward(_hurt_tilt, 0.0, delta * 2.5)
	_tilt = lerpf(_tilt, lean + _hurt_tilt, 1.0 - exp(-12.0 * delta))

	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.12
		_next_blink = randf_range(2.2, 4.5)
	_blink = maxf(_blink - delta, 0.0)
	_recoil = move_toward(_recoil, 0.0, delta * 25.0)
	_cast_flash = maxf(_cast_flash - delta, 0.0)
	_respawn_glow = maxf(_respawn_glow - delta, 0.0)

	if p.aiming and p.aim_velocity != Vector2.ZERO:
		_spark_timer -= delta
		if _spark_timer <= 0.0:
			_spark_timer = lerpf(0.14, 0.04, _aim_power())
			Vfx.spark(_world(), p.wand_tip(p.aim_velocity), p.orb_color)
	queue_redraw()


func _kick(squash: Vector2) -> void:
	_scale = squash
	_scale_vel = Vector2.ZERO


func _aim_power() -> float:
	return clampf(player.aim_velocity.length() / Tuning.ORB_MAX_SPEED, 0.0, 1.0)


func _wand_dir() -> Vector2:
	var p := player
	if p.aiming and p.aim_velocity != Vector2.ZERO:
		return p.aim_velocity.normalized()
	var f := float(p.facing)
	var sway := sin(_t * 2.6) * 0.06
	if _grounded() and absf(p.velocity.x) > 10.0:
		return Vector2(0.8 * f, -0.6).normalized().rotated(sway * f)
	return Vector2(0.6 * f, -0.8).normalized().rotated(sway * f)


func _on_jumped() -> void:
	_kick(Vector2(0.8, 1.2))
	Vfx.dust(_world(), player.global_position, 4)


func _on_double_jump() -> void:
	_twirl = TWIRL_TIME
	_kick(Vector2(0.85, 1.15))
	Vfx.sparkle(_world(), player.global_position, player.orb_color, 10)


func _on_hurt() -> void:
	_hurt_tilt = -0.35 * player.facing
	_kick(Vector2(1.15, 0.85))


func _on_fired(origin: Vector2, _vel: Vector2) -> void:
	_recoil = 2.5
	_cast_flash = 0.12
	_kick(Vector2(1.08, 0.94))
	Vfx.sparkle(_world(), origin, player.orb_color, 6)
	_spark_timer = 0.1


func _on_respawned() -> void:
	_respawn_glow = 0.6
	Vfx.sparkle(_world(), player.global_position + Vector2(0, -12), player.orb_color)


## Squash and stretch, plus the double-jump twirl (a two-turn flip on x).
func _body_scale() -> Vector2:
	var s := _scale
	if _twirl > 0.0:
		s.x *= cos((1.0 - _twirl / TWIRL_TIME) * TAU * 2.0)
	return s


## Body point (feet-origin space) after squash, tilt and recoil.
func _body(point: Vector2, offset: Vector2) -> Vector2:
	return offset + (point * _body_scale()).rotated(_tilt)


func _draw() -> void:
	var p := player
	var f := float(p.facing)
	var back := -f
	var robe := Color.WHITE if p.hurt_flash > 0.0 else p.robe_color
	var dark := robe.darkened(0.35)
	var light := robe.lightened(0.2)
	var grounded := _grounded()
	var running := grounded and absf(p.velocity.x) > 10.0
	var speed := clampf(absf(p.velocity.x) / Tuning.PLAYER_SPEED, 0.0, 1.0)
	var dir := _wand_dir()
	var offset := -dir * _recoil

	if _respawn_glow > 0.0:
		draw_circle(Vector2(0, -12), 16.0 * (1.0 - _respawn_glow / 0.6) + 6.0, Color(p.orb_color, _respawn_glow * 0.5))

	draw_set_transform(offset, _tilt, _body_scale())

	# Feet
	var step := sin(_run_phase) if running else 0.0
	var foot_a := Vector2(-4.0 + step * 1.5, -1.5 - maxf(step, 0.0) * 1.5)
	var foot_b := Vector2(1.0 - step * 1.5, -1.5 - maxf(-step, 0.0) * 1.5)
	if not grounded:
		foot_a = Vector2(-4.0, -2.5)
		foot_b = Vector2(1.0, -2.0)
	draw_rect(Rect2(foot_a, Vector2(3, 1.5)), BOOT)
	draw_rect(Rect2(foot_b, Vector2(3, 1.5)), BOOT)

	# Robe: the back of the hem trails when running and billows when falling
	var bob := -absf(sin(_run_phase)) * 1.2 if running else 0.0
	var flare := 1.5 if not grounded and p.velocity.y > 40.0 else 0.0
	var trail := speed * 1.5
	var hem_back := Vector2(back * (6.0 + flare + trail), -1.0 - trail * 0.6)
	var hem_front := Vector2(-back * (6.0 + flare), -1.0)
	draw_colored_polygon(PackedVector2Array([
		hem_back, hem_front, Vector2(-back * 4.0, -12.0 + bob), Vector2(back * 4.0, -12.0 + bob)]), robe)
	draw_line(Vector2(-back * 2.0, -11.0 + bob), Vector2(-back * 4.0, -2.0), light, 1.0)
	draw_line(hem_back + Vector2(0, -1.5), hem_front + Vector2(0, -1.5), p.trim_color, 2.0)
	draw_rect(Rect2(-4, -8 + bob, 8, 1), p.trim_color)

	# Head, blinking eye and beard
	draw_rect(Rect2(-3, -18 + bob, 6, 6), SKIN)
	var eye_x := 1.0 if f > 0.0 else -2.0
	if _blink > 0.0:
		draw_rect(Rect2(eye_x - 0.5, -15 + bob, 2, 1), EYE)
	else:
		draw_rect(Rect2(eye_x, -16 + bob, 1, 2), EYE)
	draw_rect(Rect2(-3, -13 + bob, 6, 2), BEARD)
	draw_rect(Rect2(-1.0 + back * 0.5 + sin(_t * 2.0) * 0.4, -11 + bob, 2, 1.5), BEARD)

	# Hat: tip sways, trails behind movement and lifts while falling
	var hat_lift := -1.5 if not grounded and p.velocity.y > 60.0 else 0.0
	var hat_y := -19.0 + bob + hat_lift
	var tip := Vector2(-3.0 * f + sin(_t * 1.8) * 0.8 - clampf(p.velocity.x / Tuning.PLAYER_SPEED, -1.0, 1.0) * 1.5, -29.0 + bob + hat_lift)
	draw_rect(Rect2(-6, hat_y, 12, 2), dark)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, hat_y), Vector2(4, hat_y), tip]), robe)
	var star := Vector2(0, hat_y).lerp(tip, 0.45)
	var twinkle := 1.0 + 0.5 * absf(sin(_t * 3.0))
	draw_rect(Rect2(star - Vector2(twinkle, twinkle) / 2.0, Vector2(twinkle, twinkle)), p.trim_color)

	# Arm and wand: drawn unscaled so the tip matches Player.wand_tip() exactly
	var shoulder := _body(Vector2(2.5 * f, -10.0 + bob), offset)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var tip_pos := p.wand_tip(dir) - p.global_position + offset
	var hand := tip_pos - dir * Player.WAND_LENGTH
	draw_line(shoulder, hand, robe, 2.0)
	draw_rect(Rect2(hand - Vector2(1, 1), Vector2(2, 2)), SKIN)
	draw_line(hand, tip_pos, WAND, 2.0)
	var power := _aim_power() if p.aiming else 0.0
	var pulse := 0.4 * sin(_t * 5.0)
	var glow_r := 2.0 + pulse + power * 3.5
	draw_circle(tip_pos, glow_r + 1.5, Color(p.orb_color, 0.25 + power * 0.25))
	draw_circle(tip_pos, glow_r * 0.6, Color(p.orb_color, 0.8))
	draw_circle(tip_pos, 1.2, Color.WHITE)
	if _cast_flash > 0.0:
		var k := 1.0 - _cast_flash / 0.12
		draw_arc(tip_pos, 3.0 + k * 9.0, 0.0, TAU, 16, Color(1, 1, 1, 1.0 - k), 2.0)

	if p.show_marker:
		var y := -36.0 + sin(_t * 4.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-3, y), Vector2(3, y), Vector2(0, y + 4)]), UiKit.GOLD)
