#include "countTechnique.hpp"
void CountingTechnique::init(CountingData&& data) {
  auto shader = std::make_shared<Shader>(
      ShaderType::COMPUTE, "shader/compute/preprocess/count.glsl");

  shader->add_n_define(data.numVectors);
  shader->add_aos_define(data.io.in_buffer.info.layout);
  shader->set_local_size(local_size);

  std::vector<Shader::CommandType> vec = {};
  auto io_cmds(data.io.generateCommands());
  vec.insert(std::end(vec), std::begin(io_cmds), std::end(io_cmds));

  shader->add_cmds(vec.begin(), vec.end());

  Technique::add_shader(std::move(shader));
  Technique::upload();
  Technique::use();
  uniforms_init(std::move(data.uniforms));
}
void CountingTechnique::uniforms_init(UniformsStatic&& uniforms) {
  Technique::uniform_update("gGridPos", uniforms.gGridPos.x,
                            uniforms.gGridPos.y, uniforms.gGridPos.z);
  Technique::uniform_update("gGridDim", uniforms.gGridDim);
  Technique::uniform_update("gridSpacing", uniforms.gridSpacing);
}
void CountingTechnique::dispatch_with_barrier(GLuint numVectors) {
  Technique::use();
  Technique::uniform_update("bufferSize", numVectors);
  glDispatchCompute(numVectors / local_size.x + 1, 1 / local_size.y,
                    1 / local_size.z);
  glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);
}
