local Utils = require("tools/utils")

local function IsSailingOrLoading(inst)
    local sailor = inst ~= nil and inst.components ~= nil and inst.components.sailor or nil
    return sailor ~= nil and (
        sailor:IsSailing()
        or (sailor.IsLoadingBoat ~= nil and sailor:IsLoadingBoat())
    )
end

local function DrownableShouldDrownBefore(self)
    if self.inst:HasTag("aquatic") or IsSailingOrLoading(self.inst) then
        return { false }, true
    end
end

local function IsLoadingOnBoat(player)
    if player == nil then
        return false
    end

    if player:HasTag("aquatic") and player:HasTag("sailor") then
        return true
    end

    local sailor = player.components ~= nil and player.components.sailor or nil
    if sailor ~= nil and (sailor:IsSailing() or (sailor.IsLoadingBoat ~= nil and sailor:IsLoadingBoat())) then
        return true
    end

    local replica_sailor = player.replica ~= nil and player.replica.sailor or nil
    return replica_sailor ~= nil and replica_sailor:GetBoat() ~= nil
end

AddComponentPostInit("drownable", function(self)
    Utils.FnDecorator(self, "ShouldDrown", DrownableShouldDrownBefore)
end)

AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim then
        local OldOnLoad = inst.OnLoad
        inst.OnLoad = function(inst, data, ...)
            if OldOnLoad ~= nil then
                OldOnLoad(inst, data, ...)
            end

            local has_saved_boat = data ~= nil and (
                data.ta_sailor_boat ~= nil
                or (data.sailor ~= nil and data.sailor.boat ~= nil)
            )
            local drownable = inst.components.drownable
            if drownable ~= nil and (has_saved_boat or IsLoadingOnBoat(inst)) then
                local was_enabled = drownable.enabled
                drownable.enabled = false
                -- Vanilla OnLoad queues a passability check that bypasses ShouldDrown.
                -- Same-tick callbacks have no ordering guarantee; restore on a later tick.
                inst:DoTaskInTime(2 * FRAMES, function()
                    if inst.components.drownable == drownable then
                        -- The constructor's deferred initialization may have run while disabled.
                        drownable.enabled = was_enabled == nil or was_enabled
                    end
                end)
            end
        end
    end
end)
