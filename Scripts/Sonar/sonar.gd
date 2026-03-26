extends Node2D

@export var cone_angle: float = 30.0
@export var rays: int = 40
@export var max_range: float = 600.0

@export var wave_speed: float = 400.0
@export var pulse_interval: float = 2.0

@export var rotation_speed: float = 60.0
@export var rotation_limit: float = 80.0

var timer := 0.0

@onready var sonar_drawer = get_node("sonar_drawer")

func _process(delta):
	
	handle_rotation(delta)

	timer += delta

	if timer > pulse_interval:
		timer = 0
		emit_sonar()


func handle_rotation(delta):

	if Input.is_key_pressed(KEY_Q):
		rotation_degrees -= rotation_speed * delta

	if Input.is_key_pressed(KEY_E):
		rotation_degrees += rotation_speed * delta

	rotation_degrees = clamp(rotation_degrees, -rotation_limit, rotation_limit)


func emit_sonar():

	var echoes = []

	var start_angle = -cone_angle / 2
	var step = cone_angle / rays

	var space = get_world_2d().direct_space_state

	for i in range(rays):

		var angle = deg_to_rad(start_angle + i * step) + global_rotation

		var direction = Vector2.RIGHT.rotated(angle)

		var target = global_position + direction * max_range

		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			target
		)

		var result = space.intersect_ray(query)

		var hit_pos = target

		if result:
			hit_pos = result.position

		var distance = global_position.distance_to(hit_pos)

		echoes.append({
			"point": hit_pos,
			"distance": distance,
			"delay": distance / wave_speed
		})

	sonar_drawer.start_pulse(echoes)
