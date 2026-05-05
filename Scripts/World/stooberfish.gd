extends "res://Scripts/World/fish.gd"

@export var sound_attraction_range := 1150.0
@export var shove_distance := 360.0
@export var shove_damage := 0.018
@export var shove_impulse := 175.0
@export var shove_cooldown := 3.6


func _init() -> void:
	_configure_fish()


func _configure_fish() -> void:
	attack_screech = preload("res://Assets/Audio/Monster/fish_medium3.wav")
	route_radius = Vector2(520.0, 210.0)
	route_point_count = 6
	max_swim_speed = 68.0
	steering_strength = 34.0
	route_arrival_distance = 110.0
	attraction_range = 1150.0
	curiosity_offset_distance = 230.0
	contact_distance = 360.0
	contact_damage = 0.018
	contact_impulse = 175.0
	contact_cooldown = 3.6
	attack_backoff_distance = 760.0
	attack_backoff_time = 1.25
	attack_recoil_impulse = 260.0
	attack_wait_time = 1.0
	flee_distance = 980.0
	flee_time = 4.5
	route_radius_min_scale = 0.68
	route_radius_max_scale = 1.22
	swim_speed_floor_ratio = 0.52
	swim_torque_frequency = 0.0027
	swim_torque_strength = 16.0
	swim_velocity_damping = 0.988
	attraction_enter_threshold = 0.07
	attraction_continue_threshold = 0.035
	flee_jitter_y = 260.0
	attack_sound_volume_db = -5.0
	attack_pitch_min = 0.78
	attack_pitch_max = 1.05
	contact_kind = &"scratch"


func _ready() -> void:
	_apply_species_exports()
	super._ready()


func _get_attraction(submarine: Node2D) -> float:
	return _get_attraction_from_submarine_method(submarine, &"get_sound_attraction_strength")


func _get_swim_drive(attraction: float) -> float:
	return 1.0 if _attack_state != STATE_ROAM else attraction


func _try_shove_submarine(submarine: Node2D) -> void:
	_try_contact_submarine(submarine)


func _apply_species_exports() -> void:
	attraction_range = sound_attraction_range
	contact_distance = shove_distance
	contact_damage = shove_damage
	contact_impulse = shove_impulse
	contact_cooldown = shove_cooldown
