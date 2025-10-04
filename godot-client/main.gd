extends Node

var game_world = preload("res://world/world.tscn")

func _ready():
	# Game start signal - only admins will connect on game start.
	if OS.has_feature('admin'):
		LobbySystem.signal_lobby_game_started.connect(new_game_connection)
	else:
		LobbySystem.signal_network_create_new_peer_connection.connect(new_game_connection)

func new_game_connection(_id):
	# TODO: Improve. This is fragile.
	if get_node_or_null("World") == null:
		get_window().mouse_passthrough = false
		if get_node_or_null("LobbyMenu"): get_node("LobbyMenu").hide()
		if get_node_or_null("LobbyQuickConnect"): get_node("LobbyQuickConnect").hide()
		var new_world = game_world.instantiate()
		add_child(new_world)
