extends Node3D

@onready var godot_plush_mesh = $GodotPlushModel/Rig/Skeleton3D/GodotPlushMesh
@onready var physical_bone_simulator_3d = %PhysicalBoneSimulator3D
@onready var animation_tree : AnimationTree = %AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")

@onready var center_body: PhysicalBone3D  = $"GodotPlushModel/Rig/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone DEF-hips"

@onready var cR: CharacterBody3D = get_parent().get_parent()

var ragdoll : bool = false : set = set_ragdoll
var squash_and_stretch = 1.0 : set = set_squash_and_stretch

signal footstep(intensity : float)
signal waved

func _ready():
	set_ragdoll(ragdoll)
	if is_multiplayer_authority():
		apply_new_weights()
		set_process(false)

	#else:
		##apply_no_weights()
		#set_process(true)

func apply_new_weights():
	for child in %PhysicalBoneSimulator3D.get_children():
		var bone: PhysicalBone3D = child
		bone.mass = 0.01

	center_body.mass = 0.1

#func _process(delta): 
	#for child in %PhysicalBoneSimulator3D.get_children():
		#var bone: PhysicalBone3D = child
		#if bone.name != 'Physical Bone DEF-hips':
			#bone.global_position = center_body.global_position
			#
func apply_no_weights():
	for child in %PhysicalBoneSimulator3D.get_children():
		var bone: PhysicalBone3D = child
		bone.get_node('CollisionShape3D').disabled = true

		#bone.gravity_scale = 0.01
		#bone.friction  = 0.0
		#bone.mass = 5.0
		##bone.angular_damp = 50.0
		##bone.angular_damp_mode = PhysicalBone3D.DAMP_MODE_REPLACE
		##bone.linear_damp = 50.0
		##bone.linear_damp_mode = PhysicalBone3D.DAMP_MODE_REPLACE

func set_ragdoll(value : bool) -> void:
	#manage the ragdoll appliements to the model, to call when wanting to go in/out ragdoll mode
	ragdoll = value
	if !is_inside_tree(): return
	physical_bone_simulator_3d.active = ragdoll
	animation_tree.active = !ragdoll
	
	# hide cR
	if cR.nametag: cR.nametag.visible = !value
	%NametagPlush.visible = value
	if ragdoll:
		physical_bone_simulator_3d.physical_bones_start_simulation()
	else: 
		physical_bone_simulator_3d.physical_bones_stop_simulation()

	if is_multiplayer_authority():
		sync_set_ragdoll.rpc(value)

@rpc('call_remote', 'authority')
func sync_set_ragdoll(value):
	#ragdoll = value
	if !is_inside_tree(): return
	physical_bone_simulator_3d.active = value
	animation_tree.active = !value

	# hide cR
	if cR.nametag: cR.nametag.visible = !value
	%NametagPlush.visible = value
	if value: 
		physical_bone_simulator_3d.physical_bones_start_simulation()
		cR.set_physics_process(true)
	else: 
		physical_bone_simulator_3d.physical_bones_stop_simulation()
		cR.set_physics_process(false)

# This is a cool trick.
# Calling an RPC to other machines but only effecting my puppet.
# I am authority, I'm the only one calling set_state()
# I remote out, with authority, calling on the node matching myself.
func set_state(state_name : String) -> void:
	#set current state of the model state machine (which manage the differents animations)
	state_machine.travel(state_name)
	if is_multiplayer_authority():
		sync_set_state.rpc(state_name)

@rpc('call_remote', 'authority')
func sync_set_state(state_name):
	state_machine.travel(state_name)
	
func set_squash_and_stretch(value : float) -> void:
	#squash and stretch the model
	squash_and_stretch = value
	var negative = 1.0 + (1.0 - squash_and_stretch)
	godot_plush_mesh.scale = Vector3(negative, squash_and_stretch, negative)

func emit_footstep(intensity : float = 1.0) -> void:
	#call foostep signal in charge of emitting the footstep audio effects
	footstep.emit(intensity)

func set_mesh_color(new_color: Color):
	var plush = $GodotPlushModel/Rig/Skeleton3D/GodotPlushMesh

	for i in 3:
		var mesh_material: ShaderMaterial = plush.get_active_material(i)
		var new_mat = mesh_material.duplicate()
		new_mat['shader_parameter/custom_color'] = new_color
		plush.set_surface_override_material(i, new_mat)
	
func wave():
	animation_tree["parameters/WaveOneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	if is_multiplayer_authority(): sync_wave.rpc()

@rpc('call_remote', 'authority')
func sync_wave():
	animation_tree["parameters/WaveOneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE


func set_name_tag(username_text: String):
	%NametagPlush.text = username_text
