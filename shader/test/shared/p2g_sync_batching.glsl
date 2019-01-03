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
	uint blockIndex = OUTPUT_BLOCK_INDEX_AT(OUTPUT_BLOCK_INDEX,OUTPUT_BLOCK_INDEX_VAR,OUTPUT_BLOCK_INDEX_SIZE,gl_WorkGroupID.x,OUTPUT_BLOCK_INDEX_NUM_BUFFER,OUTPUT_BLOCK_INDEX_INDEX_BUFFER);

	uvec3 blockID = getBlockID(blockIndex, grid_def.gGridDim);

	uvec3 t_ijk = getIJK(gl_LocalInvocationID.x,blockSize);
	uvec3 ijk = blockID * blockSize + t_ijk;

	uint grid_key = SORTING_KEY(ijk,grid_def.gGridDim);
	uint count = INPUT_COUNT_AT(INPUT_COUNT,INPUT_COUNT_VAR,INPUT_COUNT_SIZE,grid_key,INPUT_COUNT_NUM_BUFFER,INPUT_COUNT_INDEX_BUFFER);

	uint scan = INPUT_SCAN_AT(INPUT_SCAN,INPUT_SCAN_VAR,INPUT_SCAN_SIZE,grid_key,INPUT_SCAN_NUM_BUFFER,INPUT_SCAN_INDEX_BUFFER);

	uint tile_count =OUTPUT_BLOCK_COUNT_AT(OUTPUT_BLOCK_COUNT,OUTPUT_BLOCK_COUNT_VAR,OUTPUT_BLOCK_COUNT_SIZE,blockIndex,OUTPUT_BLOCK_COUNT_NUM_BUFFER,OUTPUT_BLOCK_COUNT_INDEX_BUFFER);

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
	PREC_VEC3_TYPE[MULTIPLE_PARTICLES] positionInGrid ;
	PREC_VEC_TYPE[MULTIPLE_PARTICLES] vp_mp ;

	for(int process_count = 0; process_count < tile_count; process_count+=MULTIPLE_PARTICLES){
		uint batch_count = clamp(int(count)-process_count,0,MULTIPLE_PARTICLES);

#if MULTIPLE_PARTICLES==2
		//unroll
		uint globalParticleIndex = scan+process_count;
		if(0 < batch_count){
			PREC_VEC3_TYPE pos = INPUT_AT(INPUT,Particle_pos_vol,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER).xyz;

			vp_mp[0]= INPUT_AT(INPUT,Particle_vel_mass,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);

			positionInGrid[0]= (pos-grid_def.gGridPos)/grid_def.gridSpacing;
		}

		if(1 < batch_count){

			globalParticleIndex +=1;
			PREC_VEC3_TYPE pos = INPUT_AT(INPUT,Particle_pos_vol,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER).xyz;

			vp_mp[1]= INPUT_AT(INPUT,Particle_vel_mass,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);

			positionInGrid[1]= (pos-grid_def.gGridPos)/grid_def.gridSpacing;
		}
#else
		for(int particle_i = process_count; particle_i< process_count + batch_count;particle_i++){
			uint globalParticleIndex = scan+particle_i;
			PREC_VEC3_TYPE pos = INPUT_AT(INPUT,Particle_pos_vol,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER).xyz;


			vp_mp[particle_i-process_count] =
				INPUT_AT(INPUT,Particle_vel_mass,INPUT_SIZE,globalParticleIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);

			positionInGrid[particle_i-process_count]= (pos-grid_def.gGridPos)/grid_def.gridSpacing;
		}
#endif
		for(int x = -LEFT_SUPPORT; x<= RIGHT_SUPPORT ;x++){
			for(int y = -LEFT_SUPPORT; y<= RIGHT_SUPPORT ;y++){
				for(int z = -LEFT_SUPPORT; z <= RIGHT_SUPPORT ;z++){

					ivec3 gridOffset = ivec3(x,y,z);
					uvec3 global_grid_index = uvec3(ivec3(ijk)+gridOffset);

					uint local_i = get_dim_index(t_ijk + uvec3(gridOffset+LEFT_SUPPORT),uvec3(HALO_X,HALO_Y,HALO_Z));
					for(int particle_i = process_count; particle_i< process_count + batch_count;particle_i++){
						uint global_grid_key = get_dim_index(global_grid_index,grid_def.gGridDim);
						PREC_VEC3_TYPE gridDistanceToParticle =vec3(global_grid_index) -  positionInGrid[particle_i-process_count] ;
						PREC_SCAL_TYPE wip = .0f;
						weighting (gridDistanceToParticle,wip);

						PREC_VEC_TYPE vi_mi = PREC_VEC_TYPE(vp_mp[particle_i-process_count].xyz,1.0)*vp_mp[particle_i-process_count].w*wip;

						temp[local_i] +=vi_mi;

					}

					memoryBarrierShared();
					barrier();
				}
			}
		}

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