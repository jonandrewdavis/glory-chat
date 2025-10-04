extends CharacterBody2D

class_name PlayerSimple

const SPEED_MAX = 100.0
const JUMP_VELOCITY = -400.0

var SPEED_CURRENT = SPEED_MAX

@onready var window: Window = get_window()
@onready var world: World = get_tree().get_first_node_in_group('World')

# TODO: Expenential speed up, at the start,
# TODO: Gets slower (pulling harder) at the end.

# TODO: Use just Perfect High timer & have it count for remaining wait time between -2.0 and 0.0

@onready var health_system: HealthSystem = %HealthSystem
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nameplate: Label = %LabelUsername
@onready var player_ui: PlayerUI = $PlayerUI
@onready var health_progress_bar = %HealthBar

var arrow = preload('res://player/arrow.tscn')

@onready var timer_perfect_low: Timer = %TimerPerfectLow
@onready var timer_perfect_high: Timer = %TimerPerfectHigh
@onready var arrow_progress_bar: ProgressBar = %ArrowProgressBar

var temp_bar_flashing_timer = Timer.new()

var player_color := Color.WHITE
var is_picked_up := false
var immobile := false

var input_jump := false
var input_primary := false
var input_secondary := false
var input_dir := 0.0
var input_sprint := false

var can_jump := false

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready():
	add_to_group('Players')
	set_process(is_multiplayer_authority())
	set_physics_process(is_multiplayer_authority())
	
	timer_perfect_low.wait_time = 2.1
	timer_perfect_high.wait_time = 2.9
	
	timer_perfect_low.timeout.connect(flash_strength)
	timer_perfect_high.timeout.connect(func(): flash_strength(false))
	
	add_child(temp_bar_flashing_timer)
	temp_bar_flashing_timer.wait_time = 0.2
	temp_bar_flashing_timer.one_shot = false
	temp_bar_flashing_timer.timeout.connect(on_temp_flash_timeout)
	
	LobbySystem.signal_lobby_own_info.connect(set_lobby_info)
	LobbySystem.lobby_get_own()
	
	%HealthSystem.death.connect(show_player_death)
	%HealthSystem.respawn.connect(show_player_respawn)
	
	%ArrowArea.body_entered.connect(proj_hit)
	%TimerCheckServer.timeout.connect(_check_server)
	%TimerJump.timeout.connect(func(): can_jump = false)
	
	%ShieldArea.set_collision_mask_value(2, true)
	%ShieldArea.body_entered.connect(proj_reflect)
	%ShieldContainer.hide()
	%ShieldCollision.disabled = true

	z_index = 1
	if not is_multiplayer_authority():
		hide_client_elements()
	else:
		health_system.health_updated.connect(on_health_updated)
		health_system.max_health_updated.connect(on_max_health_updated)
		window.focus_entered.connect(_on_window_focus_enter)
		window.focus_exited.connect(_on_window_focus_exit)

func _physics_process(delta: float) -> void:
	if is_picked_up:
		var admin_pos = get_tree().get_first_node_in_group('PlayerAdmin').position
		var admin_dist = position.distance_to(admin_pos)
		# (b - a) b: there, a: here
		#position = lerp(position, (admin_pos - position).normalized(), 0.1)
		if admin_dist > 8.0:
			velocity = position.direction_to(admin_pos).normalized() * (10 * admin_dist)
			move_and_slide()
		else:
			position = admin_pos
		return
	
	if can_jump == false and is_on_floor():
		can_jump = true

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		if can_jump and %TimerJump.is_stopped():
			%TimerJump.start()
		
	# Input to allow easy disable if menu is open
	if not immobile:
		input_jump = Input.is_action_just_pressed("jump") 
		input_primary = Input.is_action_pressed('primary')
		input_secondary = Input.is_action_pressed('secondary')
		input_dir = Input.get_axis("left", "right")	
		input_sprint = Input.is_action_pressed('sprint')
	else:
		input_jump = false	
		input_primary = false
		input_secondary = false
		input_dir = 0.0
		input_sprint = false

	# Handle jump.
	if input_jump and can_jump:
		jump_action()

	if Input.is_action_pressed('primary') and can_shoot():
		if timer_perfect_high.is_stopped() and strength == 0.0:
			timer_perfect_low.start()
			timer_perfect_high.start()
		strength += strength_factor
		arrow_progress_bar.value = strength
		%ArrowProgressBar.show()
		%ArrowContainer.show()
		%ArrowContainer.look_at(get_viewport().get_mouse_position())
	else:
		%ArrowProgressBar.hide()
		%ArrowContainer.hide()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("left", "right")
	var direction = input_dir

	if input_primary and is_on_floor():
		SPEED_CURRENT = SPEED_MAX * 0.5
	elif is_blocking:
		SPEED_CURRENT = SPEED_MAX * 0.5
	else:
		var modifier = 1.0
		if input_sprint: modifier = 1.5
		SPEED_CURRENT = SPEED_MAX  * modifier
	
	if direction:
		velocity.x = direction * SPEED_CURRENT
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED_CURRENT)

	move_and_slide()

