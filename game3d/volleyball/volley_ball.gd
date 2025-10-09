extends RigidBody3D

@onready var torus_indicator = %TorusIndicator
@onready var shape_cast_down = %ShapeCastDown
@onready var shape_cast_floor = %ShapeCastFloor
@onready var ray_cast_down: RayCast3D = %RayCastDown

var is_serving := false	

func _ready() -> void:

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true) # Paddle collision
	
	shape_cast_down.set_collision_mask_value(1, false)
	shape_cast_down.set_collision_mask_value(5, true)
	shape_cast_down.top_level = true

	shape_cast_floor.set_collision_mask_value(1, false)
	shape_cast_floor.set_collision_mask_value(5, true)
	shape_cast_floor.top_level = true

	torus_indicator.top_level = true
	
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)

func _process(_delta: float) -> void:
	move_ray_casts()
	check_collision()

func move_ray_casts():
	ray_cast_down.position = position
	shape_cast_floor.position = position
	

func check_collision():
	if ray_cast_down.is_colliding():
		torus_indicator.position = ray_cast_down.get_collision_point()
		#print(ray_cast_down.is_colliding())
		#print(ray_cast_down.get_collision_point())
		
	if shape_cast_floor.is_colliding() and is_serving == false:
		var collision_obj = shape_cast_floor.get_collider(0)
		print('[Debug]: Ball on floor: ', collision_obj)
		serve_ball()

func serve_ball():
	is_serving = true
	freeze = true
	var rand_pos = get_random_point_in_square(Vector2(0, 0), Vector2(10.0, 10.0))
	var serve_height = 10.0	
	# Note: x, y, z, but we use the 2D square, excercise caution.
	position = Vector3(rand_pos.x, serve_height, rand_pos.y)
	await get_tree().create_timer(0.1).timeout
	is_serving = false
	freeze = false

func get_random_point_in_square(position: Vector2, size: Vector2) -> Vector2:
	# Generate a random X coordinate within the square's horizontal bounds
	var random_x = randf_range(position.x, position.x + size.x)
	# Generate a random Y coordinate within the square's vertical bounds
	var random_y = randf_range(position.y, position.y + size.y)

	return Vector2(random_x, random_y)
	
