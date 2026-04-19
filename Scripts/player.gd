extends RigidBody2D

@export var thrust := 50.0
@export var max_speed := 25.0
@export var water_drag := 0.90
@export var auto_level_speed := 0.4
@export var idle_drift_force := 3.0
@export var idle_drift_interval_min := 0.35
@export var idle_drift_interval_max := 1.20

var current_thrust_multiplier := 0.0
var command_locked := false
var sonar_enabled := true
var movement: SubmarineMovement

@onready var sonar: Node2D = $sonar
@onready var command_player: CommandPlayer = $command_player
@onready var motor_player: MotorPlayer = $motor_player


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
		idle_drift_interval_max
	)

	command_player.command_pending_changed.connect(_on_command_pending_changed)
	command_player.command_resolved.connect(_on_command_resolved)
	command_player.sonar_toggle_requested.connect(_on_sonar_toggle_requested)

	_set_sonar_enabled(sonar_enabled)


func _unhandled_input(event):
	if command_locked:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		command_player.issue_key_command(event.keycode)


func _physics_process(delta):
	_handle_scan_input(delta)

	if not command_locked and Input.is_key_pressed(KEY_ENTER):
		movement.auto_level(self, delta, auto_level_speed)

	movement.apply_movement(self, delta, current_thrust_multiplier)


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


func _on_command_resolved(multiplier: float, motor_stream: int) -> void:
	current_thrust_multiplier = multiplier
	motor_player.play_stream(motor_stream)


func _on_sonar_toggle_requested() -> void:
	sonar_enabled = not sonar_enabled
	_set_sonar_enabled(sonar_enabled)


func _set_sonar_enabled(enabled: bool) -> void:
	if sonar == null:
		return

	sonar.visible = enabled
	sonar.set_process(enabled)
