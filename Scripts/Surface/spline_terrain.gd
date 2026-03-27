@tool
extends Node2D

@export var thickness := 200
@export var noise_strength := 40
@export var noise_frequency := 0.02
@export var regenerate := false:
	set(value):
		regenerate = false
		generate()

@onready var path = $path
@onready var line = $line
@onready var fill = $body/polygon
@onready var collision = $body/collider

var noise := FastNoiseLite.new()

func _ready():
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_frequency
	generate()

#func _process(_delta):
	#if Engine.is_editor_hint():
		#generate()

func generate():

	if path.curve.point_count < 2:
		return

	var baked = path.curve.get_baked_points()
	var edge := []

	for p in baked:
		var n = noise.get_noise_2d(p.x, p.y)
		var offset = Vector2(0, n * noise_strength)
		edge.append(p + offset)

	line.points = edge

	var poly := []
	poly.append_array(edge)

	for i in range(edge.size() - 1, -1, -1):
		poly.append(edge[i] + Vector2(0, thickness))

	fill.polygon = poly
	collision.polygon = poly
