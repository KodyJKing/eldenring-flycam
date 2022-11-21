#include <stdbool.h>

#define NULL 0

typedef struct {
    char pad_0[0x10];
    // Camera matrix:
    float rx; float ry; float rz; float rw; // Right
    float ux; float uy; float uz; float uw; // Up
    float fx; float fy; float fz; float fw; // Forward
    float  x; float  y; float  z;           // Position
} Camera;

typedef struct {
    int packetNumber;
    bool dpadUp : 1; bool dpadDown : 1; bool dpadLeft : 1; bool dpadRight : 1;
    bool start : 1; bool back : 1;
    bool leftStick : 1; bool rightStick : 1;
    bool leftShoulder : 1; bool rightShoulder : 1;
    int pad_0 : 2;
    bool a : 1; bool b : 1; bool x : 1; bool y : 1;
    unsigned char leftTrigger; unsigned char rightTrigger;
    short leftStickX; short leftStickY;
    short rightStickX; short rightStickY;
} Input;

extern int XInputGetState(int controllerIndex, Input *pInput);

const float triggerMax = 255.0;
const float stickMax = 32768.0;

const float speedModifyRate = 1.0116194403019225;
const float dt = 1.0 / 60.0;
const float baseSpeed = 10.0;

float speedModifier = 1.0;
Input input;

void updateCamera(void* cambase) {
    Camera *pCam = (Camera*)cambase;

    XInputGetState(0, &input);

    if (input.rightShoulder && input.leftShoulder)
        speedModifier = 1.0;
    else if (input.rightShoulder)
        speedModifier *= speedModifyRate;
    else if (input.leftShoulder)
        speedModifier /= speedModifyRate;

    float moveX = input.leftStickX / stickMax;
    float moveZ = input.leftStickY / stickMax;
    float moveY = ((float)input.rightTrigger - (float)input.leftTrigger) / triggerMax;

    float vx = pCam->rx * moveX + pCam->ux * moveY + pCam->fx * moveZ;
    float vy = pCam->ry * moveX + pCam->uy * moveY + pCam->fy * moveZ;
    float vz = pCam->rz * moveX + pCam->uz * moveY + pCam->fz * moveZ;

    float speed = baseSpeed * speedModifier;
    if (input.b) speed *= 2.0;
    if (input.a) speed /= 2.0;

    pCam->x += vx * speed * dt;
    pCam->y += vy * speed * dt;
    pCam->z += vz * speed * dt;
}