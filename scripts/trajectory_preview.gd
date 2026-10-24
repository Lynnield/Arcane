class_name TrajectoryPreview
extends Node2D
## Dotted aim line. Uses OrbPhysics.simulate, the same stepping as MagicOrb.

var _points := PackedVector2Array()


func _ready() -> void:
	top_level = true
	position = Vector2.ZERO
	z_index = 20


func show_path(origin: Vector2, velocity: Vector2, mask: int, exclude: Array[RID]) -> void:
	_points = OrbPhysics.simulate(get_world_2d().direct_space_state, origin, velocity, mask, exclude, Tuning.PREVIEW_TIME)
	queue_redraw()


func clear() -> void:
	if _points.is_empty():
		return
	_points.clear()
	queue_redraw()


func _draw() -> void:
	var n := _points.size()
	if n == 0:
		return
	for i in range(0, n, 3):
		var a := 1.0 - float(i) / n * 0.7
		draw_circle(_points[i], 1.5, Color(1, 1, 1, a))
	draw_arc(_points[n - 1], 3.0, 0.0, TAU, 12, Color(1, 0.9, 0.4, 0.9), 1.0)
