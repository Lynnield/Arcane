class_name Enemy
extends CharacterBody2D
## Shared enemy behaviour: health, line-of-sight checks and lobbing magic orbs
## with the same projectile rules the wizard uses. Origin is at the feet.

signal defeated(enemy: Enemy)

const ORB_SCENE := preload("res://scenes/magic_orb.tscn")

## "slime", "dummy", "goblin" or "golem" (visual only).
@export var style := "slime"
@export var max_health := Tuning.STATIONARY_HEALTH
@export var can_shoot := true
@export var fire_cooldown := Tuning.STATIONARY_COOLDOWN
@export var sight := Tuning.ENEMY_SIGHT
@export var orb_speed := Tuning.ENEMY_ORB_SPEED
@export var body_size := Vector2(14, 16)
@export var body_color := Color("9b59d0")

var health := 0
var target: Player
var dead := false
var facing := -1

var _cooldown := 0.0
var _flash := 0.0
var _anim := 0.0
var _exclude: Array[RID] = []


func _ready() -> void:
	health = max_health
	collision_layer = OrbPhysics.MASK_ENEMY
	collision_mask = OrbPhysics.MASK_WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = body_size
	shape.shape = rect
	shape.position = Vector2(0, -body_size.y / 2.0)
	add_child(shape)
	_exclude.append(get_rid())
	_cooldown = randf_range(1.0, fire_cooldown + 1.0)


func _physics_process(delta: float) -> void:
	if dead:
		return
	_anim += delta
	_flash = maxf(_flash - delta, 0.0)
	velocity.y = minf(velocity.y + Tuning.PLAYER_GRAVITY * delta, Tuning.MAX_FALL_SPEED)
	_move(delta)
	move_and_slide()
	if can_shoot and is_instance_valid(target) and target.health > 0:
		_cooldown -= delta
		if _cooldown <= 0.0:
			# Retry soon when no clear shot exists.
			_cooldown = fire_cooldown if _try_shoot() else 0.4
	queue_redraw()


## Overridden by subclasses. Stationary by default.
func _move(_delta: float) -> void:
	velocity.x = 0.0


func eye_position() -> Vector2:
	return global_position + Vector2(0, -body_size.y * 0.65)


func _try_shoot() -> bool:
	var from := eye_position()
	var to := target.global_position + Vector2(0, -10)
	if from.distance_to(to) > sight:
		return false
	var space := get_world_2d().direct_space_state
	for high_arc in [false, true]:
		var vel := OrbPhysics.solve_launch(from, to, orb_speed, high_arc)
		if vel == Vector2.ZERO:
			continue
		var path := OrbPhysics.simulate(space, from, vel, OrbPhysics.MASK_WORLD | OrbPhysics.MASK_PLAYER, _exclude, 2.5)
		if path[path.size() - 1].distance_to(to) < 18.0:
			var orb := ORB_SCENE.instantiate() as MagicOrb
			orb.setup(from, vel, OrbPhysics.MASK_WORLD | OrbPhysics.MASK_PLAYER, _exclude, Tuning.ENEMY_ORB_DAMAGE, self, Color("ff6b4a"))
			get_parent().add_child(orb)
			Sfx.play("enemy_shoot")
			return true
	return false


func take_damage(amount: int, _source: Node = null) -> void:
	if dead:
		return
	health -= amount
	_flash = 0.12
	if health <= 0:
		_die()


func _die() -> void:
	dead = true
	set_deferred("collision_layer", 0)
	Sfx.play("defeat")
	defeated.emit(self)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2(1.4, 0.1), 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)


func _look_dir() -> float:
	if is_instance_valid(target):
		return 1.0 if target.global_position.x > global_position.x else -1.0
	return float(facing)


