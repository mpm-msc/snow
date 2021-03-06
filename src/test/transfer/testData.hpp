#ifndef TEST_DATA
#define TEST_DATA

#include <vector>

#define GLEW_STATIC
#include <GL/glew.h>

#include <glm/glm.hpp>
struct testData {
  GLuint numParticles;
  GLuint numGridPoints;
  std::vector<Particle_exp> particles;
  std::vector<Particle_exp_2> particles2;
  GridDefines grid_def;
};
#endif

