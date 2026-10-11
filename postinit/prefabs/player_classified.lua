local RegionDefs = require("tools/regiondefs")

local function OnRevealTreasureDirty(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil and TheCamera ~= nil then
        inst._parent.HUD.controls:ShowMap()
        local map = TheWorld.minimap.MiniMap
        local angle = TheCamera:GetHeading()
        local zoom = map:GetZoom()
        local player_x, _, player_z = inst._parent.Transform:GetWorldPosition()
        local target_x = math.modf(inst.revealtreasure:value() / 65536) - 16384 - player_x
        local target_z = inst.revealtreasure:value() % 65536 - 16384 - player_z
        local x = target_x * math.cos(math.rad(90 - angle)) - target_z * math.sin(math.rad(90 - angle))
        local z = target_x * math.sin(math.rad(90 - angle)) + target_z * math.cos(math.rad(90 - angle))
        map:ResetOffset()
        map:Offset(x / zoom, z / zoom)
    end
end

local function GetRegionProfile(inst)
    local owner = inst._parent
    return owner ~= nil and RegionDefs.GetRegionProfileFromTags(function(tag)
        return owner:HasTag(tag)
    end) or RegionDefs.GetRegionProfileFromTags(function()
        return false
    end)
end

local function QueueRegionChangeEvent(inst)
    if inst._parent ~= nil and inst._regionchangetask == nil then
        inst._regionchangetask = inst:DoTaskInTime(0, function()
            inst._regionchangetask = nil
            if inst._parent ~= nil then
                local profile = GetRegionProfile(inst)
                inst._parent:PushEvent("regionchange_client", profile)
            end
        end)
    end
end

local function QueueClimateEvent(inst, event, taskname)
    if inst._parent ~= nil and inst[taskname] == nil then
        inst[taskname] = inst:DoTaskInTime(0, function()
            inst[taskname] = nil
            if inst._parent ~= nil then
                inst._parent:PushEvent(event)
            end
        end)
    end
end

local function OnRegionalClimateDirty(inst)
    QueueClimateEvent(inst, "regionalclimatechanged_client", "_regionalclimatetask")
end

local function OnFoggroggylevelDirty(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("updatefoggroggy", {
            foggroggylevel = inst._tropical_foggroggylevel:value() / 100,
        })
    end
end

local function OnNextSneezeDirty(inst)
    if inst._parent ~= nil then
        local deadline = inst._tropical_nextsneeze:value() or -1
        local sneezetime = deadline >= 0 and math.max(0, deadline - GetTime()) or 999
        inst._parent:PushEvent("updatehayfever", { sneezetime = sneezetime })
    end
end

local function RegisterNetListeners(inst)
    inst._parent = inst.entity:GetParent()

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("revealtreasuredirty", OnRevealTreasureDirty)
        inst:ListenForEvent("regionawarerevisiondirty", QueueRegionChangeEvent)
        inst:ListenForEvent("regionalclimateprofiledirty", OnRegionalClimateDirty)
        inst:ListenForEvent("regionalclimatephasedirty", OnRegionalClimateDirty)
        inst:ListenForEvent("tropicalfoggroggyleveldirty", OnFoggroggylevelDirty)
        inst:ListenForEvent("tropicalnextsneezedirty", OnNextSneezeDirty)
        QueueRegionChangeEvent(inst)
    end
end

AddPrefabPostInit("player_classified", function(inst)
    inst._regionaware_revision = net_byte(inst.GUID, "regionaware.revision", "regionawarerevisiondirty")
    inst._regionalclimate_iswinterrain = net_bool(inst.GUID, "regionalclimate.iswinterrain", "regionalclimateiswinterraindirty")
    inst._regionalclimate_profile = net_smallbyte(inst.GUID, "regionalclimate.profile", "regionalclimateprofiledirty")
    inst._regionalclimate_phase = net_tinybyte(inst.GUID, "regionalclimate.phase", "regionalclimatephasedirty")
    inst._tropical_foggroggylevel = net_byte(inst.GUID, "tropical.foggroggylevel", "tropicalfoggroggyleveldirty")
    inst._tropical_nextsneeze = net_float(inst.GUID, "tropical.nextsneeze", "tropicalnextsneezedirty")
    inst.revealtreasure = net_uint(inst.GUID, "messagebottle_sw.reveal", "revealtreasuredirty")

    inst._regionaware_revision:set(0)
    inst._regionalclimate_iswinterrain:set(false)
    inst._regionalclimate_profile:set(1)
    inst._regionalclimate_phase:set(1)
    inst._tropical_foggroggylevel:set(0)
    inst._tropical_nextsneeze:set(-1)
    inst:DoTaskInTime(0, RegisterNetListeners)
end)
