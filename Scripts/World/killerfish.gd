extends RigidBody2D

var isOrganic := true
@export var passive_sound: AudioStream = preload("res://Assets/Audio/Sub/Ship/hull_2.wav")
@export_range(0.0, 1.0, 0.01) var passive_loudness := 0.8

var direction := 'left'

@onready var sprite := $sprite
@onready var collider := $collider
@onready var light := $light

func _ready() -> void:
	add_to_group(&"passive_sound_emitters")
	self.apply_impulse(Vector2(-8, 0))
	if (direction == 'left'):
		sprite.scale.x *= -1
		collider.position.x *= 1
		light.position = Vector2(-70, -62)
	if (direction == 'right'):
		sprite.scale.x *= 1
		collider.position.x *= -1
		light.position = Vector2(10, -62)


func get_passive_sonar_stream() -> AudioStream:
	return passive_sound


func get_passive_sonar_loudness() -> float:
	return passive_loudness
