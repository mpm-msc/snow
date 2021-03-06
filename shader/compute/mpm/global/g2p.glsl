#version 440
#extension GL_NV_shader_atomic_float: enable

uniform uint indexSize;

#include "shader/compute/interpolation/cubic.include.glsl"
#include "shader/compute/indexing/neighborIndex.include.glsl"
#include "shader/compute/indexing/gridIndex.include.glsl"
layout(local_size_x =X, local_size_y =Y,local_size_z =Z)in;

void main(void){

	uint i = gl_GlobalInvocationID.x;
	if(i>=indexSize){
		return;
	}

	PREC_VEC3_TYPE pos = OUTPUT_AT(OUTPUT,Particle_pos_vol,OUTPUT_SIZE,i,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).xyz;


	// Bin due to position in grid
	PREC_VEC3_TYPE positionInGrid= (pos-grid_def.gGridPos)/grid_def.gridSpacing;


	PREC_VEC3_TYPE vp_n = PREC_VEC3_TYPE(0.0f);

#ifdef APIC
	PREC_MAT3_TYPE Bp_n = PREC_MAT3_TYPE(0.0);
#endif
	for(int x = -LEFT_SUPPORT; x<= RIGHT_SUPPORT ;x++){
		for(int y = -LEFT_SUPPORT; y<= RIGHT_SUPPORT ;y++){
			for(int z = -LEFT_SUPPORT; z <= RIGHT_SUPPORT ;z++){
				ivec3 gridOffset = ivec3(x,y,z);

				//floor
				ivec3 globalGridIndex = ivec3(positionInGrid) + gridOffset;
				if(inBounds(globalGridIndex,grid_def.gGridDim)){

					uint key = SORTING_KEY(globalGridIndex,grid_def.gGridDim);
					vec3 gridDistanceToParticle = vec3(globalGridIndex)- positionInGrid;
					float wip = .0f;
					weighting (gridDistanceToParticle,wip);

					vec4 vi_mi_n = INPUT_AT(INPUT,Gridpoint_vel_mass,INPUT_SIZE,key,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);
					vp_n += vi_mi_n.xyz*wip;

#ifdef APIC
					//need to be reworked
					PREC_VEC3_TYPE delta_x_n = (gridDistanceToParticle+gridDistanceToParticle)*grid_def.gridSpacing;
					PREC_VEC3_TYPE delta_x_p = (gridDistanceToParticle-gridDistanceToParticle)*grid_def.gridSpacing;

					Bp_n += 0.5 * wip * (outerProduct(vi_mi_n.xyz,delta_x_n) + outerProduct(delta_x_p,vi_mi_n.xyz));
#endif
				}
			}
		}
	}
	OUTPUT_AT(OUTPUT,Particle_vel_mass,OUTPUT_SIZE,i,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).xyz = vp_n;

#ifdef APIC
	OUTPUT_AT(OUTPUT,Particle_Bp_1,OUTPUT_SIZE,i,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).xyz = Bp_n[0];
	OUTPUT_AT(OUTPUT,Particle_Bp_2,OUTPUT_SIZE,i,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).xyz = Bp_n[1];
	OUTPUT_AT(OUTPUT,Particle_Bp_3,OUTPUT_SIZE,i,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).xyz = Bp_n[2];
#endif
}
