class_name PassiveSonarLogic
extends RefCounted


static func calculate_effective_range(base_range: float, engine_penalty_at_full: float, engine_mask: float) -> float:
	return max(100.0, base_range * (1.0 - engine_penalty_at_full * clamp(engine_mask, 0.0, 1.0)))


static func calculate_strength(distance: float, effective_range: float, loudness: float, engine_mask: float) -> float:
	if distance > effective_range:
		return 0.0

	var normalized := 1.0 - (distance / effective_range)
	var base_strength := clampf(normalized * clamp(loudness, 0.0, 1.0), 0.0, 1.0)
	return max(0.0, base_strength - clampf(engine_mask, 0.0, 1.0) * 0.2)


static func calculate_volume_db(strength: float, full_strength_volume_db: float, engine_mask: float, engine_penalty_volume_db: float) -> float:
	var clamped_strength := clampf(strength, 0.0, 1.0)
	return lerp(-40.0, full_strength_volume_db, clamped_strength) - clampf(engine_mask, 0.0, 1.0) * engine_penalty_volume_db


static func calculate_direction(listener_position: Vector2, emitter_position: Vector2) -> Vector2:
	return (emitter_position - listener_position).normalized()


static func fade_contacts(visual_contacts: Array, fade_speed: float, delta: float, minimum_strength := 0.01) -> Array:
	var faded_contacts := []
	for entry in visual_contacts:
		var faded_entry: Dictionary = entry.duplicate()
		faded_entry["strength"] = max(0.0, float(faded_entry["strength"]) - fade_speed * delta)
		if faded_entry["strength"] > minimum_strength:
			faded_contacts.append(faded_entry)

	return faded_contacts
