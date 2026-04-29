extends RigidBody2D

enum Facing {
	LEFT = -1,
	RIGHT = 1
}

var isOrganic := true
var sound_emitted_1: AudioStream = preload("res://Assets/Audio/Monster/fish_medium1.wav")
var sound_emitted_2: AudioStream = preload("res://Assets/Audio/Monster/fish_medium2.wav")
var sound_emitted_3: AudioStream = preload("res://Assets/Audio/Monster/fish_medium3.wav")
var sound_emitted_4: AudioStream = preload("res://Assets/Audio/Monster/fish_medium4.wav")
@export_range(0.0, 1.0, 0.01) var passive_loudness := 0.8
@export var facing: Facing = Facing.RIGHT
@export var swim_impulse := 8.0

const SOUND_INTERVAL_MIN := 6.0
const SOUND_INTERVAL_MAX := 10.0

var _rng := RandomNumberGenerator.new()
var _random_sound_player: AudioStreamPlayer2D
var _random_sound_timer: Timer
var _ambient_sounds: Array[AudioStream] = []
var _collider_base_position := Vector2.ZERO
var _collider_base_scale := Vector2.ONE
var _sprite_base_scale := Vector2.ONE
var _sprite_base_flip_h := false

@onready var collider: CollisionPolygon2D = $collider
@onready var sprite: Sprite2D = $sprite

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
	if collider != null:
		_collider_base_position = collider.position
		_collider_base_scale = collider.scale
	if sprite != null:
		_sprite_base_scale = sprite.scale
		_sprite_base_flip_h = sprite.flip_h
	_apply_facing()
	apply_central_impulse(Vector2(float(facing) * swim_impulse, 0.0))


func _apply_facing() -> void:
	if sprite != null:
		sprite.scale = _sprite_base_scale
		sprite.flip_h = _sprite_base_flip_h if facing == Facing.RIGHT else not _sprite_base_flip_h
	if collider != null:
		collider.position = _collider_base_position
		collider.scale = _collider_base_scale
		if facing == Facing.LEFT:
			collider.position.x = -_collider_base_position.x
			collider.scale.x = -_collider_base_scale.x


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