func _draw() -> void:
	var c := Color.WHITE if _flash > 0.0 else body_color
	var w := body_size.x
	var h := body_size.y
	match style:
		"dummy":
			draw_rect(Rect2(-1, -16, 2, 16), Color("8a5a32"))
			draw_rect(Rect2(-5, -2, 10, 2), Color("8a5a32"))
			var center := Vector2(0, -21)
			draw_circle(center, 7.0, Color.WHITE if _flash > 0.0 else Color("d64545"))
			draw_circle(center, 5.0, Color("f4efe6"))
			draw_circle(center, 3.0, Color("d64545"))
			draw_circle(center, 1.0, Color("f4efe6"))
		"goblin":
			var step := 1.0 if int(_anim * 8.0) % 2 == 0 else 0.0
			draw_rect(Rect2(-4, -3 + step, 3, 3), c.darkened(0.4))
			draw_rect(Rect2(1, -3 - step + 1.0, 3, 3), c.darkened(0.4))
			draw_rect(Rect2(-w / 2, -h + 4, w, h - 6), c)
			draw_colored_polygon(PackedVector2Array([Vector2(-w / 2, -h + 6), Vector2(-w / 2 - 4, -h + 1), Vector2(-w / 2 + 2, -h + 4)]), c)
			draw_colored_polygon(PackedVector2Array([Vector2(w / 2, -h + 6), Vector2(w / 2 + 4, -h + 1), Vector2(w / 2 - 2, -h + 4)]), c)
			draw_rect(Rect2(-w / 2, -6, w, 2), Color("6b4a2a"))
			var spear_x := float(facing) * (w / 2 + 2)
			draw_line(Vector2(spear_x, -2), Vector2(spear_x, -h - 4), Color("a07040"), 1.0)
			draw_colored_polygon(PackedVector2Array([Vector2(spear_x - 2, -h - 4), Vector2(spear_x + 2, -h - 4), Vector2(spear_x, -h - 8)]), Color("d0d0e0"))
			_draw_eyes(Vector2(0, -h + 8), Color("ffd84a"))
		"golem":
			var stone := c
			draw_rect(Rect2(-w / 2, -h + 6, w, h - 10), stone)
			draw_rect(Rect2(-w / 2 + 2, -4, 7, 4), stone.darkened(0.3))
			draw_rect(Rect2(w / 2 - 9, -4, 7, 4), stone.darkened(0.3))
			draw_rect(Rect2(-8, -h, 16, 8), stone.lightened(0.1))
			draw_rect(Rect2(-w / 2 - 4, -h + 8, 5, 12), stone.darkened(0.2))
			draw_rect(Rect2(w / 2 - 1, -h + 8, 5, 12), stone.darkened(0.2))
			var crystal := Color("5fe0ff")
			draw_colored_polygon(PackedVector2Array([Vector2(-w / 2 + 1, -h + 6), Vector2(-w / 2 + 5, -h - 2), Vector2(-w / 2 + 8, -h + 6)]), crystal)
			draw_colored_polygon(PackedVector2Array([Vector2(w / 2 - 8, -h + 6), Vector2(w / 2 - 4, -h - 3), Vector2(w / 2 - 1, -h + 6)]), crystal)
			draw_rect(Rect2(-3, -h + 12, 6, 6), crystal)
			_draw_eyes(Vector2(0, -h + 4), crystal)
		_:
			draw_rect(Rect2(-w / 2, -h + 7, w, h - 7), c)
			draw_circle(Vector2(0, -h + 7), w / 2, c)
			draw_rect(Rect2(-w / 2, -2, w, 2), c.darkened(0.3))
			var gem_y := -h - 1 + sin(_anim * 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(0, gem_y - 4), Vector2(3, gem_y), Vector2(0, gem_y + 3), Vector2(-3, gem_y)]), Color("ff9ae0"))
			_draw_eyes(Vector2(0, -h + 8), Color.WHITE)

	if health < max_health and not dead:
		var bar_w := maxf(w, 16.0)
		var ratio := clampf(float(health) / max_health, 0.0, 1.0)
		draw_rect(Rect2(-bar_w / 2, -h - 12, bar_w, 3), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-bar_w / 2, -h - 12, bar_w * ratio, 3), Color("ff5a5a"))


func _draw_eyes(center: Vector2, eye_color: Color) -> void:
	var look := _look_dir()
	for side in [-1.0, 1.0]:
		var p: Vector2 = center + Vector2(side * 3.0 - 1.0, -1.0)
		draw_rect(Rect2(p, Vector2(3, 3)), eye_color)
		draw_rect(Rect2(p + Vector2(1.0 + look * 0.5, 1), Vector2(1, 2)), Color("1b1530"))