var strength = 0.0
var strength_factor = 3.0
var strength_max = 500.0

var strength_perfect_multipler = 1.5

func _process(_delta: float) -> void:
	var mouse_direction = (get_global_mouse_position() - global_position).normalized()
	if mouse_direction.x > 0 and animated_sprite.flip_h:
		animated_sprite.flip_h = false
		arrow_progress_bar.fill_mode = arrow_progress_bar.FILL_END_TO_BEGIN
	elif mouse_direction.x < 0 and not animated_sprite.flip_h:
		animated_sprite.flip_h = true
		arrow_progress_bar.fill_mode = arrow_progress_bar.FILL_BEGIN_TO_END
	
	if %TimerPreventDamage.is_stopped():
		if velocity.x != 0.0:
			animated_sprite.play('walk')
		else:
			animated_sprite.play('idle')	


	if Input.is_action_just_released('primary') and can_shoot():
		fire_arrow()
	elif Input.is_action_just_pressed('secondary') and can_shoot() and can_block():
		block()
	
	
	if is_blocking:
		%ShieldContainer.look_at(get_viewport().get_mouse_position())

func can_block():
	return not is_blocking and not immobile and %TimerCooldownBlock.is_stopped()

func can_shoot():
	return not is_blocking and not immobile and %TimerCooldown.is_stopped()

func fire_arrow():
	var target : Vector2 = get_viewport().get_mouse_position()
	var proj_speed: float
	if timer_perfect_low.time_left == 0.0 and timer_perfect_high.time_left != 0.0:
		strength = strength * strength_perfect_multipler
		proj_speed = clampf(strength, 0, strength_max * strength_perfect_multipler)
	else:
		strength = strength * strength_perfect_multipler
		proj_speed = clampf(strength, 0, strength_max)

	# TODO: PackedByteArray to make this RPC super small
	spawn_proj.rpc(position, target, proj_speed, name, player_color)
	spawn_arrow_reset()

@rpc('call_local')
func spawn_proj(pos_start: Vector2, pos_target: Vector2, proj_speed: float, source: String, _player_color: Color):
	if immobile: 
		return
	# new_arrow.linear_velocity 
	# new_arrow.look_at(target)
	# new_arrow.position
	var new_proj: RigidBody2D = arrow.instantiate()
	var direction = pos_start.direction_to(pos_target).normalized()
	new_proj.color = _player_color
	new_proj.position = pos_start + Vector2(1.0, 0.0)
	new_proj.look_at(pos_target)
	new_proj.linear_velocity = Vector2(direction * proj_speed)
	new_proj.source = source
	get_parent().add_child(new_proj, true)

func spawn_arrow_reset():
	timer_perfect_low.stop()
	timer_perfect_high.stop()
	strength = 0.0
	arrow_progress_bar.value = strength
	%TimerCooldown.start()
	flash_strength(false)

@rpc("any_peer", "reliable")
func get_picked_up():
	is_picked_up = true
	immobile = true

@rpc("any_peer", "reliable")
func get_dropped():
	is_picked_up = false
	immobile = false

func hide_client_elements():
	z_index = 0	
	%ArrowProgressBar.hide()
	%ArrowContainer.hide()

func set_lobby_info(lobby):
	%LabelUsername.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	%LabelUsername.set_anchors_preset(Control.PRESET_CENTER_TOP)
	for _player in lobby.players:
		# player id matches the node name (peer id)
		if _player.id == name:
			%LabelUsername.text = _player.username
			# players set their own data only, the synchronizer broadcasts it on spawn 
			if _player.metadata:
				player_color = _player.metadata.color
				%AnimatedSprite2D.modulate = Color(player_color)
				%ArrowContainer.get_node('ArrowPolygon2D').color = Color(player_color)
				%ShieldContainer.get_node('ShieldPolygon2D').color = Color(player_color)

# 3 arrows from the same player, they die

# increment the hit as a timestamp?? how long ago 
# a timer going to DECREMENT the 
# - 1

var recent_hits = {
	'player_id_123': 0,
}

