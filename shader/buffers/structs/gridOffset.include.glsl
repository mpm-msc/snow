#ifndef PARTICLE_INDEX_GLSL
#define PARTICLE_INDEX_GLSL

#ifdef AOS_LAYOUT
struct ParticleIndices {
	GLuint GridOffset_i;
};
#else
#define ParticleIndices GLuint
#define GridOffset_i		0
#define ParticleIndices_VAR_SIZE  1
#endif

#endif /* end of include guard: PARTICLE_INDEX_GLSL */
