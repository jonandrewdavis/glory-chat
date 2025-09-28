extends AnimatableBody2D

class_name PlayerAdmin

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

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

func _physics_process(_delta: float) -> void:
	var target : Vector2 = get_viewport().get_mouse_position()
	global_position = target

var game_visible := true

func _process(_delta):
	if immobile: 
		return 
		
	if Input.is_action_just_pressed("fire") and not current_player_picked_up:
		current_player_picked_up = _get_closest_player()
		if current_player_picked_up: current_player_picked_up.get_picked_up.rpc()
		
	if Input.is_action_just_released('fire'):
		if current_player_picked_up: 
			current_player_picked_up.get_dropped.rpc()
			current_player_picked_up = null

	if Input.is_action_just_pressed("toggle_game") and window.mouse_passthrough:
		window.mouse_passthrough = false
	elif Input.is_action_just_pressed("toggle_game") and not window.mouse_passthrough: 
		window.mouse_passthrough = true

	if Input.is_action_just_pressed("debug1") and world.platforms.visible:
		world.platforms.hide()
		world.hide_all_players()
		show()
		%PointerHitbox.hide()
	elif Input.is_action_just_pressed("debug1") and not world.platforms.visible:
		world.platforms.show()
		world.show_all_players()
		show()
		%PointerHitbox.show()

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
		world.broadcast_player_kill.rpc(body.source)
