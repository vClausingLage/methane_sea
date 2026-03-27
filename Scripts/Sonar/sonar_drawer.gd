extends Node2D

var pulses = []
var map_points = []

@export var pulse_lifetime := 5.0
@export var point_size := 3.0

@export var bright_color := Color(0.2, 1.0, 0.2)
@export var dark_color := Color(0.0, 0.35, 0.0)

@export var noise := 2.0

# edge creation
@export var connection_distance := 20.0


func start_pulse(echoes):
	pulses.append({
		"echoes": echoes,
		"time": 0.0
	})


func _process(delta):
	for pulse in pulses:

		pulse.time += delta

		for echo in pulse.echoes:

			if echo.has("revealed"):
				continue

			if pulse.time >= echo.delay:

				echo.revealed = true

				var p = echo.point

				p += Vector2(
					randf_range(-noise, noise),
					randf_range(-noise, noise)
				)

				map_points.append({
					"point": p,
					"age": 0.0
				})

	pulses = pulses.filter(func(p): return p.time < pulse_lifetime)

	for m in map_points:
		m.age += delta

	queue_redraw()
	print("map points: ", map_points.size())


func _draw():
	draw_points()
	draw_edges()

func draw_points():
	for m in map_points:

		var color = bright_color

		if m.age > 0.6:
			color = dark_color

		draw_circle(
			to_local(m.point),
			point_size,
			color
		)


func draw_edges():

	for i in range(map_points.size()):

		var p1 = map_points[i]

		for j in range(i + 1, map_points.size()):

			var p2 = map_points[j]

			if p1.point.distance_to(p2.point) > connection_distance:
				continue

			var color = dark_color

			if p1.age < 0.6 or p2.age < 0.6:
				color = bright_color

			draw_line(
				to_local(p1.point),
				to_local(p2.point),
				color * 0.5,
				4
			)

			draw_line(
				to_local(p1.point),
				to_local(p2.point),
				color,
				1.5
			)
