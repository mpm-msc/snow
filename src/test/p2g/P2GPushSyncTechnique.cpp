#include "p2gpushsynctechnique.hpp"

void P2GPushSyncTechnique::init(P2GData&& data, IOBufferData&& io) {
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
void P2GPushSyncTechnique::init_sync(P2GData&& data, IOBufferData&& io) {
  filename = "shader/test/shared/p2g_sync.glsl";
  init(std::move(data), std::move(io));
}
void P2GPushSyncTechnique::uniforms_init(UniformsStatic&& uniforms) {
  gGridDim = uniforms.gGridDim;
}
void P2GPushSyncTechnique::dispatch(UniformsDynamic&& uniforms) {
  Technique::use();
  uniforms_update(std::move(uniforms));
  glDispatchCompute(gGridDim.x / local_size.x, gGridDim.y / local_size.y,
                    gGridDim.z / local_size.z);
}
void P2GPushSyncTechnique::dispatch_with_barrier(UniformsDynamic&& uniforms) {
  dispatch(std::move(uniforms));
  glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);
}
void P2GPushSyncTechnique::uniforms_update(UniformsDynamic&& uniforms) {
  Technique::uniform_update("ParticleMaxCount", uniforms.max_count);
}

