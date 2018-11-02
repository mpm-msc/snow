#ifndef COUNT_SRT_HPP_CN2ZL6DH
#define COUNT_SRT_HPP_CN2ZL6DH

#include <glm/gtc/random.hpp>

#define GLM_ENABLE_EXPERIMENTAL
#include "../../../../shader/shared_hpp/buffer_bindings.hpp"
#include "../../../test/BufferData.hpp"
#include "../../../test/reorder/countingSortPipeline.hpp"
#include "../../../test/test_util.hpp"
#include "../../src/snow/particle/particle_exp.hpp"

struct testData {
  GLuint numParticles;
  GLuint numGridPoints;
  std::vector<Particle_exp> particles;
  std::vector<Particle_exp_2> particles2;
  glm::uvec3 gGridDim;
  PREC_VEC3_TYPE gGridPos;
  PREC_SCAL_TYPE gridSpacing;
};

struct OutputData {
  std::vector<Particle_exp> particles;
};

OutputData test(testData&& data) {
  GLFWWindow();

#ifdef AOS_LAYOUT
  BufferLayout layout = BufferLayout::AOS;
#else
  BufferLayout layout = BufferLayout::SOA;
#endif

  /**********************************************************************
   *                          Buffer creations                          *
   **********************************************************************/

  // Particle_exp
  Buffer<Particle_exp> particle_buffer(
      BufferType::SSBO, BufferUsage::STATIC_DRAW, layout,
      "shader/buffers/particle_system.include.glsl");

  particle_buffer.transfer_to_gpu(data.particles);
  particle_buffer.gl_bind_base(PARTICLE_SYSTEM_BINDING);
  // Particle_exp2
  Buffer<Particle_exp_2> particle_2_buffer(
      BufferType::SSBO, BufferUsage::STATIC_DRAW, layout,
      "shader/buffers/particle_system.include.glsl");

  particle_2_buffer.transfer_to_gpu(data.particles2);
  particle_2_buffer.gl_bind_base(PARTICLE_SYSTEM_BINDING_2);

  /**********************************************************************
   *                    Techniques + IOData creation                    *
   **********************************************************************/

  auto Particle_pos_unsorted = BufferData(
      "particles", "Particle_pos_mass", particle_buffer.get_buffer_info(),
      data.numParticles, 2, "0", "Particle_exp_size");

  auto Particle_2_unsorted =
      BufferData("particles_2", "", particle_buffer.get_buffer_info(),
                 data.numParticles, 2, "0",

                 "Particle_exp_2_size");
  IOBufferData io_cnt_srt;
  // OUTPUT
  io_cnt_srt.out_buffer.push_back(
      std::make_unique<BufferData>(Particle_pos_unsorted));
  io_cnt_srt.out_buffer.push_back(
      std::make_unique<BufferData>(Particle_2_unsorted));

  CountingSortPipeline::CountingSortData cnt_srt_data{
      layout,
      data.gGridDim,
      data.gGridPos,
      data.gridSpacing,
  };

  CountingSortPipeline cnt_srt_pipeline;
#ifdef REORDER_SINGLE
#ifdef REORDER_INDEX_WRITE
  cnt_srt_pipeline.initIndexWriteSort(std::move(cnt_srt_data),
                                      std::move(io_cnt_srt));
#else
  cnt_srt_pipeline.initIndexReadSort(std::move(cnt_srt_data),
                                     std::move(io_cnt_srt));
#endif
#else
  cnt_srt_pipeline.initFullSort(std::move(cnt_srt_data), std::move(io_cnt_srt));
#endif

  /**********************************************************************
   *                         execute dispatches                         *
   **********************************************************************/

  BenchmarkerCPU bench;
  bench.time("Total CPU time spent",
             [&cnt_srt_pipeline, numParticles = data.numParticles,
              numGridPoints = data.numGridPoints]() {
               executeTest(1, [&cnt_srt_pipeline, &numParticles,
                               &numGridPoints]() {  // reset
                 // reorder
                 BenchmarkerGPU::getInstance().time(
                     "Sort Pipeline",
                     [&cnt_srt_pipeline, &numParticles, &numGridPoints]() {
                       cnt_srt_pipeline.run({numParticles, numGridPoints});
                     });
               });
             });

  BenchmarkerGPU::getInstance().collect_times_last_frame();
  BenchmarkerGPU::getInstance().collect_times_last_frame();
  BenchmarkerGPU::write_to_file("CountingSortPipeline");
  bench.write_to_file("CountingSortPipelineCPU");
  return {};
}
#endif /* end of include guard: COUNT_SRT_HPP_CN2ZL6DH */
