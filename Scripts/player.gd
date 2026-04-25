extends RigidBody2D

var thrust := 50.0
var max_speed := 25.0
var water_drag := 0.90
var auto_level_speed := 0.4
var idle_drift_force := 18.0
var idle_drift_interval_min := 1.20
var idle_drift_interval_max := 3.20
var idle_drift_vertical_bias := 0.65
var idle_drift_torque := 10.0
var idle_drift_sway_speed := 1.4

var current_thrust_multiplier := 0.0
var current_vertical_multiplier := 0.0
var command_locked := false
var sonar_enabled := true
var controls_online := false
var generator_online := false
var cooling_online := false
var reactor_online := false
var diagnostics_complete := false
var light_energy_by_name: Dictionary = {}
var battery_charge := 0.18
var last_command_key: Key = KEY_NONE
var movement: SubmarineMovement

@onready var sonar: Node2D = $sonar
@onready var command_player: CommandPlayer = $command_player
@onready var motor_player: MotorPlayer = $motor_player
@onready var fog: ColorRect = $fog
@onready var light_front: PointLight2D = $light_front
@onready var light_boat: PointLight2D = $light_boat
@onready var light_position: PointLight2D = $light_position
@onready var light_keel: PointLight2D = $light_keel
@onready var light_turret: PointLight2D = $light_turret


func _ready():
	randomize()
	if command_player == null:
		push_warning("Player expects child node 'command_player' with CommandPlayer script attached.")
		return

	if motor_player == null:
		push_warning("Player expects child node 'motor_player' with MotorPlayer script attached.")
		return

	movement = SubmarineMovement.new()
	movement.configure(
		thrust,
		max_speed,
		water_drag,
		idle_drift_force,
		idle_drift_interval_min,
		idle_drift_interval_max,
		idle_drift_vertical_bias,
		idle_drift_torque,
		idle_drift_sway_speed
	)

	command_player.command_pending_changed.connect(_on_command_pending_changed)
	command_player.command_resolved.connect(_on_command_resolved)
	command_player.sonar_toggle_requested.connect(_on_sonar_toggle_requested)

	_cache_light_energies()
	set_startup_state(false, false, false, false)


func _unhandled_input(event):
	if not controls_online or command_locked:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		_issue_control_command(event.keycode)


func _physics_process(delta):
	_update_panel_telemetry(delta)

	if not controls_online:
		current_thrust_multiplier = 0.0
		current_vertical_multiplier = 0.0
		linear_velocity *= water_drag
		angular_velocity *= water_drag
		return

	_handle_scan_input(delta)

	if not command_locked and Input.is_key_pressed(KEY_ENTER):
		movement.auto_level(self, delta, auto_level_speed)

	movement.apply_movement(self, delta, current_thrust_multiplier, current_vertical_multiplier)


func _handle_scan_input(delta: float) -> void:
	if sonar == null:
		return

	if not sonar_enabled:
		return

	if sonar.has_method("rotate_scan"):
		sonar.call("rotate_scan", delta)

	if not command_locked and Input.is_key_pressed(KEY_SPACE) and sonar.has_method("scan"):
		sonar.call("scan")


func _on_command_pending_changed(is_pending: bool) -> void:
	command_locked = is_pending


func _on_command_resolved(multiplier: float, vertical_multiplier: float, motor_stream: int) -> void:
	if not is_nan(multiplier):
		current_thrust_multiplier = multiplier
	if not is_nan(vertical_multiplier):
		current_vertical_multiplier = vertical_multiplier
	if motor_stream >= 0:
		motor_player.play_stream(motor_stream)


func _on_sonar_toggle_requested() -> void:
	sonar_enabled = not sonar_enabled
	_refresh_sonar_state()


func issue_panel_command(keycode: Key) -> bool:
	if not controls_online:
		return false

	if command_player == null:
		return false

	return _issue_control_command(keycode)


func set_startup_state(new_generator_online: bool, new_cooling_online: bool, new_reactor_online: bool, new_diagnostics_complete: bool) -> void:
	generator_online = new_generator_online
	cooling_online = new_cooling_online
	reactor_online = new_reactor_online
	diagnostics_complete = new_diagnostics_complete
	controls_online = generator_online and cooling_online and reactor_online and diagnostics_complete

	if not controls_online:
		current_thrust_multiplier = 0.0
		current_vertical_multiplier = 0.0
		if motor_player:
			motor_player.play_stream(0)

	_apply_power_visuals()
	_refresh_sonar_state()


