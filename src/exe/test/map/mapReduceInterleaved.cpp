#include "../../../test/map/mapReduceSingle.hpp"
#include "../../../test/map/mapReduceTechnique.hpp"
int main() {
  GLFWWindow();

  GLuint numVectors = 1'024 * 1'024;
  LocalSize local_size = {1024, 1, 1};

  MapReduceTest test(numVectors, "MapReduceInterleaved",
                     "shader/test/map/mapReduceInterleaved.glsl", local_size);

#ifdef MARKERS
  while (GLFWWindow::shouldClose()) {
#endif
    BenchmarkerGPU::getInstance().time(
        test.name, [&test, numVectors]() { test.run(numVectors); });

    GLFWWindow::clear();
    GLFWWindow::swapBuffers();
    BenchmarkerGPU::getInstance().collect_times_last_frame();
#ifdef MARKERS
  }
#endif

  BenchmarkerGPU::getInstance().collect_times_last_frame();
  BenchmarkerGPU::write_to_file("MapReduce");
  test.print();

  GLFWWindow::stop();
  return 0;
}
