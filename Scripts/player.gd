extends RigidBody2D

@export var thrust := 50.0
@export var max_speed := 25.0
@export var water_drag := 0.90

func _physics_process(_delta):

	var direction = Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D):
		direction.x += 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		apply_central_force(direction * thrust)

	# clamp velocity
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

	# water drag
	linear_velocity *= water_drag