# Check for garbage in your vicinity (collision check)
# if : x === 3: die.
var prevent_damage := false

func proj_hit(body):
	# only perform a hit on the player
	# only perform if not owned by the player	
	if is_multiplayer_authority() and body.source != name:
		# Always freeze arrow
		# Conditionally hurt the player
		#var get_hit_location = body.position - position
		#body.freeze_arrow.rpc(get_hit_location, name)

		# A: If prevent damage timer is stopped
		# B: If window has focus
		# TODO: Why didn't window focus here work?
		if %TimerPreventDamage.is_stopped() and %LabelAFK.visible == false:
			var get_hit_location = body.position - position
			body.freeze_arrow.rpc(get_hit_location, name)

			flash_sprite()
			animated_sprite.play('hurt')
			%HealthSystem._damage_sync(25, body.source)
			prevent_damage = true
			%TimerPreventDamage.start()

func proj_reflect(body):
	if is_multiplayer_authority() and body.source != name:
		body.reflect_arrow.rpc(name)
		
func flash_sprite():
		animated_sprite.modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate.a = 1.0

var flash = true

func flash_strength(is_flashing: bool = true):
	if is_flashing:
		flash = true
		temp_bar_flashing_timer.start()
		%ArrowProgressBar.get_theme_stylebox("fill").bg_color = Color.GREEN
		%ArrowProgressBar.modulate.a = 1.0
	else:
		flash = false
		temp_bar_flashing_timer.stop()
		%ArrowProgressBar.modulate.a = 1.0	
		%ArrowProgressBar.get_theme_stylebox("fill").bg_color = Color.from_string('ff4bff66', Color.HOT_PINK)

func on_temp_flash_timeout():
	#tween module
	var tween = create_tween()
	if (flash):
		%ArrowProgressBar.get_theme_stylebox("fill").bg_color = Color.GREEN
		tween.tween_property(%ArrowProgressBar, "modulate:a", 1.0, 0.2).from(0.0)
	else:
		%ArrowProgressBar.get_theme_stylebox("fill").bg_color = Color.from_string('ff4bff66', Color.HOT_PINK)
		tween.tween_property(%ArrowProgressBar, "modulate:a", 0.0, 0.2).from(1.0)

func _check_server():
	if not get_tree().get_first_node_in_group('PlayerAdmin'):
		%LabelDisconnected.show()
		await get_tree().create_timer(5.0).timeout
		LobbySystem.lobby_leave()
		await get_tree().create_timer(2.0).timeout
		get_tree().quit()
		
func jump_action():
	can_jump = false
	if not input_primary:
		velocity.y = JUMP_VELOCITY
	elif is_blocking:
		velocity.y = JUMP_VELOCITY * 0.55
	else: 
		velocity.y = JUMP_VELOCITY * 0.55

func show_player_death():
	# TODO: play actual death.
	set_process(false)
	immobile = true
	animated_sprite.play('death')
	world.broadcast_player_kill(health_system.last_damage_source)
	world.broadcast_player_death(name)
	await get_tree().create_timer(2.0).timeout
	modulate.a = 0.0
	await get_tree().create_timer(3.5).timeout
	health_system.respawn.emit()
	
func show_player_respawn():
	set_process(true)
	immobile = false
	animated_sprite.play('idle')
	modulate.a = 1.0
	position = Vector2(randi_range(0, 1000), randi_range(0, 0))
	
# TODO: Captured and then have a custom mouse cursor?
func _on_window_focus_enter():
	modulate.a = 1.0
	%LabelAFK.hide()
	
func _on_window_focus_exit():
	modulate.a = 0.3
	%LabelAFK.show()

var is_blocking:= false 

func block():
	is_blocking = true
	%ShieldContainer.show()
	%ShieldCollision.disabled = !is_blocking
	await get_tree().create_timer(0.7).timeout 
	%ShieldContainer.hide()
	is_blocking = false
	%ShieldCollision.disabled = !is_blocking
	# Start cooldowns
	%TimerCooldownBlock.start()
	%TimerCooldown.start()
	
func on_health_updated(next_health):
	var current = health_progress_bar.get_current_value()
	if next_health < current:
		health_progress_bar.decrease_bar_value(current - next_health)
		%HealthBar.show()
	else:
		var diff = next_health - current
		health_progress_bar.increase_bar_value(diff)
		if next_health == health_system.max_health:
			await get_tree().create_timer(1.2).timeout
			%HealthBar.hide()

func on_max_health_updated(new_max):
	health_progress_bar.set_max_value(new_max)
	health_progress_bar.set_bar_value(new_max)
