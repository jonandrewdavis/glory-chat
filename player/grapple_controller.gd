extends Node2D

@export var ray_length := Vector2(250, 0)
@export var rest_length := 25.0
@export var stiffness := 11.0
@export var damping := 0.2

@onready var player := get_parent()
@onready var ray := $RayCast2D
@onready var rope := $Line2D
@onready var sprite_target = $Sprite2D
@onready var grapple_grace_timer = $GrappleGraceTimer

var launched = false
var target: Vector2

func _ready():
	ray.target_position = ray_length
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		sprite_target.hide()
	else:
		sprite_target.show()

func _process(delta):
	
	sprite_target.top_level = true
	
	ray.look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("grapple"):
		launch()
	if Input.is_action_just_released("grapple"):
		retract()
	
	if launched:
		handle_grapple(delta)
	
	handle_sprite_target()

var last_sprite_pos: Vector2
var tween_weight = 0.1

func handle_sprite_target():		
	if launched:
		sprite_target.position = lerp(sprite_target.position, target, 0.3) 
		return

	if ray.is_colliding():
		var pos = ray.get_collision_point()
		# skip lerp far away
		if sprite_target.position.distance_to(pos) > 200.0:
			sprite_target.position = pos
		else:
			sprite_target.position = lerp(sprite_target.position, pos, 0.05) 
		sprite_target.modulate.a = lerp(sprite_target.modulate.a, 1.0, tween_weight) 
		last_sprite_pos = pos
		grapple_grace_timer.start()
	else:
		if get_parent().position.distance_to(sprite_target.position) > 50.0:
			sprite_target.position = lerp(sprite_target.position, last_sprite_pos, 0.3) 
			sprite_target.modulate.a = 0.0
		else:
			sprite_target.position = lerp(sprite_target.position, last_sprite_pos, 0.1) 
			sprite_target.modulate.a = lerp(sprite_target.modulate.a, 0.0, tween_weight) 
		
	if get_parent().strength > 0.0:
		sprite_target.modulate.a = 0.0

	
func launch():
	if get_parent().strength > 0.0:
		return
	
	if ray.is_colliding():
		launched = true
		target = ray.get_collision_point()
		rope.show()
	elif not grapple_grace_timer.is_stopped():
		launched = true
		target = last_sprite_pos
		rope.show()
		
func retract():
	launched = false
	rope.hide()

func handle_grapple(delta):
	var target_dir = player.global_position.direction_to(target)
	var target_dist = player.global_position.distance_to(target)
	
	var displacement = target_dist - rest_length
	
	var force = Vector2.ZERO
	
	if displacement > 0:
		var spring_force_magnitude = stiffness * displacement
		var spring_force = target_dir * spring_force_magnitude
		
		var vel_dot = player.velocity.dot(target_dir)
		var damping_ 

		if player.strength > 0.0: 
			# If you're charging an arrow you are slower.
			damping_ = -5.0 * vel_dot * target_dir			
		else:
			damping_ = -damping * vel_dot * target_dir			
		
		force = spring_force + damping_
	
	player.velocity += force * delta
	update_rope()

func update_rope():
	rope.set_point_position(1, to_local(target))
