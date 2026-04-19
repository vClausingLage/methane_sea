@tool
extends Node2D

@export var fill_depth := 300.0:
	set(value):
		fill_depth = maxf(value, 1.0)

@export var noise_strength := 120.0:
	set(value):
		noise_strength = value

@export var noise_frequency := 0.004:
	set(value):
		noise_frequency = value

@export var noise_octaves := 4:
	set(value):
		noise_octaves = maxi(value, 1)

@export var noise_gain := 0.45:
	set(value):
		noise_gain = value

@export var noise_lacunarity := 2.0:
	set(value):
		noise_lacunarity = value

@export var terrain_seed := 0:
	set(value):
		terrain_seed = value

@export var edge_line_width := 20.0:
	set(value):
		edge_line_width = maxf(value, 1.0)

@export var regenerate := false:
	set(value):
		regenerate = false
		if value:
			terrain_seed = randi()
			generate()

var noise := FastNoiseLite.new()

var path: Path2D
var polygon: Polygon2D
var collision_body: StaticBody2D
var collision: CollisionPolygon2D
var edge_line: Line2D


func _ready() -> void:
	_resolve_nodes()
	_restore_collision_from_saved_edge()


func generate() -> void:
	_resolve_nodes()

	if path == null or polygon == null:
		push_warning("Cave.gd: Missing required nodes Path2D and Polygon2D.")
		return

	if path.curve == null:
		path.curve = _make_default_curve()

	if path.curve.point_count < 2:
		return

	_configure_noise()

	var edge := _deduplicate_points(Array(path.curve.get_baked_points()))
	if edge.size() < 2:
		return

	for i in range(edge.size()):
		var p: Vector2 = edge[i]
		var broad := noise.get_noise_2d(p.x, p.y) * noise_strength
		var detail := noise.get_noise_2d(p.x * 2.7 + 431.0, p.y - 97.0) * noise_strength * 0.25
		edge[i] = p + Vector2(0.0, broad + detail)

	var fill_polygon := PackedVector2Array()
	for p in edge:
		fill_polygon.append(p)

	var bottom_y := _get_bottom_y(edge)
	for i in range(edge.size() - 1, -1, -1):
		var p: Vector2 = edge[i]
		fill_polygon.append(Vector2(p.x, bottom_y))

	polygon.position = path.position
	polygon.polygon = fill_polygon
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	if collision != null:
		if collision_body != null:
			collision_body.position = path.position
			collision.position = Vector2.ZERO
		else:
			collision.position = path.position
		collision.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		collision.disabled = true
		collision.polygon = PackedVector2Array()

	_apply_segment_collision(edge, bottom_y)

	_ensure_edge_line()
	if edge_line != null:
		edge_line.position = path.position
		edge_line.points = PackedVector2Array(edge)
		edge_line.width = edge_line_width
		edge_line.texture = polygon.texture
		edge_line.texture_mode = Line2D.LINE_TEXTURE_TILE


func _resolve_nodes() -> void:
	path = get_node_or_null("Path2D") as Path2D
	polygon = get_node_or_null("Polygon2D") as Polygon2D
	collision_body = get_node_or_null("StaticBody2D") as StaticBody2D
	collision = get_node_or_null("StaticBody2D/CollisionPolygon2D") as CollisionPolygon2D
	if collision == null:
		collision = get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D


func _get_collision_parent() -> Node:
	if collision_body != null:
		return collision_body
	return self


func _get_collision_part(index: int) -> CollisionPolygon2D:
	var parent := _get_collision_parent()
	var node_name := "ColliderPart%d" % index

	if parent.has_node(node_name):
		return parent.get_node(node_name) as CollisionPolygon2D

	var part := CollisionPolygon2D.new()
	part.name = node_name
	part.build_mode = CollisionPolygon2D.BUILD_SOLIDS
	parent.add_child(part)
	return part


func _apply_segment_collision(edge: Array, bottom_y: float) -> void:
	var parent := _get_collision_parent()
	var part_index := 0

	for i in range(edge.size() - 1):
		var p0: Vector2 = edge[i]
		var p1: Vector2 = edge[i + 1]

		if p0.distance_squared_to(p1) <= 0.0001:
			continue

		var part := _get_collision_part(part_index)
		if part == null:
			break

		part.disabled = false
		part.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		part.polygon = PackedVector2Array([
			p0,
			p1,
			Vector2(p1.x, bottom_y),
			Vector2(p0.x, bottom_y)
		])
		part_index += 1

	for child in parent.get_children():
		if child is CollisionPolygon2D and String(child.name).begins_with("ColliderPart"):
			var idx := int(String(child.name).trim_prefix("ColliderPart"))
			if idx >= part_index:
				var extra := child as CollisionPolygon2D
				extra.disabled = true
				extra.polygon = PackedVector2Array()


func _restore_collision_from_saved_edge() -> void:
	if Engine.is_editor_hint():
		return

	edge_line = get_node_or_null("EdgeLine2D") as Line2D
	if edge_line == null or edge_line.points.size() < 2:
		return

	if collision != null:
		collision.disabled = true
		collision.polygon = PackedVector2Array()

	var edge := []
	for point in edge_line.points:
		edge.append(point)

	_apply_segment_collision(edge, _get_saved_bottom_y(edge))


func _get_saved_bottom_y(edge: Array) -> float:
	if polygon != null and polygon.polygon.size() > 0:
		var bottom_y := polygon.polygon[0].y
		for point in polygon.polygon:
			bottom_y = maxf(bottom_y, point.y)
		return bottom_y

	return _get_bottom_y(edge)


func _configure_noise() -> void:
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = terrain_seed
	noise.frequency = noise_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = noise_octaves
	noise.fractal_gain = noise_gain
	noise.fractal_lacunarity = noise_lacunarity


func _deduplicate_points(points: Array, min_distance: float = 3.0) -> Array:
	var result := []
	for p in points:
		if result.is_empty() or result[-1].distance_squared_to(p) > min_distance * min_distance:
			result.append(p)
	return result


func _get_bottom_y(edge: Array) -> float:
	var bottom_y: float = edge[0].y
	for p in edge:
		bottom_y = maxf(bottom_y, p.y)
	return bottom_y + fill_depth


func _ensure_edge_line() -> void:
	if edge_line != null and is_instance_valid(edge_line):
		return

	edge_line = get_node_or_null("EdgeLine2D") as Line2D
	if edge_line != null:
		return

	edge_line = Line2D.new()
	edge_line.name = "EdgeLine2D"
	edge_line.z_index = 1
	add_child(edge_line)


func _make_default_curve() -> Curve2D:
	var curve := Curve2D.new()
	curve.add_point(Vector2(-900.0, 200.0))
	curve.add_point(Vector2(-450.0, 260.0))
	curve.add_point(Vector2(0.0, 180.0))
	curve.add_point(Vector2(450.0, 240.0))
	curve.add_point(Vector2(900.0, 160.0))
	return curve
