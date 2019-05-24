Further Development of https://github.com/MeyerFabian/snow focusing on performance optimization on the GPU.

The code is very hard to read due to a lot of different tests and preprocessor commands. I am focusing on [improving](#possible-improvements) it at the moment. Written text of my master thesis can be found here: [Thesis](https://github.com/MeyerFabian/msc). 

Presentation can be found at: [Pres](https://github.com/MeyerFabian/msc/blob/master/pres/pres.pdf).

Video of my BA: [Youtube](https://www.youtube.com/watch?v=JlNf7CUW4UY).

Overview
====
  * Implemented the MPM-Transfers using OpenGL Compute for physically based simulations of continuum material.
  * Tested PIC as well as APIC transfers: [Jiang et al.,2016](https://arxiv.org/pdf/1603.06188.pdf), [Jiang et al. 2015](https://www.math.ucla.edu/~jteran/papers/JSSTS15.pdf)
  * Designed a shader generator for OpenGL to allow for various permutations of GPGPU compute programs.
  * Enforced Test-driven development to monitor numerical precision and performance metrics using NVIDIA Nsight & [OpenGL Timer queries](https://www.khronos.org/registry/OpenGL/extensions/ARB/ARB_timer_query.txt).
  * Implemented SVD from [McAdams et al., 2011](https://minds.wisconsin.edu/bitstream/handle/1793/60736/TR1690.pdf?sequence=1).
  * Tested out different data formats (SoA vs. AoS) using reflection of [magic_get](https://github.com/apolukhin/magic_get). (Would recommend reflection macros though.)
  * Applied preprocessing in form of binning \& counting sort to increase coalescing \& caching behaviors. See, [Rama C. Hoetzlein, Fast Fixed-Radius Nearest Neighbors](http://on-demand.gputechconf.com/gtc/2014/presentations/S4117-fast-fixed-radius-nearest-neighbor-gpu.pdf).
  * Applied preprocessing of stream compaction of active cell regions.
  * Tested out batching which batches particles in fixed size groups and accumulates their data at once.
  * Accelerated governing transfers by fusing threads and utilizing the shared memory architecture leading to order-independence of data and up to 10x speedup over a naive GPU implementation.
  
Comparison
====
Also take a look at [GPUMPM](https://github.com/kuiwuchn/GPUMPM) which was simultaneously beeing developed and additionally uses warp operations to further speedup the Material Point Method.

|                 | This                               | Gao 2018 et al.                |
|-----------------|------------------------------------|--------------------------------|
|Sort             | Count/Histogram for each var.      | Count/Histogram sel. variables |
|Filtering domain | Filter-operation                   | Sparse Voxel Grid structure    |
|Transfers        | Shared mem. only                   | Warp-shuffle operations        |

Performance
====

|Method                                            |μs        |Speedup |VRAM   | L2      |SM         |
|--------------------------------------------------|----------|--------|------ |---------|-----------|
|global                                            |44,442    | -      | 4.6%  |34.4%    |7.7%       |
|[snow](https://github.com/MeyerFabian/snow)       |45,342    |0.98x   |25.1%  |42.4%    |11.7%      |
|[snow](https://github.com/MeyerFabian/snow) sorted|23,007	   |1.97x   |43.8%  |59.0%    |23.9%      |
|global sorted                                     |20,484	   |2.21x   | 7.0%  |**44.0%**|16.1%      |
|P2G-pull                                          |4,747     |9.55x   | 3.7%  | 6.7%    |39.4%      |
|P2G-atomic*		                                     |3,148     |14.40x  | 5.3%  | 6.7%    |**65.0%**  |
|P2G-sync*                                         |**2,595** |17.47x  | 5.9%  | 7.6%    |**67.0%**  |

P2G-transfers of one million uniformly positioned particles with random velocities between between [-1.0;1.0] in a 128x 128x128 grid. They form a rotated (unsorted) cube with four particles per cell. Block size is (8,4,4). Methods marked with a star(*) are executed with batching = 4.

Abstract
====
The material point method is allowing for physically based simulations. It has found its way into computer graphics and since then rapidly expanded. The material point method’s hybrid use of Lagrangian particles as a persistent storage and a background uniform Eulerian grid enables solving of various partial differential equations with ease.

The material point method suffers from high execution times and is thus only viable for hero shots. The method is however highly parallelizable. Thus, this thesis proposes how to accelerate the material point method using GPGPU techniques. Core of the material point method are grid and particles transfers that interpolate between the two structures. These transfers are executed multiple times per physical time step. Preprocessing steps might be taken if their computing time is outweighed.

Deep sorting with counting sort increases coalescing and L2 cache hit rates. Binning allows to divide the grid into blocks for shared memory filtering techniques. All operations do not rely on fixed bin size. As another preprocessing step, only grid blocks are executed which have particles in them.

Project
====
Ready for Windows:  VS (2017 tested), NMake(compile_commands activated)
Theoretically portable to unix-systems (no dependency restrictions)

Dependencies
===
C++17

[GLEW](http://glew.sourceforge.net/) (Tested 2.1.0, build from source)

[GLFW](http://www.glfw.org/) (Tested 3.2.1, build from source)

[ASSIMP](http://www.assimp.org/index.php/downloads) (Tested 4.1.0, build from source)

[GLM](https://glm.g-truc.net/0.9.9/index.html) (Tested GLM 0.9.9.0, Header only)

Compute Shader ready GFX introduced with OpenGL 4.3

Included Dependencies
===
[stb_image](https://github.com/nothings/stb/blob/master/stb_image.h)

[voxelizer](https://github.com/takagi/cl-voxelize/) (A precomputed voxelization of the Stanford-Bunny is already included in resources/model/)

[magic_get](https://github.com/apolukhin/magic_get)

Possible Improvements
====
  * Documentation & Readability
  * BufferDataInterface should rely on composition as opposed to inheritance or go down [ecs](https://en.wikipedia.org/wiki/Entity_component_system)-route  
  * Tests should rely more on polymorphism 
  * Test out warp operations
