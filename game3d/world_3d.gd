extends Node3D

@onready var window: Window = get_window()
@onready var walls: Node3D = $Walls

func _ready() -> void:
	window.always_on_top = false
	window.transparent = false

	for child in walls.get_children():
		var wall: StaticBody3D = child
		wall.set_collision_layer_value(2, true)