func _refresh_sonar_state() -> void:
	if sonar == null:
		return

	var sonar_active := controls_online and sonar_enabled
	sonar.visible = sonar_active
	sonar.set_process(sonar_active)


func _cache_light_energies() -> void:
	for light in _get_power_lights():
		if light == null:
			continue
		light_energy_by_name[light.name] = light.energy


func _apply_power_visuals() -> void:
	for light in _get_power_lights():
		if light == null:
			continue
		light.energy = 0.0

	if not generator_online:
		if fog:
			fog.color = Color(0, 0, 0, 1)
		return

	if fog:
		fog.color = Color(0.01, 0.02, 0.03, 1)

	if light_position:
		light_position.energy = float(light_energy_by_name.get(light_position.name, light_position.energy)) * 0.45

	if not reactor_online:
		return

	for light in _get_power_lights():
		if light == null:
			continue
		light.energy = float(light_energy_by_name.get(light.name, light.energy))


func _get_power_lights() -> Array[PointLight2D]:
	return [light_front, light_boat, light_position, light_keel, light_turret]


func get_panel_state() -> Dictionary:
	var thrust_level: float = clamp(abs(current_thrust_multiplier) / 1.15, 0.0, 1.0)
	var vertical_level: float = clamp(abs(current_vertical_multiplier) / 0.65, 0.0, 1.0)
	var speed_ratio: float = clamp(linear_velocity.length() / max_speed, 0.0, 1.0)
	var current_draw: float = 0.03

	if generator_online:
		current_draw += 0.12
	if cooling_online:
		current_draw += 0.1
	if reactor_online:
		current_draw += 0.18
	if controls_online and sonar_enabled:
		current_draw += 0.1
	if command_locked:
		current_draw += 0.08

	current_draw += thrust_level * 0.28
	current_draw += vertical_level * 0.11
	current_draw += speed_ratio * 0.1

	return {
		"generator_online": generator_online,
		"cooling_online": cooling_online,
		"reactor_online": reactor_online,
		"diagnostics_complete": diagnostics_complete,
		"controls_online": controls_online,
		"sonar_online": controls_online and sonar_enabled,
		"command_locked": command_locked,
		"battery_charge": battery_charge,
		"current_draw": clamp(current_draw, 0.0, 1.0),
		"thrust_level": thrust_level,
		"vertical_level": vertical_level,
		"speed_ratio": speed_ratio,
		"active_thrust_key": _get_active_thrust_key(),
		"active_depth_key": _get_active_depth_key(),
		"last_command_key": last_command_key
	}


func _update_panel_telemetry(delta: float) -> void:
	var charge_delta: float = -0.004

	if generator_online:
		charge_delta += 0.01
	if cooling_online:
		charge_delta += 0.008
	if reactor_online:
		charge_delta += 0.022
	if controls_online and sonar_enabled:
		charge_delta -= 0.005
	if abs(current_thrust_multiplier) > 0.0:
		charge_delta -= 0.01 * abs(current_thrust_multiplier)
	if abs(current_vertical_multiplier) > 0.0:
		charge_delta -= 0.004 * abs(current_vertical_multiplier)

	battery_charge = clamp(battery_charge + charge_delta * delta, 0.0, 1.0)


func _issue_control_command(keycode: Key) -> bool:
	var accepted := command_player.issue_key_command(keycode)
	if accepted:
		last_command_key = keycode
	return accepted


func _get_active_thrust_key() -> Key:
	if is_equal_approx(current_thrust_multiplier, 1.0 / 3.0):
		return KEY_1
	if is_equal_approx(current_thrust_multiplier, 2.0 / 3.0):
		return KEY_2
	if is_equal_approx(current_thrust_multiplier, 1.0):
		return KEY_3
	if is_equal_approx(current_thrust_multiplier, 1.15):
		return KEY_4
	if is_equal_approx(current_thrust_multiplier, -2.0 / 3.0):
		return KEY_R
	if is_equal_approx(current_thrust_multiplier, 0.0):
		return KEY_S
	return KEY_NONE


func _get_active_depth_key() -> Key:
	if is_equal_approx(current_vertical_multiplier, -0.65):
		return KEY_X
	if is_equal_approx(current_vertical_multiplier, 0.65):
		return KEY_Y
	if is_equal_approx(current_vertical_multiplier, 0.0):
		return KEY_V
	return KEY_NONE
