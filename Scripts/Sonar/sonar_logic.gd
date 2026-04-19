class_name SonarLogic
extends RefCounted


static func build_ray_directions(cone_angle: float, rays: int, global_rotation: float) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	if rays <= 0:
		return directions

	var start_angle := -cone_angle / 2.0
	var step := cone_angle / float(rays)
	for i in range(rays):
		var angle := deg_to_rad(start_angle + i * step) + global_rotation
		directions.append(Vector2.RIGHT.rotated(angle))

	return directions


static func build_echo(origin: Vector2, hit_pos: Vector2, wave_speed: float, max_range: float, is_organic_hit: bool) -> Dictionary:
	var distance := origin.distance_to(hit_pos)
	if distance >= max_range:
		return {}

	return {
		"point": hit_pos,
		"delay": distance / wave_speed,
		"noise": false,
		"organic": is_organic_hit
	}


static func is_organic_collider(collider: Object) -> bool:
	if collider == null:
		return false

	var current := collider
	while current != null:
		if _object_has_property(current, &"isOrganic") and bool(current.get("isOrganic")):
			return true

		if current is Node:
			current = current.get_parent()
		else:
			current = null

	return false


static func _object_has_property(target: Object, property_name: StringName) -> bool:
	for property_data in target.get_property_list():
		if property_data.get("name") == property_name:
			return true
	return false
