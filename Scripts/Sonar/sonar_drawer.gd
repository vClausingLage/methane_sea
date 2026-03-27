extends Node2D

var pulses = []
var point_map := {}
var simulation_time := 0.0

@export var pulse_lifetime := 5.0
@export var point_size := 1.0

@export var bright_color := Color(0.2, 1.0, 0.2)
@export var dark_color := Color(0.0, 0.35, 0.0)

@export var noise := 2.0
@export var grid_size := 8.0
@export var max_points := 1200
@export var active_window := 0.6

# active scan line creation
@export var connection_distance := 20.0
@export var min_connection_length := 10.0
@export var max_connection_length := 20.0


func start_pulse(echoes):
	pulses.append({
		"echoes": echoes,
		"time": 0.0
	})


func _process(delta):
	simulation_time += delta

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

				register_hit(p)

	pulses = pulses.filter(func(p): return p.time < pulse_lifetime)

	for cell in point_map.keys():
		point_map[cell]["age"] += delta

	queue_redraw()


func _draw():
	var active_points = collect_active_points()
	draw_points()
	draw_active_segments(active_points)


func register_hit(world_point: Vector2):
	var cell = world_to_cell(world_point)

	if point_map.has(cell):
		var entry = point_map[cell]
		entry["point"] = entry["point"].lerp(world_point, 0.45)
		entry["age"] = 0.0
		entry["last_seen"] = simulation_time
		return

	point_map[cell] = {
		"point": world_point,
		"age": 0.0,
		"last_seen": simulation_time
	}

	trim_point_budget()


func trim_point_budget():
	if point_map.size() <= max_points:
		return

	var indexed_points = []
	for cell in point_map.keys():
		indexed_points.append({
			"cell": cell,
			"last_seen": point_map[cell]["last_seen"]
		})

	indexed_points.sort_custom(func(a, b): return a["last_seen"] < b["last_seen"])

	var remove_count = point_map.size() - max_points
	for i in range(remove_count):
		point_map.erase(indexed_points[i]["cell"])


func world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(p.x / grid_size)),
		int(floor(p.y / grid_size))
	)


func collect_active_points() -> Array:
	var active = []
	for point_data in point_map.values():
		if point_data["age"] <= active_window:
			active.append(point_data)
	return active


func draw_points():
	for m in point_map.values():

		var color = bright_color

		if m["age"] > active_window:
			color = dark_color

		draw_circle(
			to_local(m["point"]),
			point_size,
			color
		)


func draw_active_segments(active_points: Array):
	if active_points.is_empty():
		return

	var active_cell_map := {}
	for p in active_points:
		active_cell_map[world_to_cell(p["point"])] = p

	var search_radius = int(ceil(connection_distance / grid_size))

	for p1 in active_points:
		var origin = p1["point"]
		var origin_cell = world_to_cell(origin)
		var nearest = null
		var nearest_distance = INF

		for x in range(-search_radius, search_radius + 1):
			for y in range(-search_radius, search_radius + 1):
				var neighbor_cell = origin_cell + Vector2i(x, y)

				if not active_cell_map.has(neighbor_cell):
					continue

				var p2 = active_cell_map[neighbor_cell]
				if p2 == p1:
					continue

				var d = origin.distance_to(p2["point"])
				if d <= 0.001 or d > connection_distance or d >= nearest_distance:
					continue

				nearest = p2
				nearest_distance = d

		if nearest == null:
			continue

		var dir = (nearest["point"] - origin).normalized()
		var segment_length = clamp(nearest_distance, min_connection_length, max_connection_length)
		var segment_end = origin + dir * segment_length

		draw_line(
			to_local(origin),
			to_local(segment_end),
			bright_color * 0.5,
			3.0
		)

		draw_line(
			to_local(origin),
			to_local(segment_end),
			bright_color,
			1.5
		)
