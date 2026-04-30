extends Node2D

@export_node_path("Node2D") var player_path: NodePath = ^"../Player"
@export var fish_scenes: Array[PackedScene] = []
@export var spawn_points: PackedVector2Array = PackedVector2Array()
@export_node_path("Node") var marker_parent_path: NodePath
@export var spawn_distance := 1000.0
@export var despawn_distance := 1400.0
@export var minimum_spawn_distance := 220.0
@export var max_active_fish := 5
@export var spawn_cooldown := 8.0
@export var check_interval := 0.35
@export var spawn_jitter_radius := 80.0

var _rng := RandomNumberGenerator.new()
var _active_by_spawn_index := {}
var _cooldown_by_spawn_index := {}
var _check_timer := 0.0

@onready var player: Node2D = get_node_or_null(player_path) as Node2D


func _ready() -> void:
	_rng.randomize()
	set_process(true)


func _process(delta: float) -> void:
	if player == null:
		player = get_node_or_null(player_path) as Node2D
		if player == null:
			return

	_tick_spawn_cooldowns(delta)
	_check_timer -= delta
	if _check_timer > 0.0:
		return

	_check_timer = check_interval
	_update_active_fish()
	_spawn_nearby_fish()


func _tick_spawn_cooldowns(delta: float) -> void:
	for spawn_index in _cooldown_by_spawn_index.keys():
		var remaining := float(_cooldown_by_spawn_index[spawn_index]) - delta
		if remaining <= 0.0:
			_cooldown_by_spawn_index.erase(spawn_index)
		else:
			_cooldown_by_spawn_index[spawn_index] = remaining


func _update_active_fish() -> void:
	for spawn_index in _active_by_spawn_index.keys():
		var fish := _active_by_spawn_index[spawn_index] as Node2D
		if fish == null or not is_instance_valid(fish):
			_active_by_spawn_index.erase(spawn_index)
			_cooldown_by_spawn_index[spawn_index] = spawn_cooldown
			continue

		var distance := player.global_position.distance_to(fish.global_position)
		if distance <= despawn_distance:
			continue

		fish.queue_free()
		_active_by_spawn_index.erase(spawn_index)
		_cooldown_by_spawn_index[spawn_index] = spawn_cooldown


func _spawn_nearby_fish() -> void:
	if fish_scenes.is_empty() or _active_by_spawn_index.size() >= max_active_fish:
		return

	var points := _get_spawn_points()
	for spawn_index in range(points.size()):
		if _active_by_spawn_index.size() >= max_active_fish:
			return
		if _active_by_spawn_index.has(spawn_index) or _cooldown_by_spawn_index.has(spawn_index):
			continue

		var spawn_point := points[spawn_index]
		var distance := player.global_position.distance_to(spawn_point)
		if distance > spawn_distance or distance < minimum_spawn_distance:
			continue

		_spawn_fish(spawn_index, spawn_point)


func _spawn_fish(spawn_index: int, spawn_point: Vector2) -> void:
	var scene := fish_scenes[_rng.randi_range(0, fish_scenes.size() - 1)]
	if scene == null:
		return

	var fish := scene.instantiate() as Node2D
	if fish == null:
		return

	fish.position = spawn_point + _get_spawn_jitter()
	add_child(fish)
	_active_by_spawn_index[spawn_index] = fish


func _get_spawn_jitter() -> Vector2:
	if spawn_jitter_radius <= 0.0:
		return Vector2.ZERO

	return Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)) * _rng.randf_range(0.0, spawn_jitter_radius)


func _get_spawn_points() -> PackedVector2Array:
	var points := spawn_points.duplicate()
	var marker_parent := get_node_or_null(marker_parent_path)
	if marker_parent == null:
		return points

	for child in marker_parent.get_children():
		if child is Node2D:
			points.append((child as Node2D).global_position)

	return points
