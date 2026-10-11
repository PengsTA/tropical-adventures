local RegionDefs = require("tools/regiondefs")

AddSimPostInit(function()
    local original_update_funcs = setmetatable({}, { __mode = "k" })
    local noop = function() end
    local old_PostUpdate = GLOBAL.EmitterManager.PostUpdate

    local function IsLocalPlayerInterior()
        local player = GLOBAL.ThePlayer
        return player ~= nil and player:HasTag(RegionDefs.INTERIOR_TAG)
    end

    GLOBAL.EmitterManager.PostUpdate = function(self, ...)
        local suppress_precipitation = IsLocalPlayerInterior()
        for inst, data in pairs(self.awakeEmitters.infiniteLifetimes) do
            if inst.prefab == "pollen" or inst.prefab == "snow" or inst.prefab == "rain" then
                local original = original_update_funcs[inst]
                if original == nil then
                    original = data.updateFunc
                    original_update_funcs[inst] = original
                end
                data.updateFunc = suppress_precipitation and noop or original
            end
        end
        if old_PostUpdate ~= nil then
            return old_PostUpdate(self, ...)
        end
    end
end)
