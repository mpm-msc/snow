#ifndef MAPREDUCE_BUFFERS_H
#define MAPREDUCE_BUFFERS_H
#include <glm/glm.hpp>
#include <glm/gtc/random.hpp>
#include <memory>
#include <vector>
#include "../../snow/buffer/buffer.hpp"
#include "../../snow/shader/technique.hpp"
class MapReduceBuffers {
 public:
  struct Input {
    glm::vec4 v;
  };

  struct Output {
    float f;
  };
  MapReduceBuffers(GLuint numVectors, LocalSize local_size);
  MapReduceBuffers(GLuint numVectors, LocalSize local_size, GLuint);
  std::vector<Input> input_data;
  std::vector<Output> output_data_init;
  std::shared_ptr<Buffer<Input>> input;
  std::shared_ptr<Buffer<Output>> output;
};
#endif

