extends Node

var game_world_arrow = preload("res://game/world.tscn")
var game_world_island = preload("res://game3d/world3d.tscn")	

func _ready():
	# Game start signal - only admins will connect on game start.
	if OS.has_feature('admin'):
		LobbySystem.signal_lobby_game_started.connect(new_game_connection)
	else:
		LobbySystem.signal_network_create_new_peer_connection.connect(new_game_connection)

var current_world: String = ""

# TODO: When a new player joins, get the host world.

func new_game_connection(_id):
	if not OS.has_feature('admin'):
		for player in LobbySystem.lobby_local_data.players:
			if player.id == str(LobbySystem.host_peer_id):
				current_world = player.metadata.current_game
	else:
		current_world = get_node_or_null("LobbyQuickConnect").current_game		
	
	if current_world == "0":
		mount_world_arrow()
	elif current_world == "1":
		mount_world_island()
	
func mount_world_arrow():
	if get_node_or_null("World") == null:
		add_child(game_world_arrow.instantiate())
		clean_up_menus() 
		
func mount_world_island():
	if get_node_or_null("World3d") == null:
		add_child(game_world_island.instantiate())
		clean_up_menus() 

func clean_up_menus():
	if get_node_or_null("LobbyMenu"): get_node("LobbyMenu").queue_free()
	if get_node_or_null("LobbyQuickConnect"): get_node("LobbyQuickConnect").queue_free()
	if LobbySystem.signal_network_create_new_peer_connection.is_connected(new_game_connection):
		LobbySystem.signal_network_create_new_peer_connection.disconnect(new_game_connection)
	if LobbySystem.signal_lobby_game_started.is_connected(new_game_connection):
		LobbySystem.signal_lobby_game_started.disconnect(new_game_connection)


@rpc("call_local", 'any_peer')
func broadcast_change_world(opt: int):
	LobbySystem.user_update_info({ "current_game": str(opt)})

	await get_tree().create_timer(0.5).timeout

	for worlds in get_tree().current_scene.get_children():
		worlds.queue_free()

	await get_tree().create_timer(1.5).timeout
	
	if opt == 0:
		mount_world_arrow()
	elif opt == 1:
		mount_world_island()
