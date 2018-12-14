#version 440
#extension GL_NV_shader_atomic_float: enable

uniform vec3 gGridPos;
uniform uvec3 gGridDim;
uniform float gridSpacing;

uniform uint indexSize;

#include "shader/compute/interpolation/cubic.include.glsl"
#include "shader/compute/indexing/neighborIndex.include.glsl"
#include "shader/compute/indexing/gridIndex.include.glsl"
layout(local_size_x =X, local_size_y =Y,local_size_z =Z)in;

shared uint scan[(X+2*SUPPORT)*(Y+2*SUPPORT)*(Z+2*SUPPORT)];
shared uint count[(X+2*SUPPORT)*(Y+2*SUPPORT)*(Z+2*SUPPORT)];

void main(void){
  uint i = gl_GlobalInvocationID.x;

  get_grid
    PREC_VEC3_TYPE pos = INPUT_AT(INPUT,Particle_pos_vol,INPUT_SIZE,i,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER).xyz;


  PREC_VEC_TYPE vp_mp =
    INPUT_AT(INPUT,Particle_vel_mass,INPUT_SIZE,i,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER);

  // Bin due to position in grid
  PREC_VEC3_TYPE positionInGrid= (pos-gGridPos)/gridSpacing;


  for(int x = -SUPPORT+1; x<= SUPPORT ;x++){
    for(int y = -SUPPORT+1; y<= SUPPORT ;y++){
      for(int z = -SUPPORT+1; z <= SUPPORT ;z++){
	ivec3 gridOffset = ivec3(x,y,z);

	//floor
	ivec3 globalGridIndex = ivec3(positionInGrid) + gridOffset;
	if(inBounds(globalGridIndex,gGridDim)){

	  uint voxelAndTileIndex = get_voxel_and_tile_index(globalGridIndex,gGridDim);
	  vec3 gridDistanceToParticle = vec3(globalGridIndex)- positionInGrid;
	  float wip = .0f;
	  weighting (gridDistanceToParticle,wip);

	  float mp = vp_mp.w;
	  vec3 vp = vp_mp.xyz;

	  float mi = mp *wip;
	  vec3 vi = vp*mp*wip;
	  atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,voxelAndTileIndex,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).w,
	      mi);
	  atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,voxelAndTileIndex,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).x,
	      vi.x);

	  atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,voxelAndTileIndex,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).y,
	      vi.y);

	  atomicAdd(OUTPUT_AT(OUTPUT,Gridpoint_vel_mass,OUTPUT_SIZE,voxelAndTileIndex,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER).z,
	      vi.z);
	}
      }
    }

  }
}