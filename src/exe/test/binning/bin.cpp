#ifndef GLM_INCLUDE_GUARD
#define GLM_INCLUDE_GUARD
#include <glm/gtc/random.hpp>
#include <numeric>
#define GLM_ENABLE_EXPERIMENTAL
#include <glm/gtx/norm.hpp>
#endif

#ifndef UNARY_OPERATION_GL
#include "../../../test/soa_aos/gpu_in_out_structs.hpp"
#define INIT_DATA                                             \
  PREC_VEC_TYPE(glm::linearRand(1.0f), glm::linearRand(1.0f), \
                glm::linearRand(1.0f), glm::linearRand(1.0f))
#define BUFFER_IN_NAME "shader/test/soa_aos/buffer_in.include.glsl"
#define BUFFER_OUT_NAME "shader/test/soa_aos/buffer_out.include.glsl"
#endif

#include <execution>
#include "../../../snow/shader/shader.hpp"
#include "../../../snow/utils/benchmarker.hpp"
#include "../../../test/binning/binTechnique.hpp"
#include "../../../test/test_util.hpp"
int main() {
  GLFWWindow();
  GLuint numVectors = 1024 * 1024;
  std::vector<Input> input_data;
  std::vector<Output> output_data_init;
  for (size_t i = 0; i < numVectors; i++) {
    input_data.push_back({INIT_DATA, INIT_DATA});
    // val here (50.0f) is actually overwritten, so this is another test
    output_data_init.push_back({0.0f, 0.0f});
  }
#ifdef AOS_LAYOUT
  BufferLayout layout = BufferLayout::AOS;
#else
  BufferLayout layout = BufferLayout::SOA;
#endif
  Buffer<Input> input(BufferType::SSBO, BufferUsage::STATIC_DRAW, layout,
                      BUFFER_IN_NAME);

  input.transfer_to_gpu(input_data);
  input.gl_bind_base(1);

  Buffer<Output> output(BufferType::SSBO, BufferUsage::STATIC_DRAW, layout,
                        BUFFER_OUT_NAME);
  output.transfer_to_gpu(output_data_init);
  output.gl_bind_base(2);
  BinningTechnique::BinningData binning_data({
      // IOBufferData
      //   In
      "g_in",
      "in_v",
      input.get_buffer_info(),
      //   Out
      "g_out",
      "out_g",
      output.get_buffer_info(),
      // numVectors
      numVectors,
  });

  auto test = BinningTechnique();
  test.init(std::move(binning_data));
  BenchmarkerCPU bench;
  bench.time("Total CPU time spent", [&numVectors, &test]() {
    executeTest(1'000, [&test, numVectors]() {
      return BenchmarkerGPU::getInstance().time("map", [&test, numVectors]() {
        test.dispatch_with_barrier(numVectors);
      });
    });
  });

  BenchmarkerGPU::getInstance().collect_times_last_frame();
  BenchmarkerGPU::getInstance().collect_times_last_frame();

  auto m(output.transfer_to_cpu(std::size(output_data_init)));
  BenchmarkerGPU::write_to_file("Binning");
  bench.write_to_file("BinningCPU");
  auto sum = std::transform_reduce(
      std::begin(input_data), std::end(input_data), 0.0f, std::plus<>(),
      [](const auto& elem) { return UNARY_OPERATION(elem.in_v); });

  auto sum_gpu =
      std::transform_reduce(std::begin(m), std::end(m), 0.0f, std::plus<>(),
                            [](const auto& elem) { return elem.out_g; });
  std::cout << "CPU map, CPU sum: " << sum << std::endl;
  std::cout << "GPU map, CPU sum: " << sum_gpu << std::endl;
  std::cout << "Difference: " << std::abs(sum - sum_gpu) << std::endl;

  GLFWWindow::swapBuffers();

  GLFWWindow::stop();

  return 0;
}
