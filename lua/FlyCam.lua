local vector = reloadPackage("lua/vector")

local FlyCam = {}

local dt = 5
local maxSpeed = 20 / 1000

local STICK_MAX = 32768
function getSpeedZ()
    local stickY = getXBox360ControllerState().ThumbLeftY
    return stickY / STICK_MAX * maxSpeed
end

function getSpeedX()
    local stickX = getXBox360ControllerState().ThumbLeftX
    return stickX / STICK_MAX * maxSpeed
end

FlyCam.create = function()

    local result = {}

    local timer = createTimer(nil)
    timer.Interval = dt
    timer.OnTimer = function()
        local camAddr = readQword("chrCam")

        local rightX = readFloat(camAddr + 0x10)
        local rightY = readFloat(camAddr + 0x14)
        local rightZ = readFloat(camAddr + 0x18)

        local fwdX = readFloat(camAddr + 0x30)
        local fwdY = readFloat(camAddr + 0x34)
        local fwdZ = readFloat(camAddr + 0x38)

        --print(fwdX, fwdY, fwdZ)

        local posX = readFloat(camAddr + 0x40)
        local posY = readFloat(camAddr + 0x44)
        local posZ = readFloat(camAddr + 0x48)

        local speedZ = getSpeedZ()
        local speedX = getSpeedX()
        writeFloat(camAddr + 0x40, posX + fwdX * speedZ * dt + rightX * speedX * dt)
        writeFloat(camAddr + 0x44, posY + fwdY * speedZ * dt + rightY * speedX * dt)
        writeFloat(camAddr + 0x48, posZ + fwdZ * speedZ * dt + rightZ * speedX * dt)
    end

    result.destroy = function()
        timer.destroy()
    end

    return result

end

return FlyCam
