class_name Checkpoint
extends Area2D
## Crystal on a pole. Touching it moves the wizard's respawn point here.

signal activated(checkpoint: Checkpoint)

var active := false
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = OrbPhysics.MASK_PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 32)
	shape.shape = rect
	shape.position = Vector2(0, -16)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not active:
		active = true
		Sfx.play("checkpoint")
		activated.emit(self)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-1, -22, 2, 22), Color("8a8aa0"))
	draw_rect(Rect2(-4, -2, 8, 2), Color("5c5c70"))
	var y := -26.0 + (sin(_t * 3.0) * 1.5 if active else 0.0)
	var c := Color("5fe0ff") if active else Color("707088")
	if active:
		draw_circle(Vector2(0, y), 8.0, Color(c, 0.25))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, y - 6), Vector2(4, y), Vector2(0, y + 6), Vector2(-4, y)]), c)
