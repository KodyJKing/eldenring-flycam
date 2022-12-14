local vector = {}

function vector.vector(x, y, z)
    return {
        x = x,
        y = y,
        z = z,
    }
end

function vector.readVec(address)
    return {
        x = readFloat(address + 0),
        y = readFloat(address + 4),
        z = readFloat(address + 8),
    }
end

function vector.writeVec(address, v)
    writeFloat(address + 0, v.x)
    writeFloat(address + 4, v.y)
    writeFloat(address + 8, v.z)
end

function vector.dist(a, b)
    return math.sqrt(
        (a.x - b.x) ^ 2 +
        (a.y - b.y) ^ 2 +
        (a.z - b.z) ^ 2
    )
end

function vector.dist2(a, b)
    return math.sqrt(
        (a.x - b.x) ^ 2 +
        (a.y - b.y) ^ 2
    )
end

function vector.addZ(v, z)
    return {
        x = v.x,
        y = v.y,
        z = v.z + z,
    }
end

function vector.add(a, b)
    return {
        x = a.x + b.x,
        y = a.y + b.y,
        z = a.z + b.z,
    }
end

function vector.sub(a, b)
    return {
        x = a.x - b.x,
        y = a.y - b.y,
        z = a.z - b.z,
    }
end

function vector.scale(a, b)
    return {
        x = a.x * b,
        y = a.y * b,
        z = a.z * b,
    }
end

function vector.cross(a, b)
    return {
        x = a.y * b.z - a.z * b.y,
        y = a.z * b.x - a.x * b.z,
        z = a.x * b.y - a.y * b.x,
    }
end

function vector.dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function vector.length(v)
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

function vector.unit(v)
    local invLength = 1 / vector.length(v)
    return {
        x = v.x * invLength,
        y = v.y * invLength,
        z = v.z * invLength,
    }
end

function vector.withLength(v, length)
    return vector.scale(vector.unit(v), length)
end

function vector.toString(v, digits)
    local format = "%." .. digits .. "f"
    local x = string.format(format, v.x)
    local y = string.format(format, v.y)
    local z = string.format(format, v.z)
    return x .. ", " .. y .. ", " .. z
end

function vector.anglesToVec(angles)
    local c = math.cos(angles.yaw)
    local s = math.sin(angles.yaw)
    local h = math.cos(angles.pitch)
    local v = math.sin(angles.pitch)
    return vector.vector(c * h, v, s * h)
end

function vector.vecToAngles(v)
    local h = math.sqrt(v.x * v.x + v.z * v.z)
    return {
        yaw = math.atan(v.z, v.x),
        pitch = math.atan(v.y, h),
    }
end

function vector.readAngles(address)
    return {
        yaw   = readFloat(address + 0),
        pitch = readFloat(address + 4),
    }
end

function vector.writeAngles(address, angles)
    writeFloat(address + 0, angles.yaw)
    writeFloat(address + 4, angles.pitch)
end

function vector.toDegrees(angles)
    return {
        yaw = angles.yaw * 180 / math.pi,
        pitch = angles.pitch * 180 / math.pi,
    }
end

local _up = vector.vector(0, 1, 0)
function vector.getLookMatrix(fwd)
    local right = vector.unit(vector.cross(_up, fwd))
    local up = vector.cross(fwd, right)
    return { right = right, up = up, fwd = fwd }
end

function vector.writeMatrix(address, mat)
    vector.writeVec(address + 0x00, mat.right)
    vector.writeVec(address + 0x10, mat.up)
    vector.writeVec(address + 0x20, mat.fwd)
end

return vector
