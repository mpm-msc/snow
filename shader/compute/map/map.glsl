#version 440
layout(local_size_x =X, local_size_y =Y,local_size_z =Z)in;

/*
 * Macros to be defined:
 *
 * {INPUT,OUTPUT} buffer
 * {INPUT,OUTPUT}_VAR var
 * {INPUT,OUTPUT}_SIZE buffer
 * {INPUT,OUTPUT}_NUM_BUFFER double/multi buffer
 * {INPUT,OUTPUT}_INDEX_BUFFER which of the multi buffers
 *
 * where buffer needs to be included
 * e.g. AOS-Layout =>
 * AT(buffer,var,index) =>
 * buffer[index].var
 *
 * UNARY_OP(value) func(value)
 */
#ifndef PERMUTATION_IN
#define PERMUTATION_IN(i) i
#endif

#ifndef PERMUTATION_OUT
#define PERMUTATION_OUT(i) i
#endif


uniform uint bufferSize;

void main(void){
	uint i= gl_GlobalInvocationID.x;
	if(i<bufferSize){
#ifndef INPUT2
		OUTPUT_AT(OUTPUT,OUTPUT_VAR,OUTPUT_SIZE,PERMUTATION_OUT(i),OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER) = UNARY_OP(INPUT_AT(INPUT,INPUT_VAR,INPUT_SIZE,PERMUTATION_IN(i),INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER));
#else
		OUTPUT_AT(OUTPUT,OUTPUT_VAR,OUTPUT_SIZE,PERMUTATION_OUT(i),OUTPUT_NUM_BUFFER,OUTPUT_INDEX_BUFFER) = BINARY_OP(
				UNARY_OP(INPUT_AT(INPUT,INPUT_VAR,INPUT_SIZE,PERMUTATION_IN(i),INPUT_NUM_BUFFER,INPUT_INDEX_BUFFER)),

				UNARY_OP2(INPUT2_AT(INPUT2,INPUT2_VAR,INPUT2_SIZE,PERMUTATION_IN(i),INPUT2_NUM_BUFFER,INPUT2_INDEX_BUFFER)))
			;
#endif
	}
}
