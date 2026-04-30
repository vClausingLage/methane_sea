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
@export var route_radius := Vector2(420.0, 160.0)
@export var route_point_count := 5
@export var max_swim_speed := 96.0
@export var steering_strength := 48.0
@export var route_arrival_distance := 80.0
@export var light_attraction_range := 950.0
@export var curiosity_offset_distance := 170.0
@export var bite_distance := 95.0
@export var bite_damage := 0.035
@export var bite_impulse := 120.0
@export var bite_cooldown := 2.8

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
var _route_center := Vector2.ZERO
var _route_points: Array[Vector2] = []
var _route_index := 0
var _bite_cooldown_remaining := 0.0

@onready var collider: CollisionPolygon2D = $collider
@onready var sprite: Sprite2D = $sprite

func _ready() -> void:
	add_to_group(&"passive_sound_emitters")
	add_to_group(&"fish")
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
	_build_route()
	apply_central_impulse(Vector2(float(facing) * swim_impulse, 0.0))


func _physics_process(delta: float) -> void:
	_bite_cooldown_remaining = max(_bite_cooldown_remaining - delta, 0.0)
	var submarine := _get_submarine()
	var target := _get_route_target()
	var attraction := 0.0

	if submarine != null:
		attraction = _get_light_interest(submarine)
		if attraction > 0.04:
			target = _get_curiosity_target(submarine)
			_try_bite_submarine(submarine)

	_swim_toward(target, attraction, delta)
	_update_route_progress()
	_update_facing_from_velocity()


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


func _build_route() -> void:
	_route_center = global_position
	_route_points.clear()
	var count: int = max(route_point_count, 3)
	var angle_offset := _rng.randf_range(0.0, TAU)
	for index in range(count):
		var angle := angle_offset + TAU * float(index) / float(count)
		var radius_scale := _rng.randf_range(0.72, 1.18)
		_route_points.append(_route_center + Vector2(cos(angle) * route_radius.x, sin(angle) * route_radius.y) * radius_scale)


func _get_route_target() -> Vector2:
	if _route_points.is_empty():
		return _route_center
	return _route_points[_route_index]


func _update_route_progress() -> void:
	if _route_points.is_empty():
		return
	if global_position.distance_to(_route_points[_route_index]) <= route_arrival_distance:
		_route_index = (_route_index + 1) % _route_points.size()


func _swim_toward(target: Vector2, attraction: float, delta: float) -> void:
	var to_target := target - global_position
	if to_target.length_squared() <= 1.0:
		return

	var speed := lerpf(max_swim_speed * 0.62, max_swim_speed, clamp(attraction, 0.0, 1.0))
	var desired_velocity : Vector2 = to_target.normalized() * speed
	var steering : Vector2 = (desired_velocity - linear_velocity) * steering_strength
	apply_central_force(steering)
	apply_torque(sin(Time.get_ticks_msec() * 0.004) * 9.0)
	if linear_velocity.length() > max_swim_speed:
		linear_velocity = linear_velocity.normalized() * max_swim_speed
	linear_velocity *= pow(0.985, delta * 60.0)


func _update_facing_from_velocity() -> void:
	if abs(linear_velocity.x) < 4.0:
		return
	var new_facing := Facing.RIGHT if linear_velocity.x >= 0.0 else Facing.LEFT
	if new_facing == facing:
		return
	facing = new_facing
	_apply_facing()


func _get_submarine() -> Node2D:
	var submarines := get_tree().get_nodes_in_group(&"submarine")
	if submarines.is_empty():
		return null
	return submarines[0] as Node2D


func _get_light_interest(submarine: Node2D) -> float:
	if not submarine.has_method("get_light_attraction_strength"):
		return 0.0
	var distance := global_position.distance_to(submarine.global_position)
	if distance > light_attraction_range:
		return 0.0
	var light_strength := float(submarine.call("get_light_attraction_strength"))
	return clamp(light_strength * (1.0 - distance / light_attraction_range), 0.0, 1.0)


func _get_curiosity_target(submarine: Node2D) -> Vector2:
	var away := global_position - submarine.global_position
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	var orbit := away.normalized().orthogonal() * curiosity_offset_distance
	return submarine.global_position + orbit


func _try_bite_submarine(submarine: Node2D) -> void:
	if _bite_cooldown_remaining > 0.0:
		return
	if global_position.distance_to(submarine.global_position) > bite_distance:
		return
	if submarine.has_method("apply_fish_contact"):
		submarine.call("apply_fish_contact", global_position, bite_damage, bite_impulse, &"bite")
	_bite_cooldown_remaining = bite_cooldown


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
