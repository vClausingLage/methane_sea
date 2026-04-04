extends Node2D

var cone_angle := 30.0
var fade_distance := 400.0
var line_width := 1.1
var fade_steps := 26
var line_color := Color(0.2, 1.0, 0.2, 0.9)
var emit_flash_duration := 0.2
var emit_flash_boost := 1.9
var emit_fill_alpha := 0.24
var emit_flash_distance := 600.0
var emit_wave_speed := 400.0

var emit_flash_time := 0.0


func set_scan_visual(new_cone_angle: float, new_fade_distance: float) -> void:
	cone_angle = new_cone_angle
	fade_distance = new_fade_distance
	queue_redraw()


func trigger_emit_flash(scan_distance: float = -1.0, scan_wave_speed: float = -1.0) -> void:
	if scan_distance > 0.0:
		emit_flash_distance = scan_distance

	if scan_wave_speed > 0.0:
		emit_wave_speed = scan_wave_speed

	if emit_wave_speed > 0.0 and emit_flash_distance > 0.0:
		emit_flash_duration = max(0.06, emit_flash_distance / emit_wave_speed)

	emit_flash_time = emit_flash_duration
	queue_redraw()


func _process(delta: float) -> void:
	if emit_flash_time <= 0.0:
		return

	emit_flash_time = max(0.0, emit_flash_time - delta)
	queue_redraw()


func _draw() -> void:
	var flash_t := 0.0
	if emit_flash_duration > 0.0:
		flash_t = emit_flash_time / emit_flash_duration

	var flash_strength : float = 1.0 + max(0.0, emit_flash_boost - 1.0) * flash_t

	draw_fade_line(-cone_angle * 0.5, flash_strength)
	draw_fade_line(cone_angle * 0.5, flash_strength)

	if flash_t > 0.0:
		draw_emit_pulse(flash_t)


func draw_fade_line(angle_degrees: float, intensity: float = 1.0) -> void:
	if fade_distance <= 0.0:
		return

	var steps = max(1, fade_steps)
	var dir = Vector2.RIGHT.rotated(deg_to_rad(angle_degrees))

	for i in range(steps):
		var t0 = float(i) / float(steps)
		var t1 = float(i + 1) / float(steps)
		var p0 = dir * fade_distance * t0
		var p1 = dir * fade_distance * t1

		var seg_color = line_color
		seg_color.a *= pow(1.0 - t0, 1.3)
		seg_color *= intensity
		seg_color.a = min(seg_color.a, 1.0)

		draw_line(p0, p1, seg_color, line_width)


func draw_emit_pulse(flash_t: float) -> void:
	var progress = 1.0 - flash_t
	var target_distance = max(emit_flash_distance, fade_distance)
	var radius = lerp(14.0, max(24.0, target_distance * 0.95), progress)
	var alpha = 0.85 * flash_t
	var pulse_color = Color(0.35, 1.0, 0.35, alpha)
	var start_angle = deg_to_rad(-cone_angle * 0.5)
	var end_angle = deg_to_rad(cone_angle * 0.5)

	draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 32, pulse_color, 4.0)


func draw_emit_fill(flash_t: float) -> void:
	var target_distance = max(emit_flash_distance, fade_distance)
	var fill_distance = max(28.0, target_distance * 0.42)
	var left = Vector2.RIGHT.rotated(deg_to_rad(-cone_angle * 0.5)) * fill_distance
	var right = Vector2.RIGHT.rotated(deg_to_rad(cone_angle * 0.5)) * fill_distance
	var center = (left + right) * 0.5
	var color = Color(0.35, 1.0, 0.35, emit_fill_alpha * flash_t)

	draw_colored_polygon([Vector2.ZERO, left, center, right], color)
