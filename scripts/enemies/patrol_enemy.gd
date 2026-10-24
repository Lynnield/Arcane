class_name PatrolEnemy
extends Enemy
## Walks back and forth along its platform, turning at walls and ledges.
## The boss uses this with more health and an occasional hop.

@export var speed := Tuning.PATROL_SPEED
@export var hops := false

var _hop_timer := 3.0


func _move(delta: float) -> void:
	if is_on_wall() and get_wall_normal().x * facing < 0.0:
		facing = -facing
	elif is_on_floor() and not _ground_ahead():
		facing = -facing
	velocity.x = facing * speed
	if hops and is_on_floor():
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			_hop_timer = randf_range(2.5, 4.5)
			velocity.y = -260.0


func _ground_ahead() -> bool:
	var front := global_position + Vector2(facing * (body_size.x / 2.0 + 2.0), -2.0)
	var query := PhysicsRayQueryParameters2D.create(front, front + Vector2(0, 12), OrbPhysics.MASK_WORLD)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()
