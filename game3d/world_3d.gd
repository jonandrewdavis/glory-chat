extends Node3D

@onready var window: Window = get_window()
@onready var walls: Node3D = $Walls

func _ready() -> void:
	if OS.is_debug_build():
		window.borderless = false
		window.always_on_top = false
	else:
		window.always_on_top = true
		window.set_mode(Window.MODE_MAXIMIZED)
		window.borderless = true
		
	for child in walls.get_children():
		var wall: StaticBody3D = child
		wall.set_collision_layer_value(2, true)
