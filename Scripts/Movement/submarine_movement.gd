extends RefCounted
class_name SubmarineMovement

var thrust := 50.0
var vertical_thrust := 34.0
var max_speed := 25.0
var water_drag := 0.90
var depth_pitch_angle := deg_to_rad(5.0)
var depth_pitch_speed := 0.55
var idle_drift_force := 18.0
var idle_drift_interval_min := 1.20
var idle_drift_interval_max := 3.20
var idle_drift_vertical_bias := 0.65
var idle_drift_torque := 10.0
var idle_drift_sway_speed := 1.4

var idle_drift_direction := Vector2.ZERO
var idle_drift_target_direction := Vector2.ZERO
var idle_drift_timer := 0.0
var idle_drift_phase := 0.0


func configure(
	new_thrust: float,
	new_max_speed: float,
	new_water_drag: float,
	new_idle_drift_force: float,
	new_idle_drift_interval_min: float,
	new_idle_drift_interval_max: float,
	new_idle_drift_vertical_bias: float,
	new_idle_drift_torque: float,
	new_idle_drift_sway_speed: float
) -> void:
	thrust = new_thrust
	max_speed = new_max_speed
	water_drag = new_water_drag
	idle_drift_force = new_idle_drift_force
	idle_drift_interval_min = new_idle_drift_interval_min
	idle_drift_interval_max = new_idle_drift_interval_max
	idle_drift_vertical_bias = new_idle_drift_vertical_bias
	idle_drift_torque = new_idle_drift_torque
	idle_drift_sway_speed = new_idle_drift_sway_speed
	_pick_new_idle_drift()


func auto_level(body: RigidBody2D, delta: float, auto_level_speed: float) -> void:
	body.rotation = lerp_angle(body.rotation, 0.0, auto_level_speed * delta)
	if abs(body.rotation) < 0.01:
		body.rotation = 0.0


func apply_movement(body: RigidBody2D, delta: float, thrust_multiplier: float, vertical_multiplier: float = 0.0) -> void:
	var direction := Vector2.RIGHT.rotated(body.rotation)
	if thrust_multiplier != 0.0 or vertical_multiplier != 0.0:
		body.apply_central_force(direction * thrust * thrust_multiplier)
		body.apply_central_force(Vector2.DOWN * vertical_thrust * vertical_multiplier)
	else:
		idle_drift_timer -= delta
		idle_drift_phase += delta * idle_drift_sway_speed
		if idle_drift_timer <= 0.0:
			_pick_new_idle_drift()

		idle_drift_direction = idle_drift_direction.lerp(idle_drift_target_direction, 1.8 * delta).normalized()
		var sway := Vector2.UP.rotated(body.rotation) * sin(idle_drift_phase) * idle_drift_force * 0.35
		body.apply_central_force(idle_drift_direction * idle_drift_force + sway)
		body.apply_torque(sin(idle_drift_phase * 0.73) * idle_drift_torque)

	var target_rotation := depth_pitch_angle * signf(vertical_multiplier)
	body.rotation = lerp_angle(body.rotation, target_rotation, depth_pitch_speed * delta)

	if body.linear_velocity.length() > max_speed:
		body.linear_velocity = body.linear_velocity.normalized() * max_speed

	body.linear_velocity *= water_drag


func _pick_new_idle_drift() -> void:
	idle_drift_target_direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-idle_drift_vertical_bias, idle_drift_vertical_bias)
	).normalized()
	if idle_drift_direction == Vector2.ZERO:
		idle_drift_direction = idle_drift_target_direction
	idle_drift_timer = randf_range(idle_drift_interval_min, idle_drift_interval_max)
