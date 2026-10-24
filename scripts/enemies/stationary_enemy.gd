class_name StationaryEnemy
extends Enemy
## Holds a fixed position and fires at the wizard when it has a clear arc.


func _move(_delta: float) -> void:
	velocity.x = 0.0
	facing = int(_look_dir())
