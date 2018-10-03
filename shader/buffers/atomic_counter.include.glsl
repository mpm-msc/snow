#ifndef ATOMIC_COUNTER_BUFFER
#define ATOMIC_COUNTER_BUFFER
#include "shader/shared_hpp/buffer_bindings.hpp"
#include "shader/buffers/counter.include.glsl"

layout(std430, binding = ATOMIC_COUNTER_BINDING) buffer AtomicCounter{
  Counter counters[];
};
#endif