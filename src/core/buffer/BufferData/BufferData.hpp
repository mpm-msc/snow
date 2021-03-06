#ifndef BUFFERDATA_HPP
#define BUFFERDATA_HPP
#include "../../shader/shader.hpp"
#include "../buffer.hpp"
#include "BufferDataInterface.hpp"
class BufferData : public BufferDataInterface {
 public:
  BufferData(std::string in_name, std::string in_var, BufferInfo in_info,
             GLuint in_size, GLuint in_buf_num = 1,
             std::string in_buf_ind = "0", std::string in_var_size = "1")
      : name(in_name),
        var(in_var),
        info(in_info),
        bufferSize(in_size),
        bufferNum(in_buf_num),
        bufferIndex(in_buf_ind),
        var_size_def(in_var_size) {}

  std::vector<Shader::CommandType> generateCommands(bool, std::string) override;
  virtual std::unique_ptr<BufferDataInterface> cloneBufferDataInterface()
      override;

  void setName(std::string) override;
  std::string getName() override;

  void setVariable(std::string) override;
  std::string getVariable() override;

  void setIndexBuffer(std::string) override;
  std::string getIndexBuffer() override;

  GLuint getSize() override;

  std::string name;
  std::string var;
  BufferInfo info;
  GLuint bufferSize;
  GLuint bufferNum = 1;
  std::string bufferIndex = "0";
  std::string var_size_def = "1";
};

#endif /* end of include guard: BUFFERDATA_HPP */

