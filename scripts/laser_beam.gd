class_name LaserBeam
extends Node2D
## Brief glowing beam drawn from one point to another, then fades out.

const LIFE := 0.22

var from := Vector2.ZERO
var to := Vector2.ZERO
var color := Color("ff3b5c")
var _t := 0.0


static func spawn(parent: Node, start: Vector2, end: Vector2, tint: Color) -> void:
	var beam := LaserBeam.new()
	beam.from = start
	beam.to = end
	beam.color = tint
	beam.z_index = 12
	parent.add_child(beam)


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _t / LIFE
	draw_line(from, to, Color(color, 0.35 * k), 7.0 * k + 1.0)
	draw_line(from, to, Color(color, 0.9 * k), 3.0 * k + 0.5)
	draw_line(from, to, Color(1, 1, 1, k), 1.0)
	draw_circle(to, 6.0 * k + 1.0, Color(color, 0.6 * k))
	draw_circle(from, 4.0 * k + 1.0, Color(1, 1, 1, 0.8 * k))
