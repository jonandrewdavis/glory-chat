@tool
extends Node3D

var key_scene = preload('res://game3d/keeb/key.tscn')

var col = 5
var row = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var track_row = 0
	var track_col = 0

	for j in row:
		track_row += 1
		track_col = 0
		for i in col:
			track_col += 1
			var new_key = key_scene.instantiate()
			new_key.position = Vector3(track_row * 2, 0.0, track_col * 2)
			add_child(new_key)
