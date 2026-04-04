extends RigidBody2D


func _ready() -> void:
	self.apply_impulse(Vector2(-2, 0))


func _process(delta: float) -> void:
	pass
