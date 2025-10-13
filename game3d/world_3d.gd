extends Node3D

@onready var window: Window = get_window()
@onready var walls: Node3D = $Walls

func _ready() -> void:
	window.always_on_top = false
	window.transparent = false

	#for wall in walls.get_children():
		#wall.set_collision_layer(2, true)
		
