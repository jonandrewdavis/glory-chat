extends RigidBody2D

var source: String
var hit_location: Vector2
var frozen := false
var admin: PlayerAdmin
var hit_rotation: float

func _ready() -> void:
	gravity_scale = 0.5
	set_collision_layer_value(2, true)
	set_collision_mask_value(2, true)
	$Timer.timeout.connect(destroy)

func _process(_delta: float) -> void:
	if frozen:
		position = admin.position + hit_location
		rotation = hit_rotation
	else:
		rotation = linear_velocity.angle()
		hit_rotation = rotation
	
@rpc('call_local', "any_peer")
func freeze_arrow(hit_location_: Vector2):
	admin = get_tree().get_first_node_in_group('PlayerAdmin')
	hit_location = hit_location_
	frozen = true
	call_deferred('freeze_arrow_defer')

func freeze_arrow_defer():
	
	freeze = true
	%CollisionShape2D.disabled = true

func destroy():
	queue_free()
