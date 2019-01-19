#ifndef DEFINES_H
#define DEFINES_H

#define BENCHMARK
//#define MARKERS
//#define NDEBUG

// slower
//#define SCAN_DIRECT_WRITE_BACK

//#define BIN_MULTIPLE_ELEMENTS 2
//#define DOUBLE_PREC

#define WINDOW_WIDTH 1280
#define WINDOW_HEIGHT 720

#define GRID_RENDERING_RESOLUTION_X 10
#define GRID_RENDERING_RESOLUTION_Y 10
#define GRID_RENDERING_RESOLUTION_Z 10

#define GRID_POS_X 0.5125
#define GRID_POS_Y 0.5125
#define GRID_POS_Z 1.5125
#define GRID_DIM_X 201
#define GRID_DIM_Y 201
#define GRID_DIM_Z 201
#define GRID_SPACING 0.05
#define PARTICLE_TO_GRID_SIZE 64
#define GRID_COLLISION_PLANE_OFFSET 4
#define PHYSIC_DT 1e-3
#define STEP_DT 0.0333

#define NUMOFPARTICLES 32 * 64 * 64

#define NUM_OF_GPGPU_THREADS_X 1024

#define PARTICLE_POS_BUFFER 0
#define PARTICLE_VEL_BUFFER 1
#define PARTICLE_FE_BUFFER 4
#define PARTICLE_FP_BUFFER 5
#define PARTICLE_VEL_N_BUFFER 6
#define PARTICLE_DELTA_VEL_BUFFER_0 13
#define PARTICLE_DELTA_VEL_BUFFER_1 14
#define PARTICLE_DELTA_VEL_BUFFER_2 15

#define GRID_POS_BUFFER 2
#define GRID_VEL_BUFFER 3
#define GRID_VEL_N_BUFFER 7
#define GRID_FORCE_BUFFER 16

#define COLLIDER_POS_BUFFER 8
#define COLLIDER_VEL_BUFFER 9
#define COLLIDER_NOR_BUFFER 10
#define COLLIDER_TYPE_BUFFER 11
#define COLLIDER_FRIC_BUFFER 12

#define YOUNG_MODULUS 6e6
#define POISSON 0.2
#define HARDENING 30.0
#define CRIT_COMPRESSION 1.0e-2
#define CRIT_STRETCH 1e-3
#endif  // DEFINES_H
        //
        // 300x100x300 105 Fps
        // 200x100x200 155 Fps
        // 100x100x100 215 Fps
        // 63 x63 x63  180 Fps
        // 64 x64 x64  145 Fps
        // 50 x50 x50  285 Fps

