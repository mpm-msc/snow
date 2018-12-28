#ifndef MAPTECHNIQUE_H
#define MAPTECHNIQUE_H
#include <optional>
#include "../../snow/buffer/buffer.hpp"
#include "../../snow/shader/technique.hpp"
#include "../IOBufferData.hpp"

class MapTechnique : public Technique {
 public:
  LocalSize local_size = {1024, 1, 1};
  bool multiple;
  struct MapData {
    std::string filename;
    std::string gl_unary_op;
    GLuint numVectors;  // SOA only
    std::optional<LocalSize> local_size;
  };

  struct DispatchData {
    GLuint bufferSize;
    bool multiple = false;
    GLuint seq_elements = 1;
  };

  struct UniformsDynamic {
    GLuint bufferSize;
    GLuint dispatchDim_x;
  };

  void uniform_update(UniformsDynamic&& data);
  void init(MapData&& data, IOBufferData&&);
  void init(std::vector<Shader::CommandType>&& in_cmds, MapData&& data,
            IOBufferData&& io);
  void dispatch(DispatchData&& data);
  void dispatch_with_barrier(DispatchData&& data);

 private:
  std::vector<Shader::CommandType> commands;
};
#endif

