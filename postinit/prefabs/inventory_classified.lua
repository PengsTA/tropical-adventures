local Utils = require "tools/utils"
AddPrefabPostInit("inventory_classified", function(inst)
    Utils.FnDecorator(inst, "GetOverflowContainer", nil, function(rets, inst)
        if inst.ignoreoverflow then
            return
        end
        if rets[1] ~= nil and rets[1]:IsFull() ~= true then
            return rets
        end
        local sailor = ThePlayer ~= nil and ThePlayer.replica ~= nil and ThePlayer.replica.sailor or nil
        local boat = sailor ~= nil and sailor:GetBoat() or nil
        return boat ~= nil and { boat.replica.container } or rets
    end)
end)
