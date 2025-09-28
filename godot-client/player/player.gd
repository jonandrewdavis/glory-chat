extends CharacterBody2D

class_name PlayerSimple

const SPEED_MAX = 100.0
const JUMP_VELOCITY = -400.0

var SPEED_CURRENT = SPEED_MAX

# TODO: Expenential speed up, at the start,
# TODO: Gets slower (pulling harder) at the end.

# TODO: Use just Perfect High timer & have it count for remaining wait time between -2.0 and 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var arrow = preload('res://player/arrow.tscn')

@onready var timer_perfect_low = %TimerPerfectLow
@onready var timer_perfect_high = %TimerPerfectHigh
@onready var arrow_progress_bar: ProgressBar = %ArrowProgressBar

var is_picked_up := false
var immobile := false

var input_jump := false
var input_primary := false
var input_dir := 0.0


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready():
	add_to_group('Players')
	set_process(is_multiplayer_authority())
	set_physics_process(is_multiplayer_authority())
	
	timer_perfect_low.wait_time = 2.1
	timer_perfect_high.wait_time = 2.8
	
	LobbySystem.signal_lobby_own_info.connect(set_lobby_info)
	LobbySystem.lobby_get_own()
	
	z_index = 1
	if not is_multiplayer_authority():
		hide_client_elements()

	%ArrowArea.body_entered.connect(proj_hit)

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

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Input to allow easy disable if menu is open
	if not immobile:
		input_jump = Input.is_action_just_pressed("jump") and is_on_floor()
		input_primary = Input.is_action_pressed('fire')
		input_dir = Input.get_axis("left", "right")	
	else:
		input_jump = false	
		input_primary = false
		input_dir = 0.0
	
	# Handle jump.
	if input_jump:
		if not input_primary:
			velocity.y = JUMP_VELOCITY
		else: 
			velocity.y = JUMP_VELOCITY * 0.55

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("left", "right")
	var direction = input_dir

	if input_primary and is_on_floor():
		SPEED_CURRENT = SPEED_MAX * 0.5
	else:
		SPEED_CURRENT = SPEED_MAX
	
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

	if velocity.x > 0:
		animated_sprite.play('walk')
	else:
		animated_sprite.play('idle')

	if Input.is_action_pressed('fire') and can_shoot():
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
	
	if Input.is_action_just_released('fire') and can_shoot():
		fire_arrow()

func can_shoot():
	return not immobile and %TimerCooldown.is_stopped()

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
	spawn_proj.rpc(position, target, proj_speed, name)
	spawn_arrow_reset()

@rpc('call_local')
func spawn_proj(pos_start: Vector2, pos_target: Vector2, proj_speed: float, source: String):
	# new_arrow.linear_velocity
	# new_arrow.look_at(target)
	# new_arrow.position
	var new_proj: RigidBody2D = arrow.instantiate()
	var direction = pos_start.direction_to(pos_target).normalized()
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

func proj_hit(body):
	# only perform a hit on the player
	# only perform if not owned by the player
	if is_multiplayer_authority() and body.source != name:
		var get_hit_location = body.position - position
		body.freeze_arrow.rpc(get_hit_location, name)
		#world.broadcast_player_kill.rpc(body.source)
