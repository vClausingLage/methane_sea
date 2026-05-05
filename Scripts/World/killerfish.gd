extends "res://Scripts/World/fish.gd"

var sound_emitted_1: AudioStream = preload("res://Assets/Audio/Monster/fish_medium1.wav")
var sound_emitted_2: AudioStream = preload("res://Assets/Audio/Monster/fish_medium2.wav")
var sound_emitted_3: AudioStream = preload("res://Assets/Audio/Monster/fish_medium3.wav")
var sound_emitted_4: AudioStream = preload("res://Assets/Audio/Monster/fish_medium4.wav")
@export_range(0.0, 1.0, 0.01) var passive_loudness := 0.8
@export var light_attraction_range := 950.0
@export var bite_distance := 95.0
@export var bite_damage := 0.035
@export var bite_impulse := 120.0
@export var bite_cooldown := 2.8

const SOUND_INTERVAL_MIN := 6.0
const SOUND_INTERVAL_MAX := 10.0

var _random_sound_player: AudioStreamPlayer2D
var _random_sound_timer: Timer
var _ambient_sounds: Array[AudioStream] = []


func _init() -> void:
	_configure_fish()


func _configure_fish() -> void:
	attack_screech = preload("res://Assets/Audio/Monster/fish_medium4.wav")
	facing = Facing.RIGHT
	swim_impulse = 8.0
	route_radius = Vector2(420.0, 160.0)
	route_point_count = 5
	max_swim_speed = 96.0
	steering_strength = 48.0
	route_arrival_distance = 80.0
	attraction_range = 950.0
	curiosity_offset_distance = 170.0
	contact_distance = 95.0
	contact_damage = 0.035
	contact_impulse = 120.0
	contact_cooldown = 2.8
	attack_backoff_distance = 260.0
	attack_backoff_time = 0.75
	attack_wait_time = 1.0
	flee_distance = 900.0
	flee_time = 4.0
	route_radius_min_scale = 0.72
	route_radius_max_scale = 1.18
	swim_speed_floor_ratio = 0.62
	swim_torque_frequency = 0.004
	swim_torque_strength = 9.0
	swim_velocity_damping = 0.985
	attraction_enter_threshold = 0.08
	attraction_continue_threshold = 0.04
	flee_jitter_y = 220.0
	attack_sound_volume_db = -4.0
	attack_pitch_min = 0.84
	attack_pitch_max = 1.12
	contact_kind = &"bite"


func _ready() -> void:
	_apply_species_exports()
	super._ready()
	add_to_group(&"passive_sound_emitters")
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


func _get_attraction(submarine: Node2D) -> float:
	return _get_attraction_from_submarine_method(submarine, &"get_light_attraction_strength")


func _apply_species_exports() -> void:
	attraction_range = light_attraction_range
	contact_distance = bite_distance
	contact_damage = bite_damage
	contact_impulse = bite_impulse
	contact_cooldown = bite_cooldown


func _try_bite_submarine(submarine: Node2D) -> void:
	_try_contact_submarine(submarine)


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
