#version 440

// INPUT    offsets		  [N]
// INPUT2   scan on local level	  [M]
// INPUT3   scan on block level	  [M]
// INPUT3+X container to sort     [N] ->| Double-
// OUTPUTX  container to put sort [N] ->| Buffer prob.
//
// add.:
// INPUT4_VAR needs position variable
// and object of
// INPUT4 == OUTPUT
// INPUT5 == OUTPUT2
// ...
// etc.

#include "shader/shared_hpp/voxel_tile_size.hpp"
#include "shader/compute/indexing/gridIndex.include.glsl"


layout(local_size_x =X)in;


uniform uvec3 gGridDim;
uniform PREC_VEC3_TYPE gGridPos;
uniform PREC_SCAL_TYPE gridSpacing;

uniform uint bufferSize;

void main(void){
	uint unsortedIndex = gl_GlobalInvocationID.x;
	if(unsortedIndex>=bufferSize){
		return;
	}

	PREC_VEC3_TYPE pos = INPUT4_AT(INPUT4,INPUT4_VAR,INPUT4_SIZE, unsortedIndex,INPUT4_NUM_BUFFER,INPUT4_INDEX_BUFFER,INPUT4_VAR_SIZE).xyz;

	// Bin due to position in grid
	PREC_VEC3_TYPE positionInGrid= (pos-gGridPos)/gridSpacing;

	//floor
	ivec3 globalGridIndex = ivec3(positionInGrid);


	if(inBounds(globalGridIndex,gGridDim)){
		uint voxelAndTileIndex = get_voxel_and_tile_index(globalGridIndex,gGridDim);
		uint scanIndex =
			//scan_local
			INPUT2_AT(INPUT2,INPUT2_VAR,INPUT2_SIZE,get_scan_local_index(voxelAndTileIndex),INPUT2_NUM_BUFFER,INPUT2_INDEX_BUFFER,INPUT2_VAR_SIZE) +
			//scan_block
			INPUT3_AT(INPUT3,INPUT3_VAR,INPUT3_SIZE,get_scan_block_index(voxelAndTileIndex),INPUT3_NUM_BUFFER,INPUT3_INDEX_BUFFER,INPUT3_VAR_SIZE);

		uint scanOffset =
			INPUT_AT(INPUT,INPUT_VAR,INPUT_SIZE,unsortedIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER,INPUT_VAR_SIZE);
		uint sortedIndex = scanIndex + scanOffset;
		for(int var=0; var<OUTPUT_VAR_SIZE;var++){
			OUTPUT_AT(OUTPUT,var,OUTPUT_SIZE,sortedIndex,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER,OUTPUT_VAR_SIZE) = INPUT4_AT(INPUT4,var,INPUT4_SIZE,unsortedIndex,INPUT4_NUM_BUFFER,INPUT4_INDEX_BUFFER,INPUT4_VAR_SIZE);
		}
#ifdef OUTPUT2
		for(int var=0; var<OUTPUT2_VAR_SIZE;var++){
			OUTPUT2_AT(OUTPUT2,var,OUTPUT2_SIZE,sortedIndex,OUTPUT2_NUM_BUFFER,OUTPUT2_INDEX_BUFFER,OUTPUT2_VAR_SIZE) = INPUT5_AT(INPUT5,var,INPUT5_SIZE,unsortedIndex,INPUT5_NUM_BUFFER,INPUT5_INDEX_BUFFER,INPUT5_VAR_SIZE);
		}
#endif

#ifdef OUTPUT3
		for(int var=0; var<OUTPUT3_VAR_SIZE;var++){
			OUTPUT3_AT(OUTPUT3,var,OUTPUT3_SIZE,sortedIndex,OUTPUT3_NUM_BUFFER,OUTPUT3_INDEX_BUFFER,OUTPUT3_VAR_SIZE) = INPUT6_AT(INPUT6,var,INPUT6_SIZE,unsortedIndex,INPUT6_NUM_BUFFER,INPUT6_INDEX_BUFFER,INPUT6_VAR_SIZE);
		}
#endif
	}
}
