extends Node2D

class_name World

var player_scene_new = preload("res://player/player.tscn")
var player_admin_new = preload('res://player/player_admin.tscn')

@export var player_container_admin: Node2D
@export var player_container: Node2D

@onready var tile_maps: Node2D = $TileMaps
@onready var target_marker = $TargetMarker

signal signal_player_death(id)
signal signal_player_kill(id)

func _ready() -> void:
	add_to_group('World')
	get_window().borderless = true
	if OS.is_debug_build():
		pass
	else:
		get_window().set_mode(Window.MODE_MAXIMIZED)
		get_window().borderless = true

	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	
	# Local player
	if OS.has_feature('admin'):
		add_player_to_game(multiplayer.get_unique_id(), true)
	else:
		add_player_to_game(multiplayer.get_unique_id())

func RTCServerConnected():
	print("WORLD: rtc server connected")
	
func RTCPeerConnected(id: int):
	print("WORLD: rtc peer connected " + str(id))
	add_player_to_game(id)
	
func RTCPeerDisconnected(id):
	print("WORLD: rtc peer disconnected " + str(id))
	remove_player_from_game(id)

func add_player_to_game(id: int, is_admin: bool = false):
	var has_id = id in player_container.get_children().map(func(node): int(node.name))
	if has_id == true:
		return

	var player_to_add
	if is_admin or id == LobbySystem.host_peer_id: 
		player_to_add = player_admin_new.instantiate()
		player_to_add.name = str(id)
		player_to_add.position = Vector2(randi_range(30, 880), randi_range(0, 0))
		player_container_admin.add_child(player_to_add, true)
	else:
		player_to_add = player_scene_new.instantiate()
		player_to_add.name = str(id)
		player_to_add.position = Vector2(randi_range(30, 880), randi_range(0, 0))
		player_container.add_child(player_to_add, true)

@rpc("any_peer", 'call_local', 'reliable')
func broadcast_player_death(id: String):
	signal_player_death.emit(id)
	
@rpc("any_peer", 'call_local', 'reliable')
func broadcast_player_kill(id: String):
	signal_player_kill.emit(id)

func remove_player_from_game(id):
	var player_to_remove = player_container.get_node_or_null(str(id))
	if player_to_remove != null:
		player_to_remove.queue_free()
	else:
		player_container_admin.get_node(str(id)).queue_free()

func hide_all():
	tile_maps.hide()
	player_container.hide()

func show_all():
	tile_maps.show()
	player_container.show()
	
var mod_value = 1.0
func show_all_modulate(should_show: bool = false):
	if mod_value == 1.0:
		mod_value = 0.1
	else:
		mod_value = 1.0

	# helps override in the case admin we wants to toss someone / interact.
	if should_show: 
		mod_value = 1.0

	tile_maps.modulate.a = mod_value
	player_container.modulate.a = mod_value
