class_name SkyBackground
extends Control
## Full-screen banded gradient sky with stars or a sun. Used by levels and menus.

var palette: Dictionary = LevelData.palette("menu")
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if palette["stars"]:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var top: Color = palette["sky_top"]
	var bottom: Color = palette["sky_bottom"]
	var bands := 14
	var band_h := ceilf(size.y / bands)
	for i in bands:
		draw_rect(Rect2(0, i * band_h, size.x, band_h + 1), top.lerp(bottom, float(i) / (bands - 1)))
	if palette["stars"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 70:
			var p := Vector2(rng.randf() * size.x, rng.randf() * size.y * 0.7)
			var twinkle := 0.5 + 0.5 * sin(_t * 2.0 + i)
			draw_rect(Rect2(p.floor(), Vector2.ONE * (2 if i % 9 == 0 else 1)), Color(1, 1, 1, 0.3 + twinkle * 0.6))
		draw_circle(Vector2(size.x * 0.8, size.y * 0.2), 14.0, Color(1, 1, 0.92, 0.9))
		draw_circle(Vector2(size.x * 0.8 + 5, size.y * 0.2 - 3), 12.0, top.lerp(bottom, 0.15))
	else:
		draw_circle(Vector2(size.x * 0.78, size.y * 0.22), 30.0, Color(1, 1, 0.9, 0.25))
		draw_circle(Vector2(size.x * 0.78, size.y * 0.22), 22.0, Color(1, 1, 0.92, 0.9))
