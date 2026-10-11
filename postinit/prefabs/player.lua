AddReplicableComponent("sailor")
AddReplicableComponent("boathealth")

local RegionDefs = require("tools/regiondefs")
local OceanWrap = require("tools/ocean_wrap")

local function IsLocalPlayerInShipwreckedExterior(inst)
    return RegionDefs.HasPrimaryRegion(inst, RegionDefs.PRIMARY.shipwrecked)
        and not inst:HasTag(RegionDefs.INTERIOR_TAG)
end

local function GetVolcanicAshRate()
    local network = TheWorld ~= nil and TheWorld.net or nil
    if network == nil then
        return 0
    end

    local active = network._tropical_volcano_active ~= nil and network._tropical_volcano_active:value()
    local eruption_rate = network._tropical_volcano_ashrate ~= nil and network._tropical_volcano_ashrate:value() or 0
    return math.max(eruption_rate, active and 6 or 1)
end

local function UpdateLocalVolcanicAsh(inst)
    local ash_rate = IsLocalPlayerInShipwreckedExterior(inst) and GetVolcanicAshRate() or 0
    local should_emit = ash_rate > 0
    local ash = inst._tropical_volcanicash
    if should_emit then
        if ash == nil or not ash:IsValid() then
            ash = SpawnPrefab("ashfx")
            if ash ~= nil then
                ash.entity:SetParent(inst.entity)
                inst._tropical_volcanicash = ash
            end
        end
        if ash ~= nil and ash.SetEmissionRate ~= nil then
            ash:SetEmissionRate(ash_rate)
        end
    elseif ash ~= nil then
        ash:Remove()
        inst._tropical_volcanicash = nil
    end
end

local function AttachLocalVolcanicAsh(inst)
    if inst ~= ThePlayer then
        return
    end

    local function RefreshAsh()
        UpdateLocalVolcanicAsh(inst)
    end

    inst:ListenForEvent("regionchange_client", RefreshAsh)
    inst:ListenForEvent("tropicalvolcanostatechanged", RefreshAsh, TheWorld)
    inst:ListenForEvent("onremove", function()
        if inst._tropical_volcanicash ~= nil then
            inst._tropical_volcanicash:Remove()
            inst._tropical_volcanicash = nil
        end
    end)
    inst:DoTaskInTime(0, RefreshAsh)
end

AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim then
        if not inst.components.regionaware then
            inst:AddComponent("regionaware")
        end
        if not inst.components.regionalclimate then
            inst:AddComponent("regionalclimate")
        end
        inst:AddComponent("sailor")
        if OceanWrap.IsEnabled(TheWorld) then inst:AddComponent("mapwrapper") end

        local OldOnLoad = inst.OnLoad
        inst.OnLoad = function(inst, data, ...)
            if OldOnLoad ~= nil then
                OldOnLoad(inst, data, ...)
            end

            local sailor = inst.components.sailor
            if sailor ~= nil
                and data ~= nil
                and data.ta_sailor_boat ~= nil
                and not sailor:IsSailing()
                and not sailor:IsLoadingBoat()
            then
                sailor:OnLoad({ boat = data.ta_sailor_boat })
            end
        end

        if TUNING.hamlet then
            if TUNING.hayfever then
                inst:AddComponent("hayfever")
            end

            if TUNING.fog then
                inst:AddComponent("foggroggy")
            end
        end
    end

    if not TheNet:IsDedicated() then
        -- The local player can be assigned after the first deferred postinit task.
        local function AttachLocalWeatherVisuals()
            if inst == ThePlayer then
                if inst.components.oceanedgevisuals == nil then
                    inst:AddComponent("oceanedgevisuals")
                end
                if inst.components.monsoonvisuals == nil then
                    inst:AddComponent("monsoonvisuals")
                end
                if inst.components.hurricanevisuals == nil then
                    inst:AddComponent("hurricanevisuals")
                end
            end
        end
        inst:ListenForEvent("playeractivated", AttachLocalWeatherVisuals)
        inst:DoStaticTaskInTime(0, function()
            AttachLocalWeatherVisuals()
            if inst == ThePlayer then -- only do this for the local player character
                inst:AddComponent("tilechangewatcher")
                inst:AddComponent("water_tilemanager")
                inst:AddComponent("floodwatervisuals")
                if TUNING.flood then
                    inst:AddComponent("floodfootsteps")
                end
                AttachLocalVolcanicAsh(inst)
            end
        end)
    end

    inst:AddComponent("infestable")
    inst:AddComponent("shopper")

    inst:ListenForEvent("onterraform", function(src, data)
        if CLIENT_MOD_RPC and CLIENT_MOD_RPC["Tropical adventures"] and CLIENT_MOD_RPC["Tropical adventures"]["tile_changed"] then
            SendModRPCToClient(GetClientModRPC("Tropical adventures", "tile_changed"), inst.userid, data.x, data.y,
                data.z, data.tile)
        end
    end, TheWorld)
end)
