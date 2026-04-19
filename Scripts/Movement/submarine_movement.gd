extends RefCounted
class_name SubmarineMovement

var thrust := 50.0
var max_speed := 25.0
var water_drag := 0.90
var idle_drift_force := 3.0
var idle_drift_interval_min := 0.35
var idle_drift_interval_max := 1.20

var idle_drift_direction := Vector2.ZERO
var idle_drift_timer := 0.0


func configure(
	new_thrust: float,
	new_max_speed: float,
	new_water_drag: float,
	new_idle_drift_force: float,
	new_idle_drift_interval_min: float,
	new_idle_drift_interval_max: float
) -> void:
	thrust = new_thrust
	max_speed = new_max_speed
	water_drag = new_water_drag
	idle_drift_force = new_idle_drift_force
	idle_drift_interval_min = new_idle_drift_interval_min
	idle_drift_interval_max = new_idle_drift_interval_max
	_pick_new_idle_drift()


func auto_level(body: RigidBody2D, delta: float, auto_level_speed: float) -> void:
	body.rotation = lerp_angle(body.rotation, 0.0, auto_level_speed * delta)
	if abs(body.rotation) < 0.01:
		body.rotation = 0.0


func apply_movement(body: RigidBody2D, delta: float, thrust_multiplier: float) -> void:
	var direction := Vector2.RIGHT.rotated(body.rotation)
	if thrust_multiplier != 0.0:
		body.apply_central_force(direction * thrust * thrust_multiplier)
	else:
		idle_drift_timer -= delta
		if idle_drift_timer <= 0.0:
			_pick_new_idle_drift()
		body.apply_central_force(idle_drift_direction * idle_drift_force)

	if body.linear_velocity.length() > max_speed:
		body.linear_velocity = body.linear_velocity.normalized() * max_speed

	body.linear_velocity *= water_drag


func _pick_new_idle_drift() -> void:
	idle_drift_direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	idle_drift_timer = randf_range(idle_drift_interval_min, idle_drift_interval_max)
