@tool
extends Node2D

var thickness := 200
var noise_strength := 40
var noise_frequency := 0.02
var allow_segment_collision_fallback := true
var regenerate := false:
	set(value):
		regenerate = false
		generate()

var noise := FastNoiseLite.new()
var _fill_parts_root: Node2D = null

@onready var path = $path
@onready var body = $body
@onready var line = $line
@onready var fill = $body/polygon
@onready var collision = $body/collider


func _ready():
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_frequency
	_ensure_fill_parts_root()
	generate()


func generate():

	if path.curve.point_count < 2:
		return

	var baked = path.curve.get_baked_points()
	var edge := []

	for p in baked:
		var n = noise.get_noise_2d(p.x, p.y)
		var offset = Vector2(0, n * noise_strength)
		edge.append(p + offset)

	# Remove near-duplicate points to prevent degenerate polygons
	edge = _deduplicate_points(edge)

	if edge.size() < 2:
		return

	line.points = edge

	var poly := []
	poly.append_array(edge)

	for i in range(edge.size() - 1, -1, -1):
		poly.append(edge[i] + Vector2(0, thickness))

	fill.polygon = PackedVector2Array()
	_apply_multi_polygon_fill(edge)
	_apply_multi_polygon_collision(edge)


func _deduplicate_points(points: Array, min_distance: float = 2.0) -> Array:
	var result := []
	for p in points:
		if result.is_empty() or result[-1].distance_squared_to(p) > min_distance * min_distance:
			result.append(p)
	return result


func _ensure_fill_parts_root() -> void:
	if not is_instance_valid(body):
		body = get_node_or_null("body") as Node2D

	if not is_instance_valid(body):
		return

	if is_instance_valid(_fill_parts_root):
		return

	if body.has_node("fill_parts"):
		_fill_parts_root = body.get_node("fill_parts") as Node2D
		return

	_fill_parts_root = Node2D.new()
	_fill_parts_root.name = "fill_parts"
	body.add_child(_fill_parts_root)


func _get_fill_part(index: int) -> Polygon2D:
	_ensure_fill_parts_root()
	if not is_instance_valid(_fill_parts_root):
		return null

	var node_name := "part_%d" % index

	if _fill_parts_root.has_node(node_name):
		return _fill_parts_root.get_node(node_name) as Polygon2D

	var part := Polygon2D.new()
	part.name = node_name
	part.color = fill.color
	part.texture = fill.texture
	part.texture_offset = fill.texture_offset
	part.texture_rotation = fill.texture_rotation
	part.texture_scale = fill.texture_scale
	_fill_parts_root.add_child(part)
	return part


func _apply_multi_polygon_fill(edge: Array) -> void:
	_ensure_fill_parts_root()
	if not is_instance_valid(_fill_parts_root):
		return

	var part_index := 0
	for i in range(edge.size() - 1):
		var p0: Vector2 = edge[i]
		var p1: Vector2 = edge[i + 1]

		if p0.distance_squared_to(p1) <= 0.0001:
			continue

		var quad := PackedVector2Array([
			p0,
			p1,
			p1 + Vector2(0, thickness),
			p0 + Vector2(0, thickness)
		])

		var part := _get_fill_part(part_index)
		if part == null:
			break
		part.visible = true
		part.polygon = quad
		part.color = fill.color
		part.texture = fill.texture
		part.texture_offset = fill.texture_offset
		part.texture_rotation = fill.texture_rotation
		part.texture_scale = fill.texture_scale
		part_index += 1

	for j in range(part_index, _fill_parts_root.get_child_count()):
		var extra := _fill_parts_root.get_child(j) as Polygon2D
		extra.visible = false
		extra.polygon = PackedVector2Array()


func _ensure_body_ref() -> void:
	if not is_instance_valid(body):
		body = get_node_or_null("body") as Node2D


func _ensure_collision_parts_root() -> void:
	_ensure_body_ref()
	if not is_instance_valid(body):
		return

	# Old versions created nested collider parts under this helper node.
	# Collision shapes must be direct children of the CollisionObject2D.
	if body.has_node("collider_parts"):
		var old_root := body.get_node("collider_parts") as Node
		if old_root != null:
			for child in old_root.get_children():
				old_root.remove_child(child)
				body.add_child(child)
			old_root.queue_free()


func _get_collision_part(index: int) -> CollisionPolygon2D:
	_ensure_collision_parts_root()
	if not is_instance_valid(body):
		return null

	var node_name := "collider_part_%d" % index

	if body.has_node(node_name):
		return body.get_node(node_name) as CollisionPolygon2D

	var part := CollisionPolygon2D.new()
	part.name = node_name
	part.build_mode = CollisionPolygon2D.BUILD_SOLIDS
	body.add_child(part)
	return part


func _apply_multi_polygon_collision(edge: Array) -> void:
	_ensure_collision_parts_root()
	if not is_instance_valid(body):
		return

	# Disable the legacy single collider to avoid conflicts.
	collision.disabled = true
	collision.polygon = PackedVector2Array()

	var part_index := 0
	for i in range(edge.size() - 1):
		var p0: Vector2 = edge[i]
		var p1: Vector2 = edge[i + 1]

		if p0.distance_squared_to(p1) <= 0.0001:
			continue

		var quad := PackedVector2Array([
			p0,
			p1,
			p1 + Vector2(0, thickness),
			p0 + Vector2(0, thickness)
		])

		var part := _get_collision_part(part_index)
		if part == null:
			break
		part.disabled = false
		part.polygon = quad
		part_index += 1

	for child in body.get_children():
		if child is CollisionPolygon2D and String(child.name).begins_with("collider_part_"):
			var idx := int(String(child.name).trim_prefix("collider_part_"))
			if idx >= part_index:
				var extra := child as CollisionPolygon2D
				extra.disabled = true
				extra.polygon = PackedVector2Array()
