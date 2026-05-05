extends CanvasLayer

const PORTRAIT_T := preload("res://Assets/Figures/portrait1.png")
const PORTRAIT_J := preload("res://Assets/Figures/portrait2.png")
const PORTRAIT_SIZE := Vector2(250, 250)
const PORTRAIT_MARGIN := 24.0

@export_node_path("Node") var player_path: NodePath = ^"../Player"

var portrait_t: TextureRect
var portrait_j: TextureRect

@onready var player: Node = get_node_or_null(player_path)


func _ready() -> void:
	_create_voice_portraits()
	_connect_voice_portrait_signals()


func _create_voice_portraits() -> void:
	portrait_j = _create_voice_portrait(PORTRAIT_J, true)
	portrait_t = _create_voice_portrait(PORTRAIT_T, false)


func _create_voice_portrait(texture: Texture2D, align_left: bool) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.texture = texture
	portrait.custom_minimum_size = PORTRAIT_SIZE
	portrait.size = PORTRAIT_SIZE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.visible = false
	portrait.z_index = 100

	if align_left:
		portrait.anchor_left = 0.0
		portrait.anchor_right = 0.0
		portrait.offset_left = PORTRAIT_MARGIN
		portrait.offset_right = PORTRAIT_MARGIN + PORTRAIT_SIZE.x
	else:
		portrait.anchor_left = 1.0
		portrait.anchor_right = 1.0
		portrait.offset_left = -PORTRAIT_MARGIN - PORTRAIT_SIZE.x
		portrait.offset_right = -PORTRAIT_MARGIN

	portrait.anchor_top = 0.0
	portrait.anchor_bottom = 0.0
	portrait.offset_top = PORTRAIT_MARGIN
	portrait.offset_bottom = PORTRAIT_MARGIN + PORTRAIT_SIZE.y
	add_child(portrait)
	return portrait


func _connect_voice_portrait_signals() -> void:
	if player == null:
		push_warning("PortraitManager expects a player node with voice line signals.")
		return
	if player.has_signal("voice_line_started"):
		player.voice_line_started.connect(_on_voice_line_started)
	if player.has_signal("voice_line_finished"):
		player.voice_line_finished.connect(_on_voice_line_finished)


func _on_voice_line_started(speaker: StringName) -> void:
	match speaker:
		&"T":
			_set_portrait_speaking(portrait_t, portrait_j)
		&"J":
			_set_portrait_speaking(portrait_j, portrait_t)


func _on_voice_line_finished(speaker: StringName) -> void:
	match speaker:
		&"T":
			if portrait_t:
				portrait_t.visible = false
		&"J":
			if portrait_j:
				portrait_j.visible = false


func _set_portrait_speaking(active_portrait: TextureRect, inactive_portrait: TextureRect) -> void:
	if inactive_portrait:
		inactive_portrait.visible = false
	if active_portrait:
		active_portrait.visible = true
