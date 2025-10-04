extends StaticBody2D

class_name Target

@onready var hurt_area = $Area2D
var destroy_time := 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hurt_area.set_collision_layer_value(2, true)
	hurt_area.set_collision_mask_value(2, true)
	
	hurt_area.body_entered.connect(_on_body_entered)
	$Timer.timeout.connect(func(): queue_free())
	$Timer.one_shot = true
	$Timer.wait_time = destroy_time
	$Timer.start()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group('Projectiles'):
		var world: World = get_tree().get_first_node_in_group('World')
		world.broadcast_player_kill(body.source)		
		queue_free()
		body.queue_free()
