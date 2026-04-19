extends AudioStreamPlayer2D
class_name MotorPlayer

const MOTOR_STREAMS := {
<<<<<<< HEAD
	1: preload("res://Assets/Audio/Sub/Ship/motor_1.wav"),
	2: preload("res://Assets/Audio/Sub/Ship/motor_3.wav"),
	3: preload("res://Assets/Audio/Sub/Ship/motor_2.wav"),
	4: preload("res://Assets/Audio/Sub/Ship/motor_4.wav")
=======
	1: preload("res://Assets/Audio/Sub/motor_1.wav"),
	2: preload("res://Assets/Audio/Sub/motor_3.wav"),
	3: preload("res://Assets/Audio/Sub/motor_2.wav"),
	4: preload("res://Assets/Audio/Sub/motor_4.wav")
>>>>>>> 0f85414141d27d0113a225f664bd7de2e8eba49d
}

func _ready() -> void:
	for stream_id in MOTOR_STREAMS.keys():
		_set_looping(MOTOR_STREAMS[stream_id] as AudioStreamWAV)


func play_stream(number: int) -> void:
	stop()
	if number == 0:
		return

	var selected_stream := MOTOR_STREAMS.get(number, null) as AudioStream
	if selected_stream == null:
		return

	stream = selected_stream
	play()


func _set_looping(audio_stream: AudioStreamWAV) -> void:
	if audio_stream == null:
		return

	audio_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
