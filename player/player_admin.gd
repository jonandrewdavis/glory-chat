extends AnimatableBody2D

class_name PlayerAdmin

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var target_scene = preload('res://game/target.tscn')

@onready var window = get_window()
@onready var world: World = get_tree().get_first_node_in_group('World')

var current_player_picked_up: PlayerSimple
var is_game_focused := false

var immobile := false

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready():
	add_to_group('PlayerAdmin')

	%PointerHitbox.body_entered.connect(proj_hit)
	%PointerHitbox.set_collision_layer_value(2, true)
	%PointerHitbox.set_collision_mask_value(2, true)
	
	set_process(is_multiplayer_authority())
	set_physics_process(is_multiplayer_authority())
	window.always_on_top = true
	window.borderless = true
	
	if is_multiplayer_authority():
		%TimerSpawnTarget.wait_time = 5.0
		%TimerSpawnTarget.timeout.connect(_create_new_target)
		%TimerSpawnTarget.start()

func _physics_process(_delta: float) -> void:
	var target : Vector2 = get_viewport().get_mouse_position()
	global_position = target

var game_visible := true

func _process(_delta):
	if immobile: 
		return 

	if Input.is_action_just_pressed('primary') and not current_player_picked_up:
		current_player_picked_up = _get_closest_player()
		if current_player_picked_up: current_player_picked_up.get_picked_up.rpc()
	elif Input.is_action_just_released('primary'):
		if current_player_picked_up: 
			current_player_picked_up.get_dropped.rpc()
			current_player_picked_up = null
	elif Input.is_action_just_pressed('secondary'):
		print(_get_closest_platform())
		pass
	elif Input.is_action_just_pressed("toggle_game") and window.mouse_passthrough:
		world.show_all()
		world.show_all_modulate(true)
		window.mouse_passthrough = false
	elif Input.is_action_just_pressed("toggle_game") and not window.mouse_passthrough: 
		window.mouse_passthrough = true
	elif Input.is_action_just_pressed("debug1") and world.tile_maps.visible:
		world.hide_all()
	elif Input.is_action_just_pressed("debug1") and not world.tile_maps.visible:
		world.show_all()
	elif Input.is_action_just_pressed("debug2"):
		world.show_all()
		world.show_all_modulate()
	elif Input.is_action_just_pressed("debug3"):
		var col: CollisionPolygon2D = %PointerHitbox.get_node("CollisionPolygon2D")
		col.disabled = !col.disabled
		%PointerHitbox.visible = !%PointerHitbox.visible
		
func _get_closest_player() -> PlayerSimple:
	var players = get_tree().get_nodes_in_group('Players')
	var dist = INF
	var closest_player: PlayerSimple
	for single in players:
		var get_dist = position.distance_to(single.position)
		if get_dist < dist:
			dist = get_dist
			closest_player = single

	return closest_player

func proj_hit(body):
	# only perform a hit if the admin gets hit
	if is_multiplayer_authority():
		var get_hit_location = body.position - position
		body.freeze_arrow.rpc(get_hit_location, 'admin')
		# DO NOT GIVE POINTS out any more
		#world.broadcast_player_kill.rpc(body.source)
		
func _get_closest_platform():
	var dist = INF
	var platform_closest: Node2D 
	for platform in world.platforms.get_children():
		var get_dist = position.distance_to(platform.position)
		if get_dist < dist:
			dist = get_dist
			platform_closest = platform

	return platform_closest

func _create_new_target():
	var random_pos = _random_pos_in_circle(world.target_marker.position, 300.0)
	var random_wait = randf_range(4.0, 9.0)
	var random_cooldown = randf_range(7.0, 11.0)
	%TimerSpawnTarget.wait_time = random_wait + random_cooldown
	%TimerSpawnTarget.start()
	_spawn_new_target.rpc(random_pos, random_wait)
	
@rpc('call_local')
func _spawn_new_target(random_pos: Vector2, destroy_time: float):
	var new_target: Target = target_scene.instantiate()
	new_target.position = random_pos
	new_target.destroy_time = destroy_time
	world.player_container.add_child(new_target, true)

func _random_pos_in_circle(center_position: Vector2, radius: float) -> Vector2:
	var angle = randf() * TAU 
	var random_radius = sqrt(randf()) * radius

	var x = center_position.x + random_radius * cos(angle)
	var y = center_position.y + random_radius * sin(angle)

	return Vector2(x, y)
