extends AudioStreamPlayer2D
class_name CommandPlayer

signal command_pending_changed(is_pending: bool)
signal command_resolved(thrust_multiplier: float, motor_stream: int)
signal sonar_toggle_requested

@export var flank_thrust_multiplier := 1.15
@export var command_delay_min := 0.20
@export var command_delay_max := 0.55
var command_locked := false

const COMMAND_CONFIG := {
	KEY_1: {
		"multiplier": 1.0 / 3.0,
		"sound": preload("res://Assets/Audio/Sub/Comms/one_third_ahead.mp3"),
		"motor_stream": 1
	},
	KEY_2: {
		"multiplier": 2.0 / 3.0,
		"sound": preload("res://Assets/Audio/Sub/Comms/two_third_ahead.mp3"),
		"motor_stream": 2
	},
	KEY_3: {
		"multiplier": 1.0,
		"sound": preload("res://Assets/Audio/Sub/Comms/full_forward.mp3"),
		"motor_stream": 3
	},
	KEY_4: {
		"multiplier": 1.15,
		"sound": preload("res://Assets/Audio/Sub/Comms/go_flank_speed.mp3"),
		"motor_stream": 4
	},
	KEY_R: {
		"multiplier": -2.0 / 3.0,
		"sound": preload("res://Assets/Audio/Sub/Comms/reverse.mp3"),
		"motor_stream": 1
	},
	KEY_S: {
		"multiplier": 0.0,
		"sound": preload("res://Assets/Audio/Sub/Comms/full_stop.mp3"),
		"motor_stream": 0
	},
	KEY_I: {
		"type": "sonar_toggle",
		"sound": preload("res://Assets/Audio/Sub/Comms/i_hear_something.mp3")
	}
}


func issue_key_command(keycode: Key) -> bool:
	if command_locked:
		return false

	var command_data: Dictionary = COMMAND_CONFIG.get(keycode, {})
	if command_data.is_empty():
		return false

	if command_data.get("type", "thrust") == "sonar_toggle":
		_issue_sonar_toggle_command(command_data["sound"] as AudioStream)
		return true

	var multiplier := float(command_data["multiplier"])
	if keycode == KEY_4:
		multiplier = flank_thrust_multiplier

	_issue_command(
		multiplier,
		command_data["sound"] as AudioStream,
		int(command_data["motor_stream"])
	)
	return true


func is_command_locked() -> bool:
	return command_locked


func _issue_command(multiplier: float, sound: AudioStream, motor_stream: int) -> void:
	command_locked = true
	command_pending_changed.emit(true)
	_play_command_sound(sound)

	var delay := randf_range(command_delay_min, command_delay_max)
	await get_tree().create_timer(delay).timeout

	command_resolved.emit(multiplier, motor_stream)
	_release_lock()


func _issue_sonar_toggle_command(sound: AudioStream) -> void:
	command_locked = true
	command_pending_changed.emit(true)
	_play_command_sound(sound)

	var delay := randf_range(command_delay_min, command_delay_max)
	await get_tree().create_timer(delay).timeout

	sonar_toggle_requested.emit()
	_release_lock()


func _play_command_sound(sound: AudioStream) -> void:
	if sound == null:
		return

	stop()
	stream = sound
	play()


func _release_lock() -> void:
	command_locked = false
	command_pending_changed.emit(false)
