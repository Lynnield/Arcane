class_name ScreenShake
extends RefCounted
## Short camera shake used when the player takes a hit.


static func shake(camera: Camera2D, strength: float = 4.0, duration: float = 0.2) -> void:
	if not is_instance_valid(camera):
		return
	var base := camera.offset
	var tween := camera.create_tween()
	var steps := 6
	for i in steps:
		var falloff := 1.0 - float(i) / steps
		var jitter := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * falloff
		tween.tween_property(camera, "offset", base + jitter, duration / steps)
	tween.tween_property(camera, "offset", base, duration / steps)