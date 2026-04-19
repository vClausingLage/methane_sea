extends GutTest

const PassiveSonarLogicScript := preload("res://Scripts/Sonar/passive_sonar_logic.gd")


func test_calculate_effective_range_applies_engine_penalty_with_minimum() -> void:
	assert_eq(PassiveSonarLogicScript.calculate_effective_range(1200.0, 0.55, 1.0), 540.0)
	assert_eq(PassiveSonarLogicScript.calculate_effective_range(120.0, 0.55, 1.0), 100.0)


func test_calculate_strength_uses_distance_loudness_and_engine_mask() -> void:
	var strength := PassiveSonarLogicScript.calculate_strength(250.0, 1000.0, 0.8, 0.5)

	assert_almost_eq(strength, 0.5, 0.001)


func test_calculate_strength_returns_zero_outside_range() -> void:
	assert_eq(PassiveSonarLogicScript.calculate_strength(1001.0, 1000.0, 1.0, 0.0), 0.0)


func test_calculate_volume_db_interpolates_strength_and_engine_penalty() -> void:
	var volume_db := PassiveSonarLogicScript.calculate_volume_db(0.5, -8.0, 0.5, 10.0)

	assert_almost_eq(volume_db, -29.0, 0.001)


func test_calculate_direction_points_from_listener_to_emitter() -> void:
	var direction := PassiveSonarLogicScript.calculate_direction(Vector2.ZERO, Vector2(0.0, 10.0))

	assert_true(direction.is_equal_approx(Vector2.DOWN))


func test_fade_contacts_reduces_strength_and_removes_quiet_entries() -> void:
	var contacts := [
		{"direction": Vector2.RIGHT, "strength": 1.0},
		{"direction": Vector2.LEFT, "strength": 0.02}
	]

	var faded := PassiveSonarLogicScript.fade_contacts(contacts, 0.5, 1.0)

	assert_eq(faded.size(), 1)
	assert_eq(faded[0]["direction"], Vector2.RIGHT)
	assert_almost_eq(faded[0]["strength"], 0.5, 0.001)
