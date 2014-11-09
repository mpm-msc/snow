#ifndef MYRENDERINGENGINE_H
#define MYRENDERINGENGINE_H
#include "../renderingEngine.h"
class myRenderingEngine : public renderingEngine
{
public:
    myRenderingEngine(std::shared_ptr<std::vector< Mesh >> const meshes, std::shared_ptr<ParticleSystem> const particles)
        :renderingEngine(meshes,particles){
    }
    virtual bool init();
    virtual void render();
    virtual bool shouldClose();
    virtual void stop();

    void fillBufferFromMeshes();
    void initVBO();
    void shadowMapPass();
    void renderPass();
    void renderQueue();
};
#endif // MYRENDERINGENGINE_H
