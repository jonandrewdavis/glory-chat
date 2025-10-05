extends Control

var user_panel_stylebox = preload("res://lobby/theme/lobby_player_container_styleboxflat.tres")

var username_value: String
var code_value: String
var current_lobby_code: String

var LOBBY_CUSTOM_ID = 'glory-chat'
var host_peer_id: int

func _ready() -> void:
	# Always hide code
	if not OS.has_feature('admin'):
		_hide_admin_features()
	elif OS.has_feature('admin'): 
		_hide_joiner_features()

	%ColumnQuickConnect.custom_minimum_size.x = 425.0
	%ColumnLobby.hide()

	%InputUsername.text_changed.connect(func(text): username_value = text; \
		%ButtonQuickHost.disabled = true if text.length() == 0 else false)

	%InputUsername.text_changed.connect(func(text): username_value = text; \
		%ButtonQuickJoin.disabled = true if text.length() == 0 else false)
	
	#%InputCode.text_changed.connect(func(text): code_value = text; \
		#%ButtonQuickJoin.disabled = true if text.length() == 0 else false)
	
	%InputCode.max_length = 8
	
	%ButtonQuickJoin.disabled = true
	%ButtonQuickJoin.custom_minimum_size.x = 100
	%ButtonQuickHost.disabled = true;
	%ButtonQuickHost.custom_minimum_size.x = 100

	%ButtonQuickJoin.pressed.connect(_quick_join)
	%ButtonQuickHost.pressed.connect(_quick_host)
	%ButtonLobbyLeave.pressed.connect(func(): LobbySystem.user_disconnect())
	%ButtonLobbyStart.pressed.connect(func(): LobbySystem.lobby_start_game())

	%ButtonCopy.pressed.connect(func(): DisplayServer.clipboard_set(current_lobby_code))
	%ButtonPaste.pressed.connect(func(): %InputCode.text = DisplayServer.clipboard_get(); %InputCode.text_changed.emit(str(%InputCode.text)))
	
	if OS.has_feature('admin'):
		LobbySystem.signal_lobby_changed.connect(_render_current_lobby_view)
	
	LobbySystem.signal_client_disconnected.connect(func(): _render_connection_light(false))
	LobbySystem.signal_packet_parsed.connect(func(_packet): _render_connection_light(true))
	# DEBUG:
	#LobbySystem.signal_packet_parsed.connect(func(packet): print('DEBUG: ', packet))
	# Admin / Host detection
	LobbySystem.signal_lobby_joined.connect(func(lobby): if lobby == null: show_error_message())


func show_error_message():
	%LabelError.show()	
	LobbySystem.user_disconnect()
	await get_tree().create_timer(1.0).timeout
	%ConnectionLight.modulate = Color.CRIMSON
	

func _hide_admin_features():
	%InputCode.hide()
	%ButtonQuickHost.hide()	

func _hide_joiner_features():
	%InputCode.hide()
	%ButtonQuickJoin.hide()	

func _quick_join():
	LobbySystem.user_connect(username_value)
	await get_tree().create_timer(1.0).timeout 
	
	if OS.is_debug_build():
		LOBBY_CUSTOM_ID = 'glory-chat'
	# NOTE: hardcoded 
	LobbySystem.lobby_join(LOBBY_CUSTOM_ID.rstrip(" "))

# TODO: Copy-able button
func _quick_host():
	# TODO: create a "connect-and-create" method? 
	LobbySystem.user_connect(username_value)
	# TODO: actual async/await
	await get_tree().create_timer(1.0).timeout 
	#LobbySystem.lobby_create()
	if OS.is_debug_build():
		LOBBY_CUSTOM_ID = 'glory-chat'

	LobbySystem.lobby_create({
		'isPublic': false,
		'customId': LOBBY_CUSTOM_ID
	})


func _create_user_item(username: String, color: String) -> PanelContainer:
	var user_hbox = HBoxContainer.new()
	var user_panel = PanelContainer.new()
	user_panel.add_theme_stylebox_override("panel", user_panel_stylebox)

	var rect = ColorRect.new()
	rect.custom_minimum_size = Vector2(25.0, 25.0)
	rect.color = Color.from_string(color, Color.WHITE)

	var user_label = Label.new()
	user_label.size_flags_horizontal = Control.SIZE_EXPAND
	user_label.text = username

	user_hbox.add_child(user_label)
	user_hbox.add_child(rect)
	user_panel.add_child(user_hbox)
	return user_panel

func _render_current_lobby_view(lobby):
	%ColumnLobby.visible = false
	%LobbyUserList.get_children().map(func(element):  element.queue_free())

	if lobby:
		var lobby_id_to_code = lobby.id
		%InputLobbyCopy.text = lobby_id_to_code
		DisplayServer.clipboard_set(lobby_id_to_code)
		current_lobby_code = lobby_id_to_code
		%LabelLobbyTitle.text = lobby.players[0].username + "'s Lobby"
		%ColumnLobby.visible = true
		lobby.players.map(func(player): %LobbyUserList.add_child(_create_user_item(player.username, player.metadata.color)))
		
func _render_connection_light(is_user_connected: bool = false):
	%ConnectionLight.modulate = Color.WHITE
	if is_user_connected:	
		%LabelError.hide()	
		await get_tree().create_timer(0.08).timeout
		%ConnectionLight.modulate = Color.GREEN
