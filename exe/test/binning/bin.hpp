#ifndef GLM_INCLUDE_GUARD
#define GLM_INCLUDE_GUARD
#include "../../../src/core/utils/defines.hpp"

#include <glm/gtc/random.hpp>
#include <numeric>
#include "../../../shader/shared_hpp/buffer_bindings.hpp"
#define GLM_ENABLE_EXPERIMENTAL
#include <glm/gtx/norm.hpp>
#endif

#ifndef UNARY_OPERATION_GL
#include "../../../src/core/object/particle/particle_exp.hpp"

#define BUFFER_IN_NAME "shader/buffers/particle_system.include.glsl"
#define BUFFER_OUT_NAME "shader/buffers/atomic_counter.include.glsl"
#define BUFFER_OUT2_NAME "shader/buffers/particle_grid_offset.include.glsl"
#endif

#include <execution>
#include "../../../src/core/buffer/BufferData//BufferData.hpp"
#include "../../../src/core/object/grid/grid_def.hpp"
#include "../../../src/core/shader/shader.hpp"
#include "../../../src/core/simulation/computingTechnique/binning/binTechnique.hpp"
#include "../../../src/core/simulation/computingTechnique/map/mapTechnique.hpp"
#include "../../../src/core/utils/benchmarker.hpp"
#include "../../../src/test/test_util.hpp"

struct testData {
  GLuint numVectors;
  GLuint numGridPoints;
  std::vector<Particle_exp> particles;
  std::vector<GLuint> binning;
  std::vector<GLuint> grid_offset;
  GridDefines grid_def;
};

struct OutputData {
  std::vector<GLuint> binning;
  std::vector<GLuint> grid_offset;
};

OutputData test(testData& data) {
  GLFWWindow();
#ifdef AOS_LAYOUT
  BufferLayout layout = BufferLayout::AOS;
#else
  BufferLayout layout = BufferLayout::SOA;
#endif

  Buffer<GridDefines> grid_def_buffer(
      BufferType::UNIFORM, BufferUsage::DYNAMIC_DRAW, BufferLayout::AOS);

  grid_def_buffer.transfer_to_gpu(std::vector<GridDefines>{data.grid_def});
  grid_def_buffer.gl_bind_base(GRID_DEFINES_BINDING);

  Buffer<Particle_exp> input(BufferType::SSBO, BufferUsage::STATIC_DRAW, layout,
                             BUFFER_IN_NAME);

  input.transfer_to_gpu(data.particles);
  input.gl_bind_base(PARTICLE_SYSTEM_BINDING);

  Buffer<GLuint> output(BufferType::SSBO, BufferUsage::STATIC_DRAW, layout,
                        BUFFER_OUT_NAME);
  output.transfer_to_gpu(data.binning);
  output.gl_bind_base(ATOMIC_COUNTER_BINDING);

  // BufferData
  auto Counter_i = BufferData(
      // INPUT
      "counters", "Counter_i", output.get_buffer_info(), data.numGridPoints);

  MapTechnique::MapData map_data{
      "shader/compute/map/map.glsl",
      // unary_op
      "0",
  };
  IOBufferData io_reset;
  // INPUT
  io_reset.in_buffer.push_back(std::make_unique<BufferData>(Counter_i));

  // OUTPUT
  io_reset.out_buffer.push_back(std::make_unique<BufferData>(Counter_i));

  auto resetCounter = MapTechnique();
  resetCounter.init(std::move(map_data), std::move(io_reset));

  BinningTechnique::BinningData binning_data{
#ifdef MULTIPLE_ELEMENTS
      "shader/test/sort/bin/bin_mult.glsl",
#else
      "shader/compute/sort/bin/bin.glsl",
#endif
#ifdef MULTIPLE_ELEMENTS
      true,
      MULTIPLE_ELEMENTS,
#endif
  };

  auto Particle_pos_mass = BufferData("particles", "Particle_pos_vol",
                                      input.get_buffer_info(), data.numVectors);

#ifdef OUTPUT2

  Buffer<GLuint> output2(BufferType::SSBO, BufferUsage::STATIC_DRAW, layout,
                         BUFFER_OUT2_NAME);
  output2.transfer_to_gpu(data.grid_offset);

  output2.gl_bind_base(PARTICLE_GRIDOFFSET_BINDING);
  auto GridOffset_i = BufferData("gridOffsets", "GridOffset_i",

                                 output2.get_buffer_info(), data.numVectors);

  IOBufferData io_data;
  // INPUT
  io_data.in_buffer.push_back(std::make_unique<BufferData>(Particle_pos_mass));

  // OUTPUT
  io_data.out_buffer.push_back(std::make_unique<BufferData>(Counter_i));

  // OUTPUT2
  io_data.out_buffer.push_back(std::make_unique<BufferData>(GridOffset_i));

#else
  IOBufferData io_data;

  // INPUT
  io_data.in_buffer.push_back(std::make_unique<BufferData>(Particle_pos_mass));

  // OUTPUT
  io_data.out_buffer.push_back(std::make_unique<BufferData>(Counter_i));
#endif
  auto binCount = BinningTechnique();
  binCount.init(std::move(binning_data), std::move(io_data));

  BenchmarkerCPU bench;
  bench.time("Total CPU time spent", [&binCount, numVectors = data.numVectors,
                                      &resetCounter,
                                      numGridPoints = data.numGridPoints]() {
    executeTest(1, [&binCount, &resetCounter, numVectors, numGridPoints]() {
      BenchmarkerGPU::getInstance().time(
          "resetCounter", [&resetCounter, numGridPoints]() {
            resetCounter.dispatch_with_barrier({numGridPoints, true, 2});
          });
      BenchmarkerGPU::getInstance().time("Counter", [&binCount, numVectors]() {
        binCount.dispatch_with_barrier(numVectors);
      });
    });
  });

  BenchmarkerGPU::getInstance().collect_times_last_frame();
  BenchmarkerGPU::getInstance().collect_times_last_frame();

  BenchmarkerGPU::write_to_file("Counting");
  bench.write_to_file("CountingCPU");
  auto m = output.transfer_to_cpu(std::size(data.binning));
  auto m2 = std::vector<GLuint>();
#ifdef OUTPUT2
  m2 = output2.transfer_to_cpu(std::size(data.grid_offset));
#endif
  GLFWWindow::swapBuffers();
  return {m, m2};
}

