extends Node2D

@export var cone_angle := 30.0
@export var fade_distance := 400.0
@export var line_width := 1.1
@export var fade_steps := 26
@export var line_color := Color(0.2, 1.0, 0.2, 0.9)


func set_scan_visual(new_cone_angle: float, new_fade_distance: float) -> void:
	cone_angle = new_cone_angle
	fade_distance = new_fade_distance
	queue_redraw()


func _draw() -> void:
	draw_fade_line(-cone_angle * 0.5)
	draw_fade_line(cone_angle * 0.5)


func draw_fade_line(angle_degrees: float) -> void:
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

		draw_line(p0, p1, seg_color, line_width)
