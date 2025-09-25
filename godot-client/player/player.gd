extends CharacterBody2D


const SPEED_MAX = 100.0
const JUMP_VELOCITY = -400.0

var SPEED_CURRENT = SPEED_MAX

# TODO: Expenential speed up, at the start,
# TODO: Gets slower (pulling harder) at the end.

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var arrow = preload('res://player/arrow.tscn')

@onready var timer_perfect_low = %TimerPerfectLow
@onready var timer_perfect_high = %TimerPerfectHigh
@onready var strength_bar: ProgressBar = %StrengthBar

func _ready():
	timer_perfect_low.wait_time = 2.1
	timer_perfect_high.wait_time = 2.8

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if  Input.is_action_pressed('fire'):
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


func _process(delta: float) -> void:
	var mouse_direction = (get_global_mouse_position() - global_position).normalized()
	if mouse_direction.x > 0 and animated_sprite.flip_h:
		animated_sprite.flip_h = false
		strength_bar.fill_mode = strength_bar.FILL_END_TO_BEGIN
	elif mouse_direction.x < 0 and not animated_sprite.flip_h:
		animated_sprite.flip_h = true
		strength_bar.fill_mode = strength_bar.FILL_BEGIN_TO_END

	if velocity.x > 0:
		animated_sprite.play('walk')
	else:
		animated_sprite.play('idle')

	if Input.is_action_pressed('fire'):
		if timer_perfect_high.is_stopped() and strength == 0.0:
			timer_perfect_low.start()
			timer_perfect_high.start()
		strength += strength_factor
		strength_bar.value = strength

	$Bar.look_at(get_viewport().get_mouse_position())	

	if Input.is_action_just_released('fire'):
		spawn_arrow()
		
func spawn_arrow():
	var target : Vector2 = get_viewport().get_mouse_position()
	var new_arrow: RigidBody2D = arrow.instantiate()
	var direction = position.direction_to(target).normalized()
	new_arrow.position = position + Vector2(1.0, 0.0)
	new_arrow.look_at(target)
	print(timer_perfect_low.time_left,  ' ' , timer_perfect_high.time_left)
	if timer_perfect_low.time_left == 0.0 and timer_perfect_high.time_left != 0.0:
		strength = strength * strength_perfect_multipler
		new_arrow.linear_velocity = Vector2(direction * clampf(strength, 0, strength_max * strength_perfect_multipler))
		print('PERF')
	else:
		strength = strength * strength_perfect_multipler
		new_arrow.linear_velocity = Vector2(direction * clampf(strength, 0, strength_max))

	get_parent().add_child(new_arrow)
	spawn_arrow_reset()

func spawn_arrow_reset():
	timer_perfect_low.stop()
	timer_perfect_high.stop()
	strength = 0.0
	strength_bar.value = strength
