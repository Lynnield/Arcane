class_name OrbPhysics
extends RefCounted
## Shared projectile rules. MagicOrb and TrajectoryPreview step with the same
## functions and collision mask, so the dotted preview follows the real path.

const MASK_WORLD := 1
const MASK_PLAYER := 2
const MASK_ENEMY := 4


## drag = finger position minus where the drag started. The orb flies the
## opposite way. Speed scales with pull distance; damage does not.
static func launch_velocity(drag: Vector2) -> Vector2:
	var length := drag.length()
	if length < Tuning.MIN_PULL:
		return Vector2.ZERO
	var t := clampf((length - Tuning.MIN_PULL) / (Tuning.MAX_PULL - Tuning.MIN_PULL), 0.0, 1.0)
	return -drag.normalized() * lerpf(Tuning.ORB_MIN_SPEED, Tuning.ORB_MAX_SPEED, t)


static func next_velocity(velocity: Vector2, delta: float) -> Vector2:
	return velocity + Vector2(0.0, Tuning.ORB_GRAVITY * delta)


static func cast(space: PhysicsDirectSpaceState2D, from: Vector2, to: Vector2, mask: int, exclude: Array[RID]) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, mask, exclude)
	# An orb spawned inside a wall is blocked instead of passing through it.
	query.hit_from_inside = true
	return space.intersect_ray(query)


## Returns the flight path; the last point is the first collision, if any.
static func simulate(space: PhysicsDirectSpaceState2D, origin: Vector2, velocity: Vector2, mask: int, exclude: Array[RID], max_time: float) -> PackedVector2Array:
	var points := PackedVector2Array([origin])
	var delta := 1.0 / Engine.physics_ticks_per_second
	var pos := origin
	var vel := velocity
	var t := 0.0
	while t < max_time:
		var next_vel := next_velocity(vel, delta)
		var next_pos := pos + next_vel * delta
		var hit := cast(space, pos, next_pos, mask, exclude)
		if not hit.is_empty():
			points.append(hit.position)
			break
		pos = next_pos
		vel = next_vel
		t += delta
		points.append(pos)
	return points


## Launch velocity that lands on `to` at the given speed, or ZERO if out of range.
static func solve_launch(from: Vector2, to: Vector2, speed: float, high_arc: bool) -> Vector2:
	var d := to - from
	var x := absf(d.x)
	var y := -d.y
	var g := Tuning.ORB_GRAVITY
	var v2 := speed * speed
	var disc := v2 * v2 - g * (g * x * x + 2.0 * y * v2)
	if disc < 0.0:
		return Vector2.ZERO
	if x < 1.0:
		return Vector2(0.0, -speed if y > 0.0 else speed)
	var root := sqrt(disc)
	var angle := atan((v2 + root) / (g * x)) if high_arc else atan((v2 - root) / (g * x))
	return Vector2(cos(angle) * speed * signf(d.x), -sin(angle) * speed)
