extends GutTest

const SonarLogicScript := preload("res://Scripts/Sonar/sonar_logic.gd")


class OrganicBody:
	extends Node
	var isOrganic := true


class OrganicParent:
	extends Node
	var isOrganic := true


func test_build_ray_directions_spreads_rays_across_cone() -> void:
	var directions := SonarLogicScript.build_ray_directions(30.0, 3, 0.0)

	assert_eq(directions.size(), 3)
	assert_true(directions[0].is_equal_approx(Vector2.RIGHT.rotated(deg_to_rad(-15.0))))
	assert_true(directions[1].is_equal_approx(Vector2.RIGHT.rotated(deg_to_rad(-5.0))))
	assert_true(directions[2].is_equal_approx(Vector2.RIGHT.rotated(deg_to_rad(5.0))))


func test_build_ray_directions_returns_empty_when_no_rays() -> void:
	assert_eq(SonarLogicScript.build_ray_directions(30.0, 0, 0.0), [])


func test_build_echo_includes_delay_and_organic_flag() -> void:
	var echo := SonarLogicScript.build_echo(Vector2.ZERO, Vector2(0.0, 200.0), 400.0, 600.0, true)

	assert_eq(echo["point"], Vector2(0.0, 200.0))
	assert_eq(echo["delay"], 0.5)
	assert_false(echo["noise"])
	assert_true(echo["organic"])


func test_build_echo_ignores_hits_at_max_range() -> void:
	var echo := SonarLogicScript.build_echo(Vector2.ZERO, Vector2(600.0, 0.0), 400.0, 600.0, false)

	assert_true(echo.is_empty())


func test_is_organic_collider_detects_metadata_on_parent() -> void:
	var parent := Node.new()
	var collider := Node.new()
	parent.set_meta("isOrganic", true)
	parent.add_child(collider)
	add_child_autofree(parent)

	assert_true(SonarLogicScript.is_organic_collider(collider))


func test_is_organic_collider_detects_snake_case_property() -> void:
	var collider := OrganicBody.new()
	add_child_autofree(collider)

	assert_true(SonarLogicScript.is_organic_collider(collider))


func test_is_organic_collider_returns_false_for_null() -> void:
	assert_false(SonarLogicScript.is_organic_collider(null))
