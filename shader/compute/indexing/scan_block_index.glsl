uniform uint scanBlockSize;
//returns uvec2(scan_local_index, scan_block_index)
uint get_scan_local_index(uint voxel_and_tile_index){
	return voxel_and_tile_index;
}
uint get_scan_block_index(uint voxel_and_tile_index){
	return voxel_and_tile_index / scanBlockSize;
}
