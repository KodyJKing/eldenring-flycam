local vector = reloadPackage("lua/vector")
local json = reloadPackage("lua/json")

local FlyCam = {}

local twoPi = math.pi * 2
local dt = 1000 / 120
local baseSpeed = 20 / 1000
local maxRotationSpeed = twoPi / 2000
local stickMax = 32768
local pitchLimit = math.pi / 2 * 7 / 8

function writeLookMatrix(address, angles, x, y, z)
    local c = math.cos(angles.yaw)
    local s = math.sin(angles.yaw)
    local h = math.cos(angles.pitch)
    local v = math.sin(angles.pitch)
    -- right x,y,z
    writeFloat(address + 0x00, s)
    -- writeFloat(address + 0x04, 0)
    writeFloat(address + 0x08, -c)
    -- up x,y,z
    writeFloat(address + 0x10, -c * v)
    writeFloat(address + 0x14, h)
    writeFloat(address + 0x18, -s * v)
    -- fwd x,y,z
    writeFloat(address + 0x20, c * h)
    writeFloat(address + 0x24, v)
    writeFloat(address + 0x28, s * h)
    -- pos x,y,z
    writeFloat(address + 0x30, x)
    writeFloat(address + 0x34, y)
    writeFloat(address + 0x38, z)
end

FlyCam.create = function()


    local cam = {}

    cam.speedModifier = 1

    local camAddr = readQword("chrCam")
    local fwd = vector.readVec(camAddr + 0x30)
    cam.angles = vector.vecToAngles(fwd)

    local sizeofMatrix = 4 * 15
    cam.matrix = allocateMemory(sizeofMatrix)
    for i = 0, 11 do writeFloat(cam.matrix + i * 4, 0) end
    -- writeFloat(cam.matrix + 15 * 4, 1)

    local timer = createTimer(nil)
    timer.Interval = dt
    local lastTick = getTickCount()
    timer.OnTimer = function()
        local input = getXBox360ControllerState()
        local tick = getTickCount()
        local dt = tick - lastTick
        lastTick = tick

        local rShoulder = input.GAMEPAD_RIGHT_SHOULDER
        local lShoulder = input.GAMEPAD_LEFT_SHOULDER
        if rShoulder and lShoulder then
            cam.speedModifier = 1
        elseif rShoulder then
            cam.speedModifier = cam.speedModifier * 2 ^ (dt / 1000)
        elseif lShoulder then
            cam.speedModifier = cam.speedModifier / 2 ^ (dt / 1000)
        end

        local speed = baseSpeed * cam.speedModifier

        local moveZ = input.ThumbLeftY / stickMax * speed * dt
        local moveX = input.ThumbLeftX / stickMax * speed * dt
        local moveY = 0
        if input.GAMEPAD_A then
            moveY = speed * dt
        elseif input.GAMEPAD_B then
            moveY = -speed * dt
        end

        local camAddr = readQword("chrCam")

        local x = readFloat(camAddr + 0x40)
        local y = readFloat(camAddr + 0x44)
        local z = readFloat(camAddr + 0x48)
        -- right
        local rx = readFloat(camAddr + 0x10)
        local ry = readFloat(camAddr + 0x14)
        local rz = readFloat(camAddr + 0x18)
        -- up
        local ux = readFloat(camAddr + 0x20)
        local uy = readFloat(camAddr + 0x24)
        local uz = readFloat(camAddr + 0x28)
        -- fwd
        local fx = readFloat(camAddr + 0x30)
        local fy = readFloat(camAddr + 0x34)
        local fz = readFloat(camAddr + 0x38)

        x = x + fx * moveZ + rx * moveX
        y = y + fy * moveZ + ry * moveX + moveY
        z = z + fz * moveZ + rz * moveX

        local lookX = -input.ThumbRightX / stickMax * maxRotationSpeed * dt
        local lookY = -input.ThumbRightY / stickMax * maxRotationSpeed * dt
        local nextYaw = (cam.angles.yaw + lookX) % twoPi
        local nextPitch = cam.angles.pitch + lookY
        if nextPitch > pitchLimit then
            nextPitch = pitchLimit
        elseif nextPitch < -pitchLimit then
            nextPitch = -pitchLimit
        end
        cam.angles.yaw = nextYaw
        cam.angles.pitch = nextPitch

        writeLookMatrix(cam.matrix, cam.angles, x, y, z)
        copyMemory(cam.matrix, sizeofMatrix, camAddr + 0x10)
    end

    cam.destroy = function()
        timer.destroy()
        deAlloc(cam.matrix)
    end

    return cam

end

return FlyCam
