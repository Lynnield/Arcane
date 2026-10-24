class_name ExitPortal
extends Area2D
## Level exit. Stays sealed until the level's objectives are complete.

signal reached
signal touched_while_locked

var locked := true
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = OrbPhysics.MASK_PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 30)
	shape.shape = rect
	shape.position = Vector2(0, -15)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func unlock() -> void:
	if not locked:
		return
	locked = false
	Sfx.play("unlock")
	_burst()
	# The wizard may already be standing in the portal.
	for body in get_overlapping_bodies():
		if body is Player:
			_emit_reached.call_deferred()


func _burst() -> void:
	var particles := CPUParticles2D.new()
	particles.position = Vector2(0, -17)
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 32
	particles.lifetime = 0.8
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 110.0
	particles.gravity = Vector2(0, 120)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 3.0
	particles.color = Color("5fe0ff")
	particles.finished.connect(particles.queue_free)
	add_child(particles)
	particles.emitting = true


func _emit_reached() -> void:
	reached.emit()


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if locked:
		touched_while_locked.emit()
	else:
		reached.emit()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var stone := Color("8a8aa0")
	draw_rect(Rect2(-14, -36, 4, 36), stone)
	draw_rect(Rect2(10, -36, 4, 36), stone)
	draw_rect(Rect2(-14, -40, 28, 5), stone.lightened(0.15))
	var inner := Color("6a4bc4") if locked else Color("5fe0ff")
	draw_rect(Rect2(-10, -35, 20, 35), Color(inner, 0.25 if locked else 0.45))
	if locked:
		draw_rect(Rect2(-3, -20, 6, 6), Color("f2c14e"))
		draw_rect(Rect2(-2, -23, 4, 3), Color("f2c14e"), false, 1.0)
		return
	for i in 6:
		var a := _t * 3.0 + i * TAU / 6.0
		var p := Vector2(cos(a) * 6.0, -17.0 + sin(a) * 11.0)
		draw_rect(Rect2(p.floor(), Vector2(2, 2)), Color.WHITE)
