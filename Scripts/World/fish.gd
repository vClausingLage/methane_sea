extends RigidBody2D
class_name Fish

enum Facing {
	LEFT = -1,
	RIGHT = 1
}

const STATE_ROAM := &"roam"
const STATE_APPROACH := &"approach"
const STATE_BACK_OFF := &"back_off"
const STATE_WAIT := &"wait"
const STATE_FLEE := &"flee"

var isOrganic := true
var attack_screech: AudioStream

@export var facing: Facing = Facing.RIGHT
@export var swim_impulse := 0.0
@export var route_radius := Vector2(420.0, 160.0)
@export var route_point_count := 5
@export var max_swim_speed := 96.0
@export var steering_strength := 48.0
@export var route_arrival_distance := 80.0
@export var attraction_range := 950.0
@export var curiosity_offset_distance := 170.0
@export var contact_distance := 95.0
@export var contact_damage := 0.035
@export var contact_impulse := 120.0
@export var contact_cooldown := 2.8
@export var attack_backoff_distance := 260.0
@export var attack_backoff_time := 0.75
@export var attack_wait_time := 1.0
@export var flee_distance := 900.0
@export var flee_time := 4.0

var route_radius_min_scale := 0.72
var route_radius_max_scale := 1.18
var swim_speed_floor_ratio := 0.62
var swim_torque_frequency := 0.004
var swim_torque_strength := 9.0
var swim_velocity_damping := 0.985
var attraction_enter_threshold := 0.08
var attraction_continue_threshold := 0.04
var attack_attempts_min := 1
var attack_attempts_max := 3
@export var attack_recoil_impulse := 0.0
var flee_jitter_y := 220.0
var attack_sound_volume_db := -4.0
var attack_pitch_min := 0.84
var attack_pitch_max := 1.12
var contact_kind := &"bite"

var _rng := RandomNumberGenerator.new()
var _attack_sound_player: AudioStreamPlayer2D
var _route_center := Vector2.ZERO
var _route_points: Array[Vector2] = []
var _route_index := 0
var _contact_cooldown_remaining := 0.0
var _attack_state := STATE_ROAM
var _attack_attempts_remaining := 0
var _state_timer := 0.0
var _flee_target := Vector2.ZERO

@onready var visuals: Node2D = $visuals
@onready var sprite: Sprite2D = $visuals/sprite
@onready var collider: CollisionPolygon2D = $visuals/collider


func _ready() -> void:
	add_to_group(&"fish")
	_rng.randomize()
	_attack_sound_player = AudioStreamPlayer2D.new()
	_attack_sound_player.name = "attack_sound_player"
	_attack_sound_player.volume_db = attack_sound_volume_db
	add_child(_attack_sound_player)
	_apply_facing()
	_build_route()
	if not is_zero_approx(swim_impulse):
		apply_central_impulse(Vector2(float(facing) * swim_impulse, 0.0))


func _physics_process(delta: float) -> void:
	_contact_cooldown_remaining = max(_contact_cooldown_remaining - delta, 0.0)
	var submarine := _get_submarine()
	var target := _get_route_target()
	var attraction := 0.0
	var update_route := true

	if submarine != null:
		attraction = _get_attraction(submarine)
		target = _update_attack_state(submarine, attraction, delta)
		update_route = _attack_state == STATE_ROAM
	elif _attack_state != STATE_ROAM:
		_reset_attack_state()

	_swim_toward(target, _get_swim_drive(attraction), delta)
	if update_route:
		_update_route_progress()
	_update_orientation(delta)


func _configure_fish() -> void:
	pass


func _get_attraction(_submarine: Node2D) -> float:
	return 0.0


func _get_swim_drive(attraction: float) -> float:
	return attraction


func _apply_facing() -> void:
	if visuals != null:
		visuals.scale.y = -1.0 if facing == Facing.LEFT else 1.0


func _cache_light_transforms() -> void:
	pass # No longer needed with visuals pivot


func _build_route() -> void:
	_route_center = global_position
	_route_points.clear()
	var count: int = max(route_point_count, 3)
	var angle_offset := _rng.randf_range(0.0, TAU)
	for index in range(count):
		var angle := angle_offset + TAU * float(index) / float(count)
		var radius_scale := _rng.randf_range(route_radius_min_scale, route_radius_max_scale)
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

	var speed := lerpf(max_swim_speed * swim_speed_floor_ratio, max_swim_speed, clamp(attraction, 0.0, 1.0))
	var desired_velocity := to_target.normalized() * speed
	var steering := (desired_velocity - linear_velocity) * steering_strength
	apply_central_force(steering)
	
	# Apply a bit of wobble via torque
	apply_torque(sin(Time.get_ticks_msec() * swim_torque_frequency) * swim_torque_strength)
	
	if linear_velocity.length() > max_swim_speed:
		linear_velocity = linear_velocity.normalized() * max_swim_speed
	linear_velocity *= pow(swim_velocity_damping, delta * 60.0)


