extends RigidBody2D


func _ready() -> void:
	print('fish ready')
	print(self.position.y)
	self.apply_impulse(Vector2(-2, 0))


func _process(delta: float) -> void:
	pass
