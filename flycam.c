#include <stdbool.h>

#define NULL 0

typedef struct {
    char pad0[0x10];
    float rx; float ry; float rz; float rw;
    float ux; float uy; float uz; float uw;
    float fx; float fy; float fz; float fw;
    float  x; float  y; float  z;
} Camera;

typedef struct {
    char pad_0[0x40];
    bool dpadUp:1; bool dpadDown:1; bool dpadLeft:1; bool dpadRight:1;
    bool start:1; bool back:1;
    bool leftStick:1; bool rightStick:1;
    bool leftShoulder:1; bool rightShoulder:1;
    int pad_1:2;
    bool a:1; bool b:1; bool x:1; bool y:1;
    unsigned char leftTrigger; unsigned char rightTrigger;
    short leftStickX; short leftStickY;
    short rightStickX; short rightStickY;
} Input;

const float triggerMax = 255.0;
const float stickMax = 32768.0;

const float speedModifyRate = 1.0116194403019225;
const float dt = 1.0 / 60.0;
const float baseSpeed = 10.0;

float speedModifier = 1.0;

void updateCamera(void* cambase, void* inputbase) {
    if (inputbase == NULL)
        return;

    Camera *cam = (Camera*)cambase;
    Input *input = (Input*)inputbase;

    if (input->rightShoulder && input->leftShoulder)
        speedModifier = 1.0;
    else if (input->rightShoulder)
        speedModifier *= speedModifyRate;
    else if (input->leftShoulder)
        speedModifier /= speedModifyRate;

    float moveX = input->leftStickX / stickMax;
    float moveZ = input->leftStickY / stickMax;
    float moveY = ((float)input->rightTrigger - (float)input->leftTrigger) / triggerMax;

    float vx = cam->rx * moveX + cam->ux * moveY + cam->fx * moveZ;
    float vy = cam->ry * moveX + cam->uy * moveY + cam->fy * moveZ;
    float vz = cam->rz * moveX + cam->uz * moveY + cam->fz * moveZ;

    float speed = baseSpeed * speedModifier;
    if (input->b) speed *= 2.0;

    cam->x += vx * speed * dt;
    cam->y += vy * speed * dt;
    cam->z += vz * speed * dt;
}