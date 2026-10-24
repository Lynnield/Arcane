class_name StarRow
extends Control
## Draws 0-3 earned stars out of 3 (drawn, so no font glyph is needed).

var stars := 0:
	set(value):
		stars = clampi(value, 0, 3)
		queue_redraw()
var star_size := 10.0


func _init(earned: int = 0, size_px: float = 10.0) -> void:
	stars = earned
	star_size = size_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(star_size * 2.0 * 3.0 + star_size, star_size * 2.0)


func _draw() -> void:
	var gap := star_size * 2.3
	var start := size.x / 2.0 - gap
	for i in 3:
		var c := Vector2(start + i * gap, size.y / 2.0)
		var points := PackedVector2Array()
		for p in 10:
			var r := star_size if p % 2 == 0 else star_size * 0.45
			var a := -PI / 2.0 + p * PI / 5.0
			points.append(c + Vector2(cos(a), sin(a)) * r)
		var earned := i < stars
		draw_colored_polygon(points, UiKit.GOLD if earned else Color(0.2, 0.17, 0.32, 0.9))
		points.append(points[0])
		draw_polyline(points, Color("120c22"), 1.5)