func _update_orientation(delta: float) -> void:
	if linear_velocity.length() < 5.0:
		return
	
	var target_rotation = linear_velocity.angle()
	rotation = lerp_angle(rotation, target_rotation, delta * 5.0)
	
	var new_facing := Facing.RIGHT if abs(rotation) < PI/2 else Facing.LEFT
	if new_facing != facing:
		facing = new_facing
		_apply_facing()


func _update_facing_from_velocity() -> void:
	pass # Deprecated in favor of _update_orientation


func _get_submarine() -> Node2D:
	var submarines := get_tree().get_nodes_in_group(&"submarine")
	if submarines.is_empty():
		return null
	return submarines[0] as Node2D


func _get_attraction_from_submarine_method(submarine: Node2D, method_name: StringName) -> float:
	if not submarine.has_method(method_name):
		return 0.0
	var distance := global_position.distance_to(submarine.global_position)
	if distance > attraction_range:
		return 0.0
	var strength := float(submarine.call(method_name))
	return clamp(strength * (1.0 - distance / attraction_range), 0.0, 1.0)


func _get_curiosity_target(submarine: Node2D) -> Vector2:
	var away := global_position - submarine.global_position
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	var orbit := away.normalized().orthogonal() * curiosity_offset_distance
	return submarine.global_position + orbit


func _update_attack_state(submarine: Node2D, attraction: float, delta: float) -> Vector2:
	match _attack_state:
		STATE_ROAM:
			if attraction > attraction_enter_threshold:
				_begin_attack_sequence()
				return submarine.global_position
			return _get_route_target()
		STATE_APPROACH:
			if global_position.distance_to(submarine.global_position) <= contact_distance:
				_perform_contact(submarine)
				_begin_backoff(submarine)
			return submarine.global_position
		STATE_BACK_OFF:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_attack_state = STATE_WAIT
				_state_timer = attack_wait_time
			return _get_backoff_target(submarine)
		STATE_WAIT:
			_state_timer -= delta
			if _state_timer <= 0.0:
				if _attack_attempts_remaining > 0 and attraction > attraction_continue_threshold:
					_attack_state = STATE_APPROACH
				else:
					_begin_flee(submarine)
			return _get_backoff_target(submarine)
		STATE_FLEE:
			_state_timer -= delta
			if _state_timer <= 0.0 or global_position.distance_to(submarine.global_position) > attraction_range:
				_reset_attack_state()
				return _get_route_target()
			return _flee_target

	return _get_route_target()


func _begin_attack_sequence() -> void:
	_attack_state = STATE_APPROACH
	_attack_attempts_remaining = _rng.randi_range(attack_attempts_min, attack_attempts_max)


func _perform_contact(submarine: Node2D) -> void:
	if _contact_cooldown_remaining > 0.0:
		return
	if submarine.has_method("apply_fish_contact"):
		submarine.call("apply_fish_contact", global_position, contact_damage, contact_impulse, contact_kind)
	_play_attack_screech()
	_attack_attempts_remaining = max(_attack_attempts_remaining - 1, 0)
	_contact_cooldown_remaining = contact_cooldown


func _begin_backoff(submarine: Node2D) -> void:
	_attack_state = STATE_BACK_OFF
	_state_timer = attack_backoff_time
	_flee_target = _get_backoff_target(submarine)
	if attack_recoil_impulse > 0.0:
		var away := global_position - submarine.global_position
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		apply_central_impulse(away.normalized() * attack_recoil_impulse)


func _begin_flee(submarine: Node2D) -> void:
	_attack_state = STATE_FLEE
	_state_timer = flee_time
	var away := global_position - submarine.global_position
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	_flee_target = global_position + away.normalized() * flee_distance + Vector2(0.0, _rng.randf_range(-flee_jitter_y, flee_jitter_y))


func _reset_attack_state() -> void:
	_attack_state = STATE_ROAM
	_attack_attempts_remaining = 0
	_state_timer = 0.0


func _get_backoff_target(submarine: Node2D) -> Vector2:
	var away := global_position - submarine.global_position
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	return submarine.global_position + away.normalized() * attack_backoff_distance


func _play_attack_screech() -> void:
	if _attack_sound_player == null or attack_screech == null:
		return
	_attack_sound_player.stream = attack_screech
	_attack_sound_player.pitch_scale = _rng.randf_range(attack_pitch_min, attack_pitch_max)
	_attack_sound_player.play()


func _try_contact_submarine(submarine: Node2D) -> void:
	if _contact_cooldown_remaining > 0.0:
		return
	if global_position.distance_to(submarine.global_position) > contact_distance:
		return
	if submarine.has_method("apply_fish_contact"):
		submarine.call("apply_fish_contact", global_position, contact_damage, contact_impulse, contact_kind)
	_contact_cooldown_remaining = contact_cooldown
