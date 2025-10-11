extends Node3D

@onready var window: Window = get_window()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	window.transparent = false
