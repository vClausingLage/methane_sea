extends Node2D

@export var cone_angle := 30.0
@export var rays := 40
@export var max_range := 600.0

@export var wave_speed := 400.0
@export var pulse_interval := 2.0

@export var rotation_speed := 12.0
@export var rotation_limit := 80.0

@export var cone_visual_distance := 400.0

@export_enum("manual", "auto") var mode: String = "manual"

var timer := 0.0

@onready var sonar_drawer: Node2D = $sonar_drawer
@onready var cone_drawer: Node2D = $sonar_cone


func _process(delta):
	update_cone_visual()

	timer += delta
	if mode == "auto" and timer > pulse_interval:
		emit_sonar()
		timer = 0.0


func scan() -> void:
	if timer > pulse_interval:
		emit_sonar()
		timer = 0.0


func rotate_scan(delta: float) -> void:
	if Input.is_key_pressed(KEY_UP):
		rotation_degrees -= rotation_speed * delta

	if Input.is_key_pressed(KEY_DOWN):
		rotation_degrees += rotation_speed * delta

	rotation_degrees = clamp(rotation_degrees, -rotation_limit, rotation_limit)


func emit_sonar() -> void:
	if cone_drawer and cone_drawer.has_method("trigger_emit_flash"):
		cone_drawer.call("trigger_emit_flash", max_range, wave_speed)

	var ray_directions := SonarLogic.build_ray_directions(cone_angle, rays, global_rotation)
	if ray_directions.is_empty():
		return

	var echoes := []

	var space = get_world_2d().direct_space_state

	for dir in ray_directions:
		var target := global_position + dir * max_range

		var query = PhysicsRayQueryParameters2D.create(global_position, target)
		var result = space.intersect_ray(query)

		if result.is_empty():
			continue

		var is_organic_hit := false
		if result.has("collider"):
			is_organic_hit = SonarLogic.is_organic_collider(result["collider"])

		var echo := SonarLogic.build_echo(global_position, result.position, wave_speed, max_range, is_organic_hit)
		if not echo.is_empty():
			echoes.append(echo)

	if sonar_drawer and sonar_drawer.has_method("start_pulse"):
		sonar_drawer.call("start_pulse", echoes)


func update_cone_visual() -> void:
	if cone_drawer and cone_drawer.has_method("set_scan_visual"):
		cone_drawer.call("set_scan_visual", cone_angle, cone_visual_distance)
