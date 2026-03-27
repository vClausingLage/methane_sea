extends Node2D

@export var cone_angle := 30.0
@export var rays := 40
@export var max_range := 600.0

@export var wave_speed := 400.0
@export var pulse_interval := 2.0

@export var rotation_speed := 60.0
@export var rotation_limit := 80.0

@export var sonar_drawer: Node2D

var timer := 0.0


func _process(delta):

	handle_rotation(delta)

	timer += delta
	if timer > pulse_interval:
		timer = 0
		emit_sonar()


func handle_rotation(delta):

	if Input.is_key_pressed(KEY_UP):
		rotation_degrees -= rotation_speed * delta

	if Input.is_key_pressed(KEY_DOWN):
		rotation_degrees += rotation_speed * delta

	rotation_degrees = clamp(rotation_degrees, -rotation_limit, rotation_limit)


func emit_sonar():

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
			"delay": distance / wave_speed
		})

	sonar_drawer.start_pulse(echoes)
