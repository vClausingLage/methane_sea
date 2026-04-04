extends RigidBody2D

var thrust := 50.0
var max_speed := 25.0
var water_drag := 0.90
var auto_level_speed := .4
var current_thrust_multiplier := 0.0
var command_locked := false

@export var flank_thrust_multiplier := 1.15
@export var command_delay_min := 0.20
@export var command_delay_max := 0.55
@onready var one_third_sound: AudioStream = preload("res://Assets/Audio/one_third_ahead.mp3")
@onready var two_third_sound: AudioStream = preload("res://Assets/Audio/two_third_ahead.mp3")
@onready var full_forward_sound: AudioStream = preload("res://Assets/Audio/full_forward.mp3")
@onready var flank_sound: AudioStream = preload("res://Assets/Audio/go_flank_speed.mp3")
@onready var reverse_sound: AudioStream = preload("res://Assets/Audio/reverse.mp3")
@onready var stop_sound: AudioStream = preload("res://Assets/Audio/full_stop.mp3")

@onready var sonar = $sonar
@onready var command_audio_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()

func _ready():
	randomize()
	add_child(command_audio_player)

func _unhandled_input(event):
	if command_locked:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_issue_thrust_command(1.0 / 3.0, one_third_sound)
			KEY_2:
				_issue_thrust_command(2.0 / 3.0, two_third_sound)
			KEY_3:
				_issue_thrust_command(1.0, full_forward_sound)
			KEY_4:
				_issue_thrust_command(flank_thrust_multiplier, flank_sound)
			KEY_R:
				_issue_thrust_command(-2.0 / 3.0, reverse_sound)
			KEY_S:
				_issue_thrust_command(0.0, stop_sound)
func _issue_thrust_command(multiplier: float, sound: AudioStream) -> void:
	if command_locked:
		return

	command_locked = true
	_play_command_sound(sound)

	var delay := randf_range(command_delay_min, command_delay_max)
	await get_tree().create_timer(delay).timeout

	current_thrust_multiplier = multiplier
	command_locked = false

func _play_command_sound(sound: AudioStream) -> void:
	if sound == null:
		return

	command_audio_player.stop()
	command_audio_player.stream = sound
	command_audio_player.play()

func _physics_process(delta):
	if not command_locked and Input.is_key_pressed(KEY_ENTER):
		rotation = lerp_angle(rotation, 0.0, auto_level_speed * delta)
		if abs(rotation) < 0.01:
			rotation = 0.0
	if not command_locked and Input.is_key_pressed(KEY_SPACE):
		sonar.scan()

	var direction := Vector2.RIGHT.rotated(rotation)
	if current_thrust_multiplier != 0.0:
		apply_central_force(direction * thrust * current_thrust_multiplier)

	# clamp velocity
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

	# water drag
	linear_velocity *= water_drag
