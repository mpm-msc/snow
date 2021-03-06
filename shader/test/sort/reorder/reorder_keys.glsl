#version 440

// INPUT    offsets		  [N]
// INPUT2   scan on local level	  [M]
// INPUT3   scan on block level	  [M]
// INPUT4   container to sort     [N]
// OUTPUT   key sorted            [N]
//
// add.:
// INPUT4_VAR needs position variable

#include "shader/shared_hpp/voxel_block_size.hpp"

#include "shader/utils/sorting_method.include.glsl"
#include "shader/buffers/grid_defines.include.glsl"


layout(local_size_x =X)in;



uniform uint bufferSize;

void main(void){
  uint unsortedIndex = gl_GlobalInvocationID.x;
  if(unsortedIndex>=bufferSize){
    return;
  }

  PREC_VEC3_TYPE pos = INPUT4_AT(INPUT4,INPUT4_VAR,INPUT4_SIZE, unsortedIndex,INPUT4_NUM_BUFFER,INPUT4_INDEX_BUFFER,INPUT4_VAR_SIZE).xyz;

  // Bin due to position in grid
  PREC_VEC3_TYPE positionInGrid= (pos-grid_def.gGridPos)/grid_def.gridSpacing;

  //floor
  ivec3 globalGridIndex = ivec3(positionInGrid);


  if(inBounds(globalGridIndex,grid_def.gGridDim)){
    uint voxelAndTileIndex = SORTING_KEY(globalGridIndex,grid_def.gGridDim);
    uint scanIndex =
      //scan_local
      INPUT2_AT(INPUT2,INPUT2_VAR,INPUT2_SIZE,get_scan_local_index(voxelAndTileIndex),INPUT2_NUM_BUFFER,INPUT2_INDEX_BUFFER,INPUT2_VAR_SIZE)
#ifndef SCAN_DIRECT_WRITE_BACK
      +
      //scan_block
      INPUT3_AT(INPUT3,INPUT3_VAR,INPUT3_SIZE,get_scan_block_index(voxelAndTileIndex),INPUT3_NUM_BUFFER,INPUT3_INDEX_BUFFER,INPUT3_VAR_SIZE)
#endif
      ;
    uint scanOffset =
      INPUT_AT(INPUT,INPUT_VAR,INPUT_SIZE,unsortedIndex,INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER,INPUT_VAR_SIZE);
    uint sortedIndex = scanIndex + scanOffset;

    OUTPUT_AT(OUTPUT,OUTPUT_VAR,OUTPUT_SIZE,sortedIndex,OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER,OUTPUT_VAR_SIZE) = voxelAndTileIndex;
  }
}
