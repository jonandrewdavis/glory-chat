extends CanvasLayer

class_name PlayerUI

@export var player: Node2D

var world: World 

func _ready() -> void:
	if not is_multiplayer_authority():
		queue_free()
		return

	%Menu.hide()
	%LabelFPSCounter.hide()
		
	LobbySystem.signal_lobby_chat.connect(_render_lobby_chat_visible)
	LobbySystem.signal_lobby_event.connect(_render_new_event)
	%LobbyChatFadeTimer.timeout.connect(_render_lobby_chat_fade)
	# Scoreboard
	LobbySystem.signal_lobby_changed.connect(_render_own_lobby_info)
	LobbySystem.signal_lobby_own_info.connect(_render_own_lobby_info)
	multiplayer.peer_disconnected.connect(_render_remove_player_info)	

	world = get_tree().get_first_node_in_group("World")
	if world:
		world.signal_player_death.connect(add_death_to_player)
		world.signal_player_kill.connect(add_kill_to_player)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed('menu') and %Menu.visible:
		%LobbyChat.lobby_chat_should_focus(false)
		%Menu.hide()
		player.immobile = false
	elif Input.is_action_just_pressed('menu') and not %Menu.visible:
		player.immobile = true
		%Menu.show()
		%LobbyChat.lobby_chat_should_focus(true)

	%LabelFPSCounter.text = 'FPS: ' + str(Engine.get_frames_per_second())

#func _on_hurt():
	#%HurtSound.play()
	#%HurtTexture.visible = true
	#%HurtTimer.start()
#
#func _on_hurt_timer_timeout():
	#%HurtTexture.visible = false

func _on_disconnect():
	if multiplayer != null && multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer = null
	
func _on_hit_signal(headshot = false):
	%HitMarker.show()
	%HitTimer.start()
	await get_tree().create_timer(0.1).timeout
	if headshot: 
		%HitHeadSound.play()
	else:
		%HitSound.play()


func _render_lobby_chat_visible(chat_user: String, chat_text: String):
	%LobbyChatVisible.modulate.a = 1.0
	%LobbyChatVisible.append_text(chat_user + " : " + chat_text)
	%LobbyChatVisible.newline()
	%LobbyChatFadeTimer.start()

func _render_new_event(event_text: String):
	%LobbyChatVisible.modulate.a = 1.0
	%LobbyChatVisible.append_text('[color=808080]' + event_text)
	%LobbyChatVisible.newline()
	%LobbyChatFadeTimer.start()


func _render_lobby_chat_fade():
	var tween = get_tree().create_tween()
	tween.tween_property(%LobbyChatVisible, "modulate:a", 0.0, 0.8)
	tween.play()
	await tween.finished
	tween.kill()

# TODO: Would be nice to have some type saftey on this
func _render_own_lobby_info(lobby):
	# TODO: We clear the scoreboard if new players join.
	# We could make a list of not present Ids and just add those instead.
	for _player in lobby.players:
		if not %LobbyScoreboard.get_node_or_null(_player.id):
			var new_player_item = Instantiate.scene(PlayerInfoItem)
			new_player_item.name = _player.id 
			new_player_item.render_player_info(_player.username,  _player.metadata.color if _player.metadata.has('color') else 'WHITE')
			%LobbyScoreboard.add_child(new_player_item, true)

func _render_remove_player_info(id: int):
	var player_info_item_to_remove =  %LobbyScoreboard.get_node_or_null(str(id))
	if player_info_item_to_remove: player_info_item_to_remove.queue_free()

# TODO: improve score keeping. make more generic
func add_death_to_player(playerId: String):
	var info_target: PlayerInfoItem = %LobbyScoreboard.get_node_or_null(playerId)
	if not null:
		info_target.add_death()

func add_kill_to_player(playerId: String):
	var info_target: PlayerInfoItem = %LobbyScoreboard.get_node_or_null(playerId)
	if not null:
		info_target.add_kill()
