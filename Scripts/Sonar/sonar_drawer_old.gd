extends Node2D

var pulses = []

@export var wave_speed: float = 400.0
@export var pulse_lifetime: float = 5.0

@export var bright_color := Color(0,1,0)
@export var dark_color := Color(0,0.35,0)

@export var noise_strength := 5.0

func start_pulse(echoes):

	pulses.append({
		"echoes": echoes,
		"time": 0.0
	})

func _process(delta):

	for pulse in pulses:
		pulse.time += delta

	pulses = pulses.filter(func(p): return p.time < pulse_lifetime)

	queue_redraw()

func _draw():

	for pulse in pulses:

		draw_wave(pulse)

		draw_echoes(pulse)



func draw_wave(pulse):

	var radius = pulse.time * wave_speed

	draw_arc(
		Vector2.ZERO,
		radius,
		deg_to_rad(-15),
		deg_to_rad(15),
		32,
		bright_color,
		2
	)



func draw_echoes(pulse):

	for echo in pulse.echoes:

		if pulse.time >= echo.delay:

			var age = pulse.time - echo.delay

			var color = bright_color

			if age > 0.5:
				color = dark_color

			var local_point = to_local(echo.point)

			var noise = Vector2(
				randf_range(-noise_strength, noise_strength),
				randf_range(-noise_strength, noise_strength)
			)

			draw_line(
				Vector2.ZERO,
				local_point + noise,
				color,
				2
			)

			draw_circle(
				local_point + noise,
				3,
				color
			)
