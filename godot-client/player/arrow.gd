extends RigidBody2D

func _ready() -> void:
	gravity_scale = 0.5

func _process(delta: float) -> void:
	rotation = linear_velocity.angle()
