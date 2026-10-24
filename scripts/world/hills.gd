class_name Hills
extends Node2D
## Rolling hill silhouette for a parallax layer.

var color := Color.DARK_GREEN
var span := 2000
var base_y := 368
var amplitude := 100.0
var seed_value := 1


func _draw() -> void:
	var points := PackedVector2Array()
	points.append(Vector2(-400, base_y + 400))
	var x := -400
	while x <= span:
		var t := float(x) / 160.0 + seed_value
		var y := base_y - amplitude * (0.55 + 0.25 * sin(t) + 0.15 * sin(t * 2.3 + 1.7))
		points.append(Vector2(x, roundf(y)))
		x += 16
	points.append(Vector2(span, base_y + 400))
	draw_colored_polygon(points, color)
