/*
#include "shader/shared_hpp/voxel_tile_size.hpp"
#define VOXEL_SIZE_X_OFFSET 0
#define VOXEL_SIZE_Y_OFFSET VOXEL_SIZE_X_BIT
#define VOXEL_SIZE_Z_OFFSET VOXEL_SIZE_Y_BIT + VOXEL_SIZE_Y_OFFSET
#define TILE_SIZE_X_OFFSET  VOXEL_SIZE_Z_BIT + VOXEL_SIZE_Z_OFFSET
#define TILE_SIZE_Y_OFFSET  TILE_SIZE_X_BIT  + TILE_SIZE_X_OFFSET
#define TILE_SIZE_Z_OFFSET  TILE_SIZE_Y_BIT  + TILE_SIZE_Y_OFFSET
uvec3 tileAddressToUvec3(uint address){
return uvec3(
bitfieldExtract(
address,
TILE_SIZE_X_BIT,
TILE_SIZE_X_OFFSET),
bitfieldExtract(
address,
TILE_SIZE_Y_BIT,
TILE_SIZE_Y_OFFSET),
bitfieldExtract(
address,
TILE_SIZE_Z_BIT,
TILE_SIZE_Z_OFFSET)
);
}

uvec3 voxelAddressToUvec3(uint address){
return uvec3(
bitfieldExtract(
address,
VOXEL_SIZE_X_BIT,
VOXEL_SIZE_X_OFFSET),
bitfieldExtract(
address,
VOXEL_SIZE_Y_BIT,
VOXEL_SIZE_Y_OFFSET),
bitfieldExtract(
address,
VOXEL_SIZE_Z_BIT,
VOXEL_SIZE_Z_OFFSET)
);
}

uint voxelAndtileAddressToUint(uvec3 voxelAddress,
uvec3 tileAddress){
uint address=0;
address = bitfieldInsert(
address,
voxelAddress.x,
VOXEL_SIZE_X_BIT,
VOXEL_SIZE_X_OFFSET
);

address = bitfieldInsert(
address,
voxelAddress.y,
VOXEL_SIZE_Y_BIT,
VOXEL_SIZE_Y_OFFSET
);

address = bitfieldInsert(
address,
voxelAddress.z,
VOXEL_SIZE_Z_BIT,
VOXEL_SIZE_Z_OFFSET
);

address = bitfieldInsert(
address,
tileAddress.x,
TILE_SIZE_X_BIT,
TILE_SIZE_X_OFFSET
);

address = bitfieldInsert(
		address,
		tileAddress.y,
		TILE_SIZE_Y_BIT,
		TILE_SIZE_Y_OFFSET
		);

address = bitfieldInsert(
		address,
		tileAddress.z,
		TILE_SIZE_Z_BIT,
		TILE_SIZE_Z_OFFSET
		);
return address;
}
*/
