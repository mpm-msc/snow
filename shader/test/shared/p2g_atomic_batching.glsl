#version 440
#extension GL_NV_shader_atomic_float: enable

uniform uint indexSize;

#include "shader/compute/interpolation/cubic.include.glsl"
layout(local_size_x =X, local_size_y =Y,local_size_z =Z)in;

#define HALO_X (VOXEL_DIM_X+LEFT_SUPPORT+RIGHT_SUPPORT)
#define HALO_Y (VOXEL_DIM_Y+LEFT_SUPPORT+RIGHT_SUPPORT)
#define HALO_Z (VOXEL_DIM_Z+LEFT_SUPPORT+RIGHT_SUPPORT)
#define THREAD_RANGE int((HALO_X*HALO_Y*HALO_Z)/(X*Y*Z))
shared PREC_VEC_TYPE temp [HALO_X*HALO_Y*HALO_Z];

#define blockSize uvec3(VOXEL_DIM_X,VOXEL_DIM_Y,VOXEL_DIM_Z)
void main(void){
#ifdef OUTPUT_BLOCK_INDEX
	uvec3 blockID = getBlockID(OUTPUT_BLOCK_INDEX_AT(OUTPUT_BLOCK_INDEX,OUTPUT_BLOCK_INDEX_VAR,OUTPUT_BLOCK_INDEX_SIZE,gl_WorkGroupID.x,OUTPUT_BLOCK_INDEX_NUM_BUFFER,OUTPUT_BLOCK_INDEX_INDEX_BUFFER), grid_def.gGridDim);
#else
	uvec3 blockID = getBlockID(gl_WorkGroupID.x,grid_def.gGridDim);
#endif
	uvec3 t_ijk = getIJK(gl_LocalInvocationID.x,blockSize);
	uvec3 ijk = blockID * blockSize + t_ijk;

	uint grid_key = SORTING_KEY(ijk,grid_def.gGridDim);
	uint count = INPUT_COUNT_AT(INPUT_COUNT,INPUT_COUNT_VAR,INPUT_COUNT_SIZE,grid_key,INPUT_COUNT_NUM_BUFFER,INPUT_COUNT_INDEX_BUFFER);

	uint scan = INPUT_SCAN_AT(INPUT_SCAN,INPUT_SCAN_VAR,INPUT_SCAN_SIZE,grid_key,INPUT_SCAN_NUM_BUFFER,INPUT_SCAN_INDEX_BUFFER);

	int local_i = int(gl_LocalInvocationID.x);

	for(int frac = 0; frac < THREAD_RANGE;frac++){
		temp[local_i] = PREC_VEC_TYPE(0.0);
		local_i += X*Y*Z;
	}


	if(local_i < (HALO_X*HALO_Y*HALO_Z)) {
		temp[local_i] = PREC_VEC_TYPE(0.0);
	}
	memoryBarrierShared();
	barrier();

	PREC_VEC3_TYPE[MULTIPLE_PARTICLES] pos ;
	PREC_VEC_TYPE[MULTIPLE_PARTICLES] vp_mp ;
	uint process_count = 0;
	while(process_count != count){
		uint batch_count = min(count-process_count,MULTIPLE_PARTICLES);
		/*
#if MULTIPLE_PARTICLES==2
		//unroll
		uint globalParticleIndex = scan+process_count;
		if(0 < batch_count){
		pos[0] = INPUT_AT(INPUT,Particle_pos_vol,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER).xyz;

		vp_mp[0]= INPUT_AT(INPUT,Particle_vel_mass,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);
		}

		if(1 < batch_count){

		globalParticleIndex +=1;
		pos[1] = INPUT_AT(INPUT,Particle_pos_vol,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER).xyz;

		vp_mp[1]= INPUT_AT(INPUT,Particle_vel_mass,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);
		}
#elif MULTIPLE_PARTICLES==4
		 */
#if MULTIPLE_PARTICLES==4
		//unroll
		uint globalParticleIndex = scan+process_count;
		if(0 < batch_count){

			pos[0] = INPUT_AT(INPUT,Particle_pos_vol,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER).xyz;

			vp_mp[0]= INPUT_AT(INPUT,Particle_vel_mass,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);
		}

		if(1 < batch_count){

			globalParticleIndex +=1;
			pos[1] = INPUT_AT(INPUT,Particle_pos_vol,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER).xyz;

			vp_mp[1]= INPUT_AT(INPUT,Particle_vel_mass,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);
		}

		if(2 < batch_count){

			globalParticleIndex +=1;
			pos[2] = INPUT_AT(INPUT,Particle_pos_vol,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER).xyz;

			vp_mp[2]= INPUT_AT(INPUT,Particle_vel_mass,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);
		}


		if(3 < batch_count){

			globalParticleIndex +=1;
			pos[3] = INPUT_AT(INPUT,Particle_pos_vol,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER).xyz;

			vp_mp[3]= INPUT_AT(INPUT,Particle_vel_mass,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);
		}
#else
		for(uint particle_i = process_count; particle_i < process_count+batch_count; particle_i++){
			uint globalParticleIndex = scan+particle_i;
			pos[particle_i-process_count] = INPUT_AT(INPUT,Particle_pos_vol,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER).xyz;


			vp_mp[particle_i-process_count]=
				INPUT_AT(INPUT,Particle_vel_mass,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);
		}
#endif

		for(int x = -LEFT_SUPPORT; x<= RIGHT_SUPPORT ;x++){
			for(int y = -LEFT_SUPPORT; y<= RIGHT_SUPPORT ;y++){
				for(int z = -LEFT_SUPPORT; z <= RIGHT_SUPPORT ;z++){
					ivec3 gridOffset = ivec3(x,y,z);
					uvec3 global_grid_index = uvec3(ivec3(ijk)+gridOffset);
					PREC_VEC3_TYPE vi =vec3(0.0);
					PREC_SCAL_TYPE mi = 0.0;
					for(int particle_i = 0; particle_i < batch_count; particle_i++){
						PREC_VEC3_TYPE positionInGrid= (pos[particle_i]-grid_def.gGridPos)/grid_def.gridSpacing;

						PREC_VEC3_TYPE gridDistanceToParticle =vec3(global_grid_index) -  positionInGrid ;
						PREC_SCAL_TYPE wip = .0f;
						weighting (gridDistanceToParticle,wip);

						PREC_SCAL_TYPE mp = vp_mp[particle_i].w;
						PREC_VEC3_TYPE vp = vp_mp[particle_i].xyz;

						mi += mp*wip;
						vi += vp*mp*wip;
					}
					uint local_i = get_dim_index(t_ijk + uvec3(gridOffset+LEFT_SUPPORT),uvec3(HALO_X,HALO_Y,HALO_Z));
					atomicAdd(temp[local_i].x,vi.x);
					atomicAdd(temp[local_i].y,vi.y);
					atomicAdd(temp[local_i].z,vi.z);
					atomicAdd(temp[local_i].w,mi);

				}
			}
		}
		process_count +=batch_count;
	}
	memoryBarrierShared();
	barrier();

	local_i = int(gl_LocalInvocationID.x);
	ivec3 grid_start_node = ivec3(blockID * blockSize) - LEFT_SUPPORT;

	for(int frac = 0; frac < THREAD_RANGE;frac++){
		uvec3 halo_ijk = uvec3(getIJK(local_i,ivec3(HALO_X,HALO_Y,HALO_Z)));
		ivec3 to_process = grid_start_node + ivec3(halo_ijk);
		if(inBounds(to_process,grid_def.gGridDim)){
			uint write_key = SORTING_KEY(to_process,grid_def.gGridDim);
			PREC_VEC_TYPE to_write = temp[local_i];

			atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,write_key,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).x,
					to_write.x);

			atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,write_key,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).y,
					to_write.y);

			atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,write_key,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).z,
					to_write.z);

			atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,write_key,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).w,
					to_write.w);
		}
		local_i += X*Y*Z;
	}

	if(local_i < (HALO_X*HALO_Y*HALO_Z)) {
		uvec3 halo_ijk = uvec3(getIJK(local_i,ivec3(HALO_X,HALO_Y,HALO_Z)));
		ivec3 to_process = grid_start_node + ivec3(halo_ijk);
		if(inBounds(to_process,grid_def.gGridDim)){
			uint write_key = SORTING_KEY(to_process,grid_def.gGridDim);
			PREC_VEC_TYPE to_write = temp[local_i];

			atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,write_key,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).x,
					to_write.x);

			atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,write_key,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).y,
					to_write.y);

			atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,write_key,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).z,
					to_write.z);

			atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,write_key,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).w,
					to_write.w);
		}

	}

}