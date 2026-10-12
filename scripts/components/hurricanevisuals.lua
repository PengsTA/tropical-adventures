local RegionDefs = require("tools/regiondefs")

local HURRICANE_SOUNDS = {}

local function AddSound(tile, sound)
    if tile ~= nil then
        HURRICANE_SOUNDS[tile] = sound
    end
end

AddSound(GROUND.JUNGLE, "dontstarve_DLC002/hurricane/jungleAMB")
AddSound(GROUND.BEACH, "dontstarve_DLC002/hurricane/beachAMB")
AddSound(GROUND.SWAMP, "dontstarve_DLC002/hurricane/marshAMB")
AddSound(GROUND.MAGMAFIELD, "dontstarve_DLC002/hurricane/rockyAMB")
AddSound(GROUND.TIDALMARSH, "dontstarve_DLC002/hurricane/marshAMB")
AddSound(GROUND.MEADOW, "dontstarve_DLC002/hurricane/grasslandAMB")
AddSound(GROUND.OCEAN_SHALLOW, "dontstarve_DLC002/hurricane/ocean_shallowAMB")
AddSound(GROUND.OCEAN_MEDIUM, "dontstarve_DLC002/hurricane/ocean_shallowAMB")
AddSound(GROUND.OCEAN_DEEP, "dontstarve_DLC002/hurricane/ocean_deepAMB")
AddSound(GROUND.OCEAN_SHIPGRAVEYARD, "dontstarve_DLC002/hurricane/ocean_deepAMB")
AddSound(GROUND.OCEAN_SHORE, "dontstarve_DLC002/hurricane/waves")
AddSound(GROUND.OCEAN_CORAL, "dontstarve_DLC002/hurricane/coral_reef")
AddSound(GROUND.MANGROVE, "dontstarve_DLC002/hurricane/mangrove")

local HurricaneVisuals = Class(function(self, inst)
    self.inst = inst
    self.hailfx = nil
    self.last_sound = nil
    self.task = nil
    self._onchange = function()
        self:Refresh()
    end
    self._onthunder = function()
        if self:IsActive() then
            self.inst.SoundEmitter:PlaySound("dontstarve/rain/thunder_far")
        end
    end

    inst:ListenForEvent("regionchange_client", self._onchange)
    inst:ListenForEvent("tropicalhurricanestatechanged", self._onchange, TheWorld)
    inst:ListenForEvent("tropicalhurricanethunder", self._onthunder, TheWorld)
    inst:DoTaskInTime(0, self._onchange)
end)

function HurricaneVisuals:GetNetwork()
    return TheWorld ~= nil and TheWorld.net or nil
end

function HurricaneVisuals:IsInHurricaneRegion()
    return RegionDefs.HasPrimaryRegion(self.inst, RegionDefs.PRIMARY.shipwrecked)
        and RegionDefs.HasSubregion(self.inst, RegionDefs.SUBREGION.sw_vanilla)
        and not self.inst:HasTag(RegionDefs.INTERIOR_TAG)
end

function HurricaneVisuals:IsActive()
    local network = self:GetNetwork()
    return TheWorld._ta_config_ready and self:IsInHurricaneRegion()
        and network ~= nil
        and network._tropical_hurricane_active ~= nil
        and network._tropical_hurricane_active:value()
end

function HurricaneVisuals:GetRates()
    local network = self:GetNetwork()
    if network == nil then
        return 0, 0
    end
    local storm_strength = network._tropical_hurricane_stormstrength ~= nil
        and network._tropical_hurricane_stormstrength:value() / 100 or 0
    local hail_rate = network._tropical_hurricane_hailrate ~= nil
        and network._tropical_hurricane_hailrate:value() / 100 or 0
    return storm_strength, hail_rate
end

function HurricaneVisuals:GetSound()
    local x, _, z = self.inst.Transform:GetWorldPosition()
    local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
    return HURRICANE_SOUNDS[tile] or "dontstarve_DLC002/hurricane/jungleAMB"
end

function HurricaneVisuals:StopSounds()
    self.last_sound = nil
    self.inst.SoundEmitter:KillSound("tropical_hurricane")
    self.inst.SoundEmitter:KillSound("tropical_hail")
end

function HurricaneVisuals:Update()
    if not self:IsActive() then
        self:Refresh()
        return
    end

    local storm_strength, hail_rate = self:GetRates()
    local sound = self:GetSound()
    if sound ~= self.last_sound then
        self.inst.SoundEmitter:KillSound("tropical_hurricane")
        self.inst.SoundEmitter:PlaySound(sound, "tropical_hurricane")
        self.last_sound = sound
    end
    self.inst.SoundEmitter:SetParameter("tropical_hurricane", "intensity", math.max(storm_strength, .15))

    if hail_rate > 0 and TUNING.hail then
        if self.hailfx == nil or not self.hailfx:IsValid() then
            self.hailfx = SpawnPrefab("hurricane_hailfx")
            if self.hailfx ~= nil then
                self.hailfx.entity:SetParent(self.inst.entity)
            end
        end
        if self.hailfx ~= nil then
            self.hailfx:SetRate(hail_rate)
        end
        if not self.inst.SoundEmitter:PlayingSound("tropical_hail") then
            self.inst.SoundEmitter:PlaySound("dontstarve_DLC002/rain/islandhailAMB", "tropical_hail")
        end
        self.inst.SoundEmitter:SetParameter("tropical_hail", "intensity", hail_rate)
    else
        if self.hailfx ~= nil then
            self.hailfx:Remove()
            self.hailfx = nil
        end
        self.inst.SoundEmitter:KillSound("tropical_hail")
    end
end

function HurricaneVisuals:Refresh()
    if self:IsActive() then
        if self.task == nil then
            self.task = self.inst:DoPeriodicTask(.5, function()
                self:Update()
            end)
        end
        self:Update()
    else
        if self.task ~= nil then
            self.task:Cancel()
            self.task = nil
        end
        if self.hailfx ~= nil then
            self.hailfx:Remove()
            self.hailfx = nil
        end
        self:StopSounds()
    end
end

function HurricaneVisuals:OnRemoveFromEntity()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
    if self.hailfx ~= nil then
        self.hailfx:Remove()
        self.hailfx = nil
    end
    self:StopSounds()
    self.inst:RemoveEventCallback("regionchange_client", self._onchange)
    self.inst:RemoveEventCallback("tropicalhurricanestatechanged", self._onchange, TheWorld)
    self.inst:RemoveEventCallback("tropicalhurricanethunder", self._onthunder, TheWorld)
end

return HurricaneVisuals
