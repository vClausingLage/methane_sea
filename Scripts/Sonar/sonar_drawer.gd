extends Node2D

var pulses = []
var point_map := {}
var simulation_time := 0.0
var line_cache := []
var line_cache_dirty := true

@export var pulse_lifetime := 5.0
@export var point_size := 1.5

@export var bright_color := Color(0.2, 1.0, 0.2)
@export var dark_color := Color(0.0, 0.35, 0.0)

@export var noise := 2.0
@export var grid_size := 8.0
@export var max_points := 1200
@export var active_window := 0.6

# active scan line creation
@export var line_noise := 0.7
@export var max_line_segment_length := 45.0


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
	draw_points()
	draw_nearest_neighbor_line()


func register_hit(world_point: Vector2):
	var cell = world_to_cell(world_point)

	if point_map.has(cell):
		var entry = point_map[cell]
		entry["point"] = entry["point"].lerp(world_point, 0.45)
		entry["age"] = 0.0
		entry["last_seen"] = simulation_time
		line_cache_dirty = true
		return

	point_map[cell] = {
		"point": world_point,
		"age": 0.0,
		"last_seen": simulation_time
	}
	line_cache_dirty = true

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

	if remove_count > 0:
		line_cache_dirty = true


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


func draw_nearest_neighbor_line():
	if line_cache_dirty:
		rebuild_line_cache()

	if line_cache.size() < 2:
		return

	for i in range(line_cache.size() - 1):
		var a = line_cache[i]
		var b = line_cache[i + 1]

		if a == null or b == null:
			continue

		if max_line_segment_length > 0.0 and a["point"].distance_to(b["point"]) > max_line_segment_length:
			continue

		var color = dark_color
		if a["age"] <= active_window or b["age"] <= active_window:
			color = bright_color

		var start = jittered_local(a["point"], float(i) * 31.0)
		var ending = jittered_local(b["point"], float(i) * 31.0 + 13.0)

		draw_line(
			start,
			ending,
			color * 0.45,
			3
		)

		draw_line(
			start,
			ending,
			color,
			1.25
		)


func rebuild_line_cache():
	line_cache.clear()

	if point_map.size() < 2:
		line_cache_dirty = false
		return

	var remaining = []
	for data in point_map.values():
		remaining.append(data)

	var start_index = index_of_latest_point(remaining)
	var current = remaining[start_index]
	line_cache.append(current)
	remaining.remove_at(start_index)
	var max_segment_sq = max_line_segment_length * max_line_segment_length

	while not remaining.is_empty():
		var nearest_idx = 0
		var nearest_dist := INF

		for i in range(remaining.size()):
			var d = current["point"].distance_squared_to(remaining[i]["point"])
			if d < nearest_dist:
				nearest_dist = d
				nearest_idx = i

		if max_line_segment_length > 0.0 and nearest_dist > max_segment_sq:
			line_cache.append(null)
			var restart_index = index_of_latest_point(remaining)
			current = remaining[restart_index]
			line_cache.append(current)
			remaining.remove_at(restart_index)
			continue

		current = remaining[nearest_idx]
		line_cache.append(current)
		remaining.remove_at(nearest_idx)

	line_cache_dirty = false


func index_of_latest_point(points: Array) -> int:
	var index = 0
	var latest = points[0]["last_seen"]

	for i in range(1, points.size()):
		if points[i]["last_seen"] > latest:
			latest = points[i]["last_seen"]
			index = i

	return index


func jittered_local(world_point: Vector2, seed_offset: float) -> Vector2:
	if line_noise <= 0.0:
		return to_local(world_point)

	var seed_a = world_point + Vector2(seed_offset, seed_offset * 0.37)
	var seed_b = world_point + Vector2(seed_offset * 0.21, seed_offset)
	var offset = Vector2(pseudo_noise(seed_a), pseudo_noise(seed_b)) * line_noise
	return to_local(world_point + offset)


func pseudo_noise(v: Vector2) -> float:
	var raw = sin(v.dot(Vector2(12.9898, 78.233))) * 43758.5453
	var fract_part = raw - floor(raw)
	return fract_part * 2.0 - 1.0
