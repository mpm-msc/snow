Written text of master thesis can be found here: [Thesis](https://github.com/MeyerFabian/msc).

Presentation can be found at: [Pres](https://github.com/MeyerFabian/msc/blob/master/pres/pres.pdf).

Also take a look at [GPUMPM](https://github.com/kuiwuchn/GPUMPM) which additionally uses warp operations to further speedup the Material Point Method.

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
====
[GLEW](http://glew.sourceforge.net/) (Tested 2.1.0, build from source)

[GLFW](http://www.glfw.org/) (Tested 3.2.1, build from source)

[ASSIMP](http://www.assimp.org/index.php/downloads) (Tested 4.1.0, build from source)

[GLM](https://glm.g-truc.net/0.9.9/index.html) (Tested GLM 0.9.9.0, Header only)

Compute Shader ready GFX introduced with OpenGL 4.3

Included Dependencies
====
[stb_image](https://github.com/nothings/stb/blob/master/stb_image.h)

[voxelizer](https://github.com/takagi/cl-voxelize/) (A precomputed voxelization of the Stanford-Bunny is already included in resources/model/)
