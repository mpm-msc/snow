#ifndef PARTICLE_INDEX_BUFFER
#define PARTICLE_INDEX_BUFFER
#include "shader/shared_hpp/buffer_bindings.hpp"
#include "shader/buffers/structs/gridOffset.include.glsl"

layout(std430, binding = PARTICLE_INDICES_BINDING) buffer Particle_GridOffset{
	ParticleIndices particle_indices[];
};
#endif
