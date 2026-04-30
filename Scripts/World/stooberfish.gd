extends RigidBody2D

var isOrganic := true

@export var route_radius := Vector2(520.0, 210.0)
@export var route_point_count := 6
@export var max_swim_speed := 68.0
@export var steering_strength := 34.0
@export var route_arrival_distance := 110.0
@export var sound_attraction_range := 1150.0
@export var curiosity_offset_distance := 230.0
@export var shove_distance := 145.0
@export var shove_damage := 0.018
@export var shove_impulse := 175.0
@export var shove_cooldown := 3.6

var _rng := RandomNumberGenerator.new()
var _route_center := Vector2.ZERO
var _route_points: Array[Vector2] = []
var _route_index := 0
var _shove_cooldown_remaining := 0.0
var _sprite_base_flip_h := false

@onready var sprite: Sprite2D = $sprite


func _ready() -> void:
	add_to_group(&"fish")
	_rng.randomize()
	if sprite != null:
		_sprite_base_flip_h = sprite.flip_h
	_build_route()


func _physics_process(delta: float) -> void:
	_shove_cooldown_remaining = max(_shove_cooldown_remaining - delta, 0.0)
	var submarine := _get_submarine()
	var target := _get_route_target()
	var attraction := 0.0

	if submarine != null:
		attraction = _get_sound_interest(submarine)
		if attraction > 0.035:
			target = _get_curiosity_target(submarine)
			_try_shove_submarine(submarine)

	_swim_toward(target, attraction, delta)
	_update_route_progress()
	_update_facing_from_velocity()


func _build_route() -> void:
	_route_center = global_position
	_route_points.clear()
	var count: int = max(route_point_count, 3)
	var angle_offset := _rng.randf_range(0.0, TAU)
	for index in range(count):
		var angle := angle_offset + TAU * float(index) / float(count)
		var radius_scale := _rng.randf_range(0.68, 1.22)
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

	var speed := lerpf(max_swim_speed * 0.52, max_swim_speed, clamp(attraction, 0.0, 1.0))
	var desired_velocity := to_target.normalized() * speed
	var steering := (desired_velocity - linear_velocity) * steering_strength
	apply_central_force(steering)
	apply_torque(sin(Time.get_ticks_msec() * 0.0027) * 16.0)
	if linear_velocity.length() > max_swim_speed:
		linear_velocity = linear_velocity.normalized() * max_swim_speed
	linear_velocity *= pow(0.988, delta * 60.0)


func _update_facing_from_velocity() -> void:
	if sprite == null or abs(linear_velocity.x) < 4.0:
		return
	sprite.flip_h = _sprite_base_flip_h if linear_velocity.x >= 0.0 else not _sprite_base_flip_h


func _get_submarine() -> Node2D:
	var submarines := get_tree().get_nodes_in_group(&"submarine")
	if submarines.is_empty():
		return null
	return submarines[0] as Node2D


func _get_sound_interest(submarine: Node2D) -> float:
	if not submarine.has_method("get_sound_attraction_strength"):
		return 0.0
	var distance := global_position.distance_to(submarine.global_position)
	if distance > sound_attraction_range:
		return 0.0
	var sound_strength := float(submarine.call("get_sound_attraction_strength"))
	return clamp(sound_strength * (1.0 - distance / sound_attraction_range), 0.0, 1.0)


func _get_curiosity_target(submarine: Node2D) -> Vector2:
	var away := global_position - submarine.global_position
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	var orbit := away.normalized().orthogonal() * curiosity_offset_distance
	return submarine.global_position + orbit


func _try_shove_submarine(submarine: Node2D) -> void:
	if _shove_cooldown_remaining > 0.0:
		return
	if global_position.distance_to(submarine.global_position) > shove_distance:
		return
	if submarine.has_method("apply_fish_contact"):
		submarine.call("apply_fish_contact", global_position, shove_damage, shove_impulse, &"scratch")
	_shove_cooldown_remaining = shove_cooldown
