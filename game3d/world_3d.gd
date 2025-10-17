extends Node3D

@onready var window: Window = get_window()
@onready var walls: Node3D = $Walls
@onready var player_container = $PlayerContainer3D

var player_scene_new = preload("res://addons/PlayerCharacter/PlayerCharacterScene.tscn")

func _ready() -> void:
	window.always_on_top = false
	window.transparent = true
	window.mode = Window.MODE_MAXIMIZED

	for child in walls.get_children():
		var wall: StaticBody3D = child
		wall.set_collision_layer_value(2, true)

	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	
	# Local player needs no validation, Island world skips on 
	if not OS.has_feature('admin'):
		add_player_to_game(multiplayer.get_unique_id())
	else:
		add_player_to_game(multiplayer.get_unique_id())
	
	if multiplayer.get_peers().size() > 0:
		for peer in multiplayer.get_peers():
			add_player_to_game(peer)
	
func RTCServerConnected():
	print("WORLD: rtc server connected")
	
func RTCPeerConnected(id: int):
	print("WORLD: rtc peer connected " + str(id))
	add_player_to_game(id)
	
func RTCPeerDisconnected(id):
	print("WORLD: rtc peer disconnected " + str(id))
	remove_player_from_game(id)

@rpc('any_peer', 'call_remote')
func signal_disconnect():
	RTCPeerDisconnected(multiplayer.get_remote_sender_id())

@rpc('call_local', 'any_peer')
func remove_player_on_change(id):
	remove_player_from_game(id)	

func validate_add_player_to_game(id):
	# Skip if client & player to be added is admin
	#if LobbySystem.host_peer_id == id:
		#return

	if LobbySystem.lobby_local_data == null:
		return
		
	for _player in LobbySystem.lobby_local_data.players:
		var _pending_player_id: String = str(id)
		if _player.id == _pending_player_id:
			if _player.metadata.has("current_game") and _player.metadata.current_game == "1": 
				add_player_to_game(id)

func add_player_to_game(id: int):
	#if get_tree().get_node("Main").current_game == 0:
	var has_id = id in player_container.get_children().map(func(node): int(node.name))
	if has_id == true:
		return

	var player_to_add
	player_to_add = player_scene_new.instantiate()
	player_to_add.name = str(id)
	player_to_add.position = Vector3(randf_range(-10.0, 10.0), 1.5, randf_range(-10.0, 10.0))
	player_container.add_child(player_to_add, true)

func remove_player_from_game(id):
	var player_to_remove = player_container.get_node_or_null(str(id))
	if player_to_remove != null:
		player_to_remove.queue_free()
