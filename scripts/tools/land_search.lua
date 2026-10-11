local function IsSafe(map, x, z)
    return map:IsAboveGroundAtPoint(x, 0, z)
        and map:IsPassableAtPoint(x, 0, z)
        and not map:IsPointNearHole(Vector3(x, 0, z))
end

local function Find(map, scale, fallback)
    local width, height = map:GetSize()
    height = height or width
    width = math.max(0, math.floor(width * (scale or 1)))
    height = math.max(0, math.floor(height * (scale or 1)))
    for _ = 1, 128 do
        local x, z = math.random(-width, width), math.random(-height, height)
        if IsSafe(map, x, z) then
            return x, z
        end
    end
    if fallback ~= nil and IsSafe(map, fallback.x, fallback.z) then
        return fallback.x, fallback.z
    end
end

return { Find = Find }
