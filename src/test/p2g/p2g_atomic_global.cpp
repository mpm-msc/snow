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
void P2G_atomic_global::init_too_parallel(P2GData&& data, IOBufferData&& io) {
  filename = "shader/test/atomic_global/p2g.glsl";
  ydim = 64;
  init(std::move(data), std::move(io));
}
void P2G_atomic_global::init_looping(P2GData&& data, IOBufferData&& io) {
  filename = "shader/test/atomic_global/p2gLoop.glsl";
  ydim = 1;
  init(std::move(data), std::move(io));
}
void P2G_atomic_global::uniforms_init(UniformsStatic&& uniforms) {
  Technique::uniform_update("gGridPos", uniforms.gGridPos.x,
                            uniforms.gGridPos.y, uniforms.gGridPos.z);
  Technique::uniform_update("gGridDim", uniforms.gGridDim);
  Technique::uniform_update("gridSpacing", uniforms.gridSpacing);
}
void P2G_atomic_global::dispatch(UniformsDynamic&& uniforms) {
  Technique::use();
  auto numParticles = uniforms.numParticles;
  uniforms_update(std::move(uniforms));
  glDispatchCompute(numParticles / local_size.x, ydim, 1);
}
void P2G_atomic_global::dispatch_with_barrier(UniformsDynamic&& uniforms) {
  dispatch(std::move(uniforms));
  glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);
}
void P2G_atomic_global::uniforms_update(UniformsDynamic&& uniforms) {
  Technique::uniform_update("indexSize", uniforms.numParticles);
}
