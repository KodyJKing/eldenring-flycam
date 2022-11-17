local vector = reloadPackage("lua/vector")
local json = reloadPackage("lua/json")

local FlyCam = {}

local twoPi = math.pi * 2
local dt = 1000 / 120
local maxSpeed = 20 / 1000
local maxRotationSpeed = twoPi / 2000

local STICK_MAX = 32768
function getSpeedZ()
    local stickY = getXBox360ControllerState().ThumbLeftY
    return stickY / STICK_MAX * maxSpeed
end

function getSpeedX()
    local stickX = getXBox360ControllerState().ThumbLeftX
    return stickX / STICK_MAX * maxSpeed
end

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

    local camAddr = readQword("chrCam")

    local cam = {}

    local fwd = vector.readVec(camAddr + 0x30)
    cam.angles = vector.vecToAngles(fwd)

    local sizeofMatrix = 4 * 15
    cam.matrix = allocateMemory(sizeofMatrix)
    for i = 0, 11 do writeFloat(cam.matrix + i * 4, 0) end
    writeFloat(cam.matrix + 15 * 4, 1)

    local timer = createTimer(nil)
    timer.Interval = dt
    local lastTick = getTickCount()
    timer.OnTimer = function()
        local input = getXBox360ControllerState()
        local tick = getTickCount()
        local dt = tick - lastTick
        lastTick = tick

        local moveZ = input.ThumbLeftY / STICK_MAX * maxSpeed * dt
        local moveX = input.ThumbLeftX / STICK_MAX * maxSpeed * dt

        local x = readFloat(camAddr + 0x40)
        local y = readFloat(camAddr + 0x44)
        local z = readFloat(camAddr + 0x48)
        -- fwd
        local fx = readFloat(camAddr + 0x30)
        local fy = readFloat(camAddr + 0x34)
        local fz = readFloat(camAddr + 0x38)
        -- right
        local rx = readFloat(camAddr + 0x10)
        local ry = readFloat(camAddr + 0x14)
        local rz = readFloat(camAddr + 0x18)

        x = x + fx * moveZ + rx * moveX
        y = y + fy * moveZ + ry * moveX
        z = z + fz * moveZ + rz * moveX

        local lookX = -input.ThumbRightX / STICK_MAX * maxRotationSpeed * dt
        local lookY = -input.ThumbRightY / STICK_MAX * maxRotationSpeed * dt
        local nextYaw = (cam.angles.yaw + lookX) % twoPi
        local nextPitch = cam.angles.pitch + lookY
        if nextPitch > math.pi / 4 then
            nextPitch = math.pi / 4
        elseif nextPitch < -math.pi / 4 then
            nextPitch = -math.pi / 4
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
