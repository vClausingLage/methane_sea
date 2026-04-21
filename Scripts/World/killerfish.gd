extends RigidBody2D

var isOrganic := true
var sound_emitted_1: AudioStream = preload("res://Assets/Audio/Monster/fish_medium1.wav")
var sound_emitted_2: AudioStream = preload("res://Assets/Audio/Monster/fish_medium2.wav")
var sound_emitted_3: AudioStream = preload("res://Assets/Audio/Monster/fish_medium3.wav")
var sound_emitted_4: AudioStream = preload("res://Assets/Audio/Monster/fish_medium4.wav")
@export_range(0.0, 1.0, 0.01) var passive_loudness := 0.8

const SOUND_INTERVAL_MIN := 6.0
const SOUND_INTERVAL_MAX := 10.0

var direction := 'left'
var _rng := RandomNumberGenerator.new()
var _random_sound_player: AudioStreamPlayer2D
var _random_sound_timer: Timer
var _ambient_sounds: Array[AudioStream] = []

@onready var sprite := $sprite
@onready var collider := $collider
@onready var light := $light

func _ready() -> void:
	add_to_group(&"passive_sound_emitters")
	_rng.randomize()
	_ambient_sounds = [sound_emitted_1, sound_emitted_2, sound_emitted_3, sound_emitted_4]

	_random_sound_player = AudioStreamPlayer2D.new()
	_random_sound_player.name = "random_sound_player"
	add_child(_random_sound_player)

	_random_sound_timer = Timer.new()
	_random_sound_timer.name = "random_sound_timer"
	_random_sound_timer.one_shot = true
	_random_sound_timer.timeout.connect(_on_random_sound_timer_timeout)
	add_child(_random_sound_timer)
	_schedule_next_random_sound()

	self.apply_impulse(Vector2(-8, 0))
	if (direction == 'left'):
		sprite.scale.x *= -1
		collider.position.x *= 1
		light.position = Vector2(-70, -62)
	if (direction == 'right'):
		sprite.scale.x *= 1
		collider.position.x *= -1
		light.position = Vector2(10, -62)


func _on_random_sound_timer_timeout() -> void:
	if _ambient_sounds.is_empty():
		return

	var index := _rng.randi_range(0, _ambient_sounds.size() - 1)
	_random_sound_player.stream = _ambient_sounds[index]
	_random_sound_player.play()
	_schedule_next_random_sound()


func _schedule_next_random_sound() -> void:
	_random_sound_timer.wait_time = _rng.randf_range(SOUND_INTERVAL_MIN, SOUND_INTERVAL_MAX)
	_random_sound_timer.start()


func get_passive_sonar_stream() -> AudioStream:
	return sound_emitted_2


func get_passive_sonar_loudness() -> float:
	return passive_loudness
