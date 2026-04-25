extends Control

var battery_level := 0.0
var current_level := 0.0
var speed_level := 0.0
var phase := 0.0


func _process(delta: float) -> void:
	phase += delta
	queue_redraw()


func set_levels(new_battery_level: float, new_current_level: float, new_speed_level: float) -> void:
	battery_level = clamp(new_battery_level, 0.0, 1.0)
	current_level = clamp(new_current_level, 0.0, 1.0)
	speed_level = clamp(new_speed_level, 0.0, 1.0)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.01, 0.06, 0.06, 0.35), true)

	var grid_color := Color(0.16, 0.36, 0.32, 0.3)
	for step in range(1, 4):
		var x: float = size.x * float(step) / 4.0
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
	for step in range(1, 3):
		var y: float = size.y * float(step) / 3.0
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)

	var baseline: float = lerp(size.y * 0.76, size.y * 0.34, battery_level)
	var amplitude: float = lerp(4.0, size.y * 0.18, current_level)
	var speed_wobble: float = lerp(0.35, 1.35, speed_level)
	var points := PackedVector2Array()

	for index in range(48):
		var t: float = float(index) / 47.0
		var x: float = size.x * t
		var wave_a: float = sin(t * TAU * (2.2 + speed_wobble) + phase * 3.4) * amplitude
		var wave_b: float = sin(t * TAU * (5.5 + current_level * 2.0) - phase * 5.1) * amplitude * 0.42
		var y: float = clamp(baseline + wave_a + wave_b, 3.0, size.y - 3.0)
		points.append(Vector2(x, y))

	draw_polyline(points, Color(0.36, 0.95, 0.79, 0.95), 2.0, true)

	var battery_bar := Rect2(Vector2(6, 6), Vector2(8, (size.y - 12) * battery_level))
	battery_bar.position.y = size.y - 6 - battery_bar.size.y
	draw_rect(Rect2(6, 6, 8, size.y - 12), Color(0.08, 0.16, 0.15, 0.8), true)
	draw_rect(battery_bar, Color(0.31, 0.88, 0.73, 0.9), true)

	var current_bar := Rect2(Vector2(size.x - 14, 6), Vector2(8, (size.y - 12) * current_level))
	current_bar.position.y = size.y - 6 - current_bar.size.y
	draw_rect(Rect2(size.x - 14, 6, 8, size.y - 12), Color(0.12, 0.11, 0.07, 0.8), true)
	draw_rect(current_bar, Color(0.88, 0.71, 0.34, 0.92), true)
