extends Node

var game_world = preload("res://world/world.tscn")

func _ready():
	# Game start signal
	if not OS.has_feature('admin'):
		LobbySystem.signal_network_create_new_peer_connection.connect(new_game_connection)
	else:
		LobbySystem.signal_lobby_game_started.connect(new_game_connection)

func new_game_connection(_id):
	# TODO: Improve. This is fragile.
	if get_node_or_null("World") == null:
		if get_node_or_null("LobbyMenu"): get_node("LobbyMenu").hide()
		if get_node_or_null("LobbyQuickConnect"): get_node("LobbyQuickConnect").hide()
		var new_world = game_world.instantiate()
		add_child(new_world)
