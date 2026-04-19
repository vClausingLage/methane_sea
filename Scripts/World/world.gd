extends Node2D

@onready var sea_player: AudioStreamPlayer2D = $sea_ambiance_player

func _ready() -> void:
	if sea_player:
		sea_player.play()
