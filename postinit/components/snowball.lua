------改这个似乎不起作用啊
local snowball = require("components/snowballmanager")
local _TryToCreateSnowballAtPoint = snowball.TryToCreateSnowballAtPoint

function snowball:TryToCreateSnowballAtPoint(x, y, z, skipsnowballtest)
    if not TheWorld.Map:IsDSTRegionAtPoint(x, y, z) then
        return false
    end
    return _TryToCreateSnowballAtPoint(self, x, y, z, skipsnowballtest)
end

AddPrefabPostInit("snowball_item", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:DoTaskInTime(0, function()
        if not inst:IsInPrimaryRegion("dst") or inst:IsOutsideWorld() then
            inst:Remove()
        end
    end)
end)
