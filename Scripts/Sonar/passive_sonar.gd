extends Node2D

var emitter_group := &"passive_sound_emitters"
var base_range := 1200.0
var min_audible_strength := 0.03
var max_simultaneous_contacts := 5

var full_strength_volume_db := -8.0
var directional_hint_radius := 120.0
var directional_hint_width := 4.0
var directional_hint_color := Color(0.373, 0.597, 0.643, 0.851)
var directional_fade_speed := 3.2

var engine_penalty_at_full := 0.55
var engine_penalty_volume_db := 10.0

var contact_players := {}
var visual_contacts := []


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_update_contacts(delta)
	queue_redraw()


func _draw() -> void:
	for entry in visual_contacts:
		if entry["strength"] <= 0.0:
			continue

		var dir: Vector2 = entry["direction"]
		var anchor := dir * directional_hint_radius
		var tail := dir * (directional_hint_radius - 22.0)
		var side : Vector2 = dir.orthogonal() * (6.0 + 8.0 * entry["strength"])

		var color := directional_hint_color
		color.a *= entry["strength"]

		draw_line(tail, anchor, color, directional_hint_width)
		draw_colored_polygon([anchor, tail + side, tail - side], color)


func _update_contacts(delta: float) -> void:
	var emitters := get_tree().get_nodes_in_group(emitter_group)
	if emitters.is_empty():
		_fade_visual_contacts(delta)
		_stop_all_contact_players()
		return

	var engine_mask := _get_engine_mask()
	var effective_range := PassiveSonarLogic.calculate_effective_range(base_range, engine_penalty_at_full, engine_mask)

	var candidates := []
	for emitter in emitters:
		if not (emitter is Node2D):
			continue

		if emitter == self or emitter == get_parent():
			continue

		if not is_instance_valid(emitter):
			continue

		var stream: AudioStream = _resolve_emitter_stream(emitter)
		if stream == null:
			continue

		var distance := global_position.distance_to((emitter as Node2D).global_position)
		if distance > effective_range:
			continue

		var strength := PassiveSonarLogic.calculate_strength(distance, effective_range, _resolve_emitter_loudness(emitter), engine_mask)
		if strength < min_audible_strength:
			continue

		candidates.append({
			"node": emitter,
			"stream": stream,
			"strength": strength,
			"direction": PassiveSonarLogic.calculate_direction(global_position, (emitter as Node2D).global_position)
		})

	candidates.sort_custom(func(a, b): return a["strength"] > b["strength"])
	if candidates.size() > max_simultaneous_contacts:
		candidates.resize(max_simultaneous_contacts)

	var active_ids := {}
	for entry in candidates:
		var emitter: Node = entry["node"]
		var emitter_id := emitter.get_instance_id()
		active_ids[emitter_id] = true
		_update_or_create_contact_player(emitter_id, entry["stream"], entry["strength"], engine_mask)

	for emitter_id in contact_players.keys():
		if active_ids.has(emitter_id):
			continue

		var stale_player: AudioStreamPlayer = contact_players[emitter_id]
		if stale_player != null:
			stale_player.stop()
			stale_player.queue_free()
		contact_players.erase(emitter_id)

	_update_visual_contacts(candidates, delta)


func _resolve_emitter_stream(emitter: Object) -> AudioStream:
	if emitter.has_method("get_passive_sonar_stream"):
		return emitter.call("get_passive_sonar_stream") as AudioStream

	if emitter.has_meta("passive_sound"):
		return emitter.get_meta("passive_sound") as AudioStream

	if _has_property(emitter, &"passive_sound"):
		return emitter.get("passive_sound") as AudioStream

	return null


func _resolve_emitter_loudness(emitter: Object) -> float:
	if emitter.has_method("get_passive_sonar_loudness"):
		return float(emitter.call("get_passive_sonar_loudness"))

	if emitter.has_meta("passive_loudness"):
		return clamp(float(emitter.get_meta("passive_loudness")), 0.0, 1.0)

	if _has_property(emitter, &"passive_loudness"):
		return clamp(float(emitter.get("passive_loudness")), 0.0, 1.0)

	return 1.0


func _update_or_create_contact_player(emitter_id: int, stream: AudioStream, strength: float, engine_mask: float) -> void:
	var player := contact_players.get(emitter_id, null) as AudioStreamPlayer
	if player == null:
		player = AudioStreamPlayer.new()
		player.name = "contact_%d" % emitter_id
		player.bus = "Master"
		add_child(player)
		contact_players[emitter_id] = player

	if player.stream != stream:
		player.stream = stream

	player.volume_db = PassiveSonarLogic.calculate_volume_db(strength, full_strength_volume_db, engine_mask, engine_penalty_volume_db)

	if not player.playing:
		player.play()


func _update_visual_contacts(candidates: Array, delta: float) -> void:
	for entry in visual_contacts:
		entry["strength"] = max(0.0, entry["strength"] - directional_fade_speed * delta)

	for candidate in candidates:
		var direction: Vector2 = candidate["direction"]
		var strength: float = candidate["strength"]
		visual_contacts.append({
			"direction": direction,
			"strength": strength
		})

	if visual_contacts.size() > 18:
		visual_contacts = visual_contacts.slice(visual_contacts.size() - 18, visual_contacts.size())


func _fade_visual_contacts(delta: float) -> void:
	visual_contacts = PassiveSonarLogic.fade_contacts(visual_contacts, directional_fade_speed, delta)


func _stop_all_contact_players() -> void:
	for emitter_id in contact_players.keys():
		var player: AudioStreamPlayer = contact_players[emitter_id]
		if player != null:
			player.stop()
			player.queue_free()
	contact_players.clear()


func _get_engine_mask() -> float:
	var host := get_parent()
	if host == null:
		return 0.0

	if _has_property(host, &"current_thrust_multiplier"):
		return clamp(abs(float(host.get("current_thrust_multiplier"))), 0.0, 1.0)

	return 0.0


func _has_property(target: Object, property_name: StringName) -> bool:
	for property_data in target.get_property_list():
		if property_data.get("name") == property_name:
			return true
	return false
