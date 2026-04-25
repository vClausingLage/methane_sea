extends Node2D

@export_node_path("Node2D") var target_path: NodePath = ^"../Player"
@export var overscan := Vector2(320.0, 240.0)

@onready var target: Node2D = get_node_or_null(target_path)
@onready var backdrop: ColorRect = $Backdrop

func _ready() -> void:
	_update_backdrop_size()


func _process(_delta: float) -> void:
	if target == null:
		target = get_node_or_null(target_path)

	if target:
		global_position = target.global_position

	_update_backdrop_size()


func _update_backdrop_size() -> void:
	if backdrop == null:
		return

	var viewport_size := get_viewport_rect().size + overscan * 2.0
	backdrop.position = -viewport_size * 0.5
	backdrop.size = viewport_size
