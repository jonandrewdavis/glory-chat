extends State

class_name RagdollState

var state_name : String = "Ragdoll"
var cR : CharacterBody3D

var ragdoll_jump_active := false
var ragdoll_jump_cooldown = Timer.new()

func _ready():
	ragdoll_jump_cooldown.wait_time = 1.0
	ragdoll_jump_cooldown.one_shot = true
	#ragdoll_jump_cooldown.timeout.connect(func(): ragdoll_jump_active = false)
	add_child(ragdoll_jump_cooldown)
	ragdoll_jump_cooldown.start()

func enter(char_ref : CharacterBody3D):
	cR = char_ref
	
	apply_ragdoll()
	verifications()
	
func verifications():
	cR.floor_snap_length = 1.0
	if cR.jump_cooldown > 0.0: cR.jump_cooldown = -1.0
	if cR.nb_jumps_in_air_allowed < cR.nb_jumps_in_air_allowed_ref: cR.nb_jumps_in_air_allowed = cR.nb_jumps_in_air_allowed_ref
	if cR.coyote_jump_cooldown < cR.coyote_jump_cooldown_ref: cR.coyote_jump_cooldown = cR.coyote_jump_cooldown_ref
	if cR.movement_dust.emitting: cR.movement_dust.emitting = false
	
func apply_ragdoll():
	#set model to ragdoll mode
	cR.set_process(false)
	cR.set_physics_process(false)
	
	cR.godot_plush_skin.ragdoll = true
	
func update(_delta : float):
	check_if_ragdoll()

func physics_update(delta : float):
	#gravity_apply(delta)
	#applies()
	input_management()
	move(delta)

func check_if_ragdoll():
	if !cR.godot_plush_skin.ragdoll:
		transitioned.emit(self, "IdleState")
		
func gravity_apply(delta : float):
	cR.velocity.y -= cR.ragdoll_gravity * delta #apply distant gravity value to follow the model (if wanted)
	
func applies():
	#have to apply the cut movement apply every frame, otherwise the camera will continue to move
	cR.velocity.x = 0.0
	cR.velocity.z = 0.0
	
func input_management():
	if cR.immobile: return

	if Input.is_action_just_pressed("ragdoll"):
		#if ragdoll is set to be only enable on floor
		if cR.ragdoll_on_floor_only and cR.is_on_floor():
			cR.godot_plush_skin.ragdoll = false
		#otherwise
		elif !cR.ragdoll_on_floor_only:
			cR.godot_plush_skin.ragdoll = false

		cR.velocity.x = 0.0
		cR.velocity.z = 0.0
		cR.set_process(true)
		cR.set_physics_process(true)
		cR.position = cR.godot_plush_skin.center_body.global_position + Vector3(0.0, 0.6, 0.0)
	
	if Input.is_action_just_pressed(cR.jumpAction): 
		if ragdoll_jump_active == false and ragdoll_jump_cooldown.is_stopped():
			# only allow jump below a certain altitude.
			if cR.godot_plush_skin.center_body.global_position.y < 2.0:
				ragdoll_jump_active = true

var RAGDOLL_JUMP_FORCE := 50.0

# NOTE: cR.is_on_floor is always true in ragdoll since ragdoll can't be activated in air & the cR 
# remains on the ground. # TODO: Fix.
func move(delta : float):
	cR.move_dir = Input.get_vector(cR.moveLeftAction, cR.moveRightAction, cR.moveForwardAction, cR.moveBackwardAction).rotated(-cR.cam_holder.global_rotation.y)
	var center: PhysicalBone3D = cR.godot_plush_skin.center_body
		#apply smooth move
	var force_x = cR.move_dir.x * cR.move_speed * 0.4
	var force_z = cR.move_dir.y * cR.move_speed * 0.4
	var force_y = 0.0
	#cR.plush
	if ragdoll_jump_active: 
		force_y = RAGDOLL_JUMP_FORCE
		ragdoll_jump_active = false
		ragdoll_jump_cooldown.start()

	center.apply_central_impulse(Vector3(force_x, force_y, force_z ) * delta)

#func move(delta : float):
	#
	#cR.move_dir = Input.get_vector(cR.moveLeftAction, cR.moveRightAction, cR.moveForwardAction, cR.moveBackwardAction).rotated(-cR.cam_holder.global_rotation.y)
	#
	#if cR.move_dir and cR.is_on_floor():
		##apply smooth move
		#cR.velocity.x = lerp(cR.velocity.x, cR.move_dir.x * cR.move_speed, cR.move_accel * delta)
		#cR.velocity.z = lerp(cR.velocity.z, cR.move_dir.y * cR.move_speed, cR.move_accel * delta)
