extends Node2D

@onready var sea_player: AudioStreamPlayer2D = $sea_ambiance_player

func _ready() -> void:
	if sea_player:
		if not sea_player.finished.is_connected(_on_sea_ambiance_finished):
			sea_player.finished.connect(_on_sea_ambiance_finished)
		_play_sea_ambiance()


func _play_sea_ambiance() -> void:
	if sea_player == null or sea_player.stream == null or sea_player.playing:
		return

	sea_player.play()


func _on_sea_ambiance_finished() -> void:
	_play_sea_ambiance()
