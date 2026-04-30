extends AudioStreamPlayer2D
class_name CommandPlayer

signal command_pending_changed(is_pending: bool)
signal command_resolved(thrust_multiplier: float, vertical_multiplier: float, motor_stream: int)
signal sonar_toggle_requested
signal voice_line_started(speaker: StringName)
signal voice_line_finished(speaker: StringName)

var command_locked := false
var active_voice_speaker := StringName()

const ORDER_RESPONSE_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Audio/Sub/Comms/Orders/J_aye.mp3"),
	preload("res://Assets/Audio/Sub/Comms/Orders/J_aye_aye_maam.mp3"),
	preload("res://Assets/Audio/Sub/Comms/Orders/J_aye_captain.mp3"),
	preload("res://Assets/Audio/Sub/Comms/Orders/J_check.mp3"),
	preload("res://Assets/Audio/Sub/Comms/Orders/J_ok_got_it.mp3"),
	preload("res://Assets/Audio/Sub/Comms/Orders/J_on_it.mp3"),
	preload("res://Assets/Audio/Sub/Comms/Orders/J_yep.mp3"),
	preload("res://Assets/Audio/Sub/Comms/Orders/J_yes_maam.mp3")
]
const SONAR_ENABLE_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Audio/Sub/Comms/Sonar/T_sonar_activate_1.mp3"),
	preload("res://Assets/Audio/Sub/Comms/Sonar/T_sonar_activate_2.mp3")
]
const SONAR_DISABLE_SOUNDS: Array[AudioStream] = [
	preload("res://Assets/Audio/Sub/Comms/Sonar/T_sonar_off_1.mp3"),
	preload("res://Assets/Audio/Sub/Comms/Sonar/T_sonar_off_2.mp3")
]
var flank_thrust_multiplier := 1.15

const COMMAND_CONFIG := {
	KEY_1: {
		"multiplier": 1.0 / 3.0,
		"sound": preload("res://Assets/Audio/Sub/Comms/Control/T_forward_one_third.mp3"),
		"motor_stream": 1
	},
	KEY_2: {
		"multiplier": 2.0 / 3.0,
		"sound": preload("res://Assets/Audio/Sub/Comms/Control/T_forwar_two_third.mp3"),
		"motor_stream": 2
	},
	KEY_3: {
		"multiplier": 1.0,
		"sound": preload("res://Assets/Audio/Sub/Comms/Control/T_full_forward.mp3"),
		"motor_stream": 3
	},
	KEY_4: {
		"multiplier": 1.15,
		"sound": preload("res://Assets/Audio/Sub/Comms/Control/T_flank_speed.mp3"),
		"motor_stream": 4
	},
	KEY_R: {
		"multiplier": -2.0 / 3.0,
		"sound": preload("res://Assets/Audio/Sub/Comms/Control/T_reverse.mp3"),
		"motor_stream": 1
	},
	KEY_S: {
		"multiplier": 0.0,
		"sound": preload("res://Assets/Audio/Sub/Comms/Control/T_full_stop.mp3"),
		"motor_stream": 0
	},
	KEY_X: {
		"vertical_multiplier": -0.65,
		"sound": preload("res://Assets/Audio/Sub/Comms/Control/T_ascend.mp3"),
		"motor_stream": -1
	},
	KEY_Y: {
		"vertical_multiplier": 0.65,
		"sound": preload("res://Assets/Audio/Sub/Comms/Control/T_descend.mp3"),
		"motor_stream": -1
	},
	KEY_V: {
		"vertical_multiplier": 0.0,
		"sound": preload("res://Assets/Audio/Sub/Comms/Control/T_stay_level.mp3"),
		"motor_stream": -1
	},
	KEY_I: {
		"type": "sonar_toggle",
		"sound": preload("res://Assets/Audio/Sub/Comms/i_hear_something.mp3")
	}
}


func issue_key_command(keycode: Key, context: Dictionary = {}) -> bool:
	if command_locked:
		return false

	var command_data: Dictionary = COMMAND_CONFIG.get(keycode, {})
	if command_data.is_empty():
		return false

	if command_data.get("type", "thrust") == "sonar_toggle":
		_issue_sonar_toggle_command(bool(context.get("sonar_enabled", false)))
		return true

	var multiplier := float(command_data.get("multiplier", NAN))
	if keycode == KEY_4:
		multiplier = flank_thrust_multiplier
	var vertical_multiplier := float(command_data.get("vertical_multiplier", NAN))

	_issue_command(
		multiplier,
		vertical_multiplier,
		command_data["sound"] as AudioStream,
		int(command_data["motor_stream"])
	)
	return true


func is_command_locked() -> bool:
	return command_locked


func _issue_command(multiplier: float, vertical_multiplier: float, sound: AudioStream, motor_stream: int) -> void:
	await _run_command_pipeline(
		sound,
		_get_random_order_response(),
		func() -> void:
			command_resolved.emit(multiplier, vertical_multiplier, motor_stream)
	)


func _issue_sonar_toggle_command(sonar_enabled: bool) -> void:
	var command_sound := _get_random_sonar_sound(sonar_enabled)
	await _run_command_pipeline(
		command_sound,
		_get_random_order_response(),
		func() -> void:
			sonar_toggle_requested.emit()
	)


func _run_command_pipeline(command_sound: AudioStream, response_sound: AudioStream, execute_action: Callable) -> void:
	command_locked = true
	command_pending_changed.emit(true)

	await _play_voice_line_and_wait(command_sound)
	await _play_voice_line_and_wait(response_sound)

	if execute_action.is_valid():
		execute_action.call()

	_release_lock()


func _play_command_sound(sound: AudioStream) -> StringName:
	if sound == null:
		return StringName()

	_finish_active_voice_line()
	stop()
	stream = sound
	var speaker := _get_speaker_for_stream(sound)
	active_voice_speaker = speaker
	if speaker != StringName():
		voice_line_started.emit(speaker)
	play()
	return speaker


func _play_voice_line_and_wait(sound: AudioStream) -> void:
	if sound == null:
		return

	var speaker := _play_command_sound(sound)
	await finished
	if active_voice_speaker == speaker:
		_finish_active_voice_line()


func play_voice_line(sound: AudioStream) -> void:
	var speaker := _play_command_sound(sound)
	await finished
	if active_voice_speaker == speaker:
		_finish_active_voice_line()


func _get_random_order_response() -> AudioStream:
	return _pick_random_stream(ORDER_RESPONSE_SOUNDS)


func _get_random_sonar_sound(sonar_enabled: bool) -> AudioStream:
	if sonar_enabled:
		return _pick_random_stream(SONAR_DISABLE_SOUNDS)
	return _pick_random_stream(SONAR_ENABLE_SOUNDS)


func _pick_random_stream(streams: Array[AudioStream]) -> AudioStream:
	if streams.is_empty():
		return null
	return streams[randi() % streams.size()]


func _finish_active_voice_line() -> void:
	if active_voice_speaker == StringName():
		return

	var finished_speaker := active_voice_speaker
	active_voice_speaker = StringName()
	voice_line_finished.emit(finished_speaker)


func _get_speaker_for_stream(sound: AudioStream) -> StringName:
	if sound == null:
		return StringName()

	var file_name := sound.resource_path.get_file()
	if file_name.begins_with("T_"):
		return &"T"
	if file_name.begins_with("J_"):
		return &"J"
	return StringName()


func _release_lock() -> void:
	command_locked = false
	command_pending_changed.emit(false)
