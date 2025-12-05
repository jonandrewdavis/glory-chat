extends Node3D

# TODO: properly transmit this, for now we'll disable dust particles
func display_particles(particle_ref : PackedScene, char_ref : CharacterBody3D):
	if is_multiplayer_authority():
		#display and emit particles
		var particles : GPUParticles3D = particle_ref.instantiate()
		char_ref.add_sibling(particles)
		particles.global_transform = char_ref.global_transform
		particles.emitting = true
