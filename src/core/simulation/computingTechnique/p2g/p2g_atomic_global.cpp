#include "p2g_atomic_global.hpp"

void P2G_atomic_global::init(P2GData&& data, IOBufferData&& io) {
  auto shader = std::make_shared<Shader>(ShaderType::COMPUTE, filename);
  shader->set_local_size(local_size);

  std::vector<Shader::CommandType> vec = {};

  auto io_cmds(io.generateCommands());
  vec.insert(std::end(vec), std::begin(io_cmds), std::end(io_cmds));

  shader->add_cmds(vec.begin(), vec.end());

  Technique::add_shader(std::move(shader));
  Technique::upload();
  Technique::use();
  uniforms_init(std::move(data.uniforms));
}
/* Parallelizes also for each grid node in the support.
 *  @io.
 *    in_buffer[x]    : BufferData or SortedBufferData with particle variables
 *    out_buffer[x]   : BufferData with grid variables
 */
void P2G_atomic_global::init_too_parallel(P2GData&& data, IOBufferData&& io) {
  filename = "shader/compute/mpm/global/p2g.glsl";
  too_parallel = true;
  init(std::move(data), std::move(io));
}
/* Parallelizes with an iterative, sequential loop over all nodes in the
 * support.
 *  @io.
 *    in_buffer[x]    : BufferData or SortedBufferData with particle variables
 *    out_buffer[x]   : BufferData with grid variables
 */
void P2G_atomic_global::init_looping(P2GData&& data, IOBufferData&& io) {
  filename = "shader/compute/mpm/global/p2gLoop.glsl";
  init(std::move(data), std::move(io));
}
void P2G_atomic_global::uniforms_init(UniformsStatic&& uniforms) {}
// @uniforms.numParticles : expected global size
void P2G_atomic_global::dispatch(UniformsDynamic&& uniforms) {
  Technique::use();
  auto numParticles = uniforms.numParticles;
  uniforms_update(std::move(uniforms));
  ydim = 1;
  if (too_parallel) {
    ydim = 64;
  }
  glDispatchCompute(numParticles / local_size.x + 1, ydim, 1);
}
void P2G_atomic_global::dispatch_with_barrier(UniformsDynamic&& uniforms) {
  dispatch(std::move(uniforms));
  glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);
}
void P2G_atomic_global::uniforms_update(UniformsDynamic&& uniforms) {
  Technique::uniform_update("indexSize", uniforms.numParticles);
}

