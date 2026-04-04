extends Node2D

var cone_angle := 30.0
var rays := 40
var max_range := 600.0

var wave_speed := 400.0
var pulse_interval := 2.0

var rotation_speed := 12.0
var rotation_limit := 80.0

@onready var sonar_drawer: Node2D = $sonar_drawer
@onready var cone_drawer: Node2D = $sonar_cone
var cone_visual_distance := 400.0

var noise_echo_probability := 0.12
var noise_echo_range := 500.0

var mode : String = 'manual'

var timer: float = 0.0

func _process(delta):

	handle_rotation(delta)
	update_cone_visual()

	timer += delta
	if timer > pulse_interval:
		if mode == 'auto':
			emit_sonar()
			timer = 0

func scan():
	if timer > pulse_interval:
		emit_sonar()
		timer = 0

func handle_rotation(delta):

	if Input.is_key_pressed(KEY_UP):
		rotation_degrees -= rotation_speed * delta

	if Input.is_key_pressed(KEY_DOWN):
		rotation_degrees += rotation_speed * delta

	rotation_degrees = clamp(rotation_degrees, -rotation_limit, rotation_limit)


func update_cone_visual():
	if cone_drawer and cone_drawer.has_method("set_scan_visual"):
		cone_drawer.call("set_scan_visual", cone_angle, cone_visual_distance)


func emit_sonar():
	if cone_drawer and cone_drawer.has_method("trigger_emit_flash"):
		cone_drawer.call("trigger_emit_flash", max_range, wave_speed)

	var echoes = []

	var start_angle = -cone_angle / 2
	var step = cone_angle / rays

	var space = get_world_2d().direct_space_state

	for i in range(rays):

		var angle = deg_to_rad(start_angle + i * step) + global_rotation
		var dir = Vector2.RIGHT.rotated(angle)

		var target = global_position + dir * max_range

		var query = PhysicsRayQueryParameters2D.create(global_position, target)
		var result = space.intersect_ray(query)

		if result.is_empty():
			continue

		var hit_pos = result.position
		var distance = global_position.distance_to(hit_pos)

		if distance >= max_range:
			continue
			
		echoes.append({
			"point": hit_pos,
			"delay": distance / wave_speed,
			"noise": false
		})


	sonar_drawer.start_pulse(echoes)
