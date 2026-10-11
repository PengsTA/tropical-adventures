local M = {}

function M.IsWaterPoint(map, point, excluded_tiles)
    return not map:IsAboveGroundAtPoint(point:Get())
        and excluded_tiles[map:GetTileAtPoint(point:Get())] == nil
        and not map:IsPassableAtPoint(point:Get())
end

function M.Retry(inst, fn)
    inst.spawn_attempts = inst.spawn_attempts - 1
    if inst.spawn_attempts > 0 then
        inst:DoTaskInTime(1, fn)
    else
        inst:Remove()
    end
end

return M
