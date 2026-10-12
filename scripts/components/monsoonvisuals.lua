local RegionDefs = require("tools/regiondefs")

local SWIRLS_PER_SECOND = 16
local SPAWN_RADIUS = 16

local MonsoonVisuals = Class(function(self, inst)
    self.inst = inst
    self.active = true
    self.updating = false
    self.emission = 0
    self.effects = {}
    self._onstatechange = function()
        self:Refresh()
    end
    self._onactivate = function()
        self.active = true
        self:Refresh()
    end
    self._ondeactivate = function()
        self.active = false
        self:Stop()
    end

    inst:ListenForEvent("regionchange_client", self._onstatechange)
    inst:ListenForEvent("tropicalmonsoonwindchanged", self._onstatechange, TheWorld)
    inst:ListenForEvent("tropicalhurricanestatechanged", self._onstatechange, TheWorld)
    inst:ListenForEvent("playeractivated", self._onactivate)
    inst:ListenForEvent("playerdeactivated", self._ondeactivate)
    inst:DoTaskInTime(0, self._onstatechange)
end)

function MonsoonVisuals:IsActive()
    if not self.active or not TheWorld._ta_config_ready or not TUNING.wind or self.inst:HasTag("playerghost") then
        return false
    end

    local network = TheWorld ~= nil and TheWorld.net or nil
    -- The storm manager owns both hurricane storms and mild-season teasers.
    return RegionDefs.HasPrimaryRegion(self.inst, RegionDefs.PRIMARY.shipwrecked)
        and RegionDefs.HasSubregion(self.inst, RegionDefs.SUBREGION.sw_vanilla)
        and not self.inst:HasTag(RegionDefs.INTERIOR_TAG)
        and network ~= nil
        and network._tropical_hurricane_active ~= nil
        and network._tropical_hurricane_active:value()
        and network._tropical_hurricane_windactive ~= nil
        and network._tropical_hurricane_windactive:value()
        and network._tropical_monsoon_windstrength ~= nil
        and network._tropical_monsoon_windstrength:value() > 0
end

function MonsoonVisuals:OnUpdate(dt)
    if not self:IsActive() then
        self:Refresh()
        return
    end
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local network = TheWorld.net
    local wind_angle = network._tropical_monsoon_windangle:value() / 255 * 360
    local strength = network._tropical_monsoon_windstrength:value() / 100
    for wind in pairs(self.effects) do
        if wind:IsValid() then
            wind.AnimState:SetMultColour(1, 1, 1, strength)
        else
            self.effects[wind] = nil
        end
    end

    self.emission = self.emission + SWIRLS_PER_SECOND * math.min(dt, 1)
    while self.emission >= 1 do
        self.emission = self.emission - 1
        local wind = SpawnPrefab("monsoon_windfx")
        if wind ~= nil then
            wind.Transform:SetPosition(x + (math.random() * 2 - 1) * SPAWN_RADIUS,
                y, z + (math.random() * 2 - 1) * SPAWN_RADIUS)
            wind.Transform:SetRotation(wind_angle + 180)
            wind.AnimState:SetMultColour(1, 1, 1, strength)
            self.effects[wind] = true
        end
    end
end

function MonsoonVisuals:Refresh()
    if self:IsActive() then
        if not self.updating then
            self.updating = true
            self.emission = 1
            self.inst:StartUpdatingComponent(self)
        end
    else
        self:Stop()
    end
end

function MonsoonVisuals:Stop()
    if self.updating then
        self.inst:StopUpdatingComponent(self)
        self.updating = false
    end
    self.emission = 0
    for wind in pairs(self.effects) do
        if wind:IsValid() then
            wind:Remove()
        end
    end
    self.effects = {}
end

function MonsoonVisuals:OnRemoveFromEntity()
    self:Stop()
    self.inst:RemoveEventCallback("regionchange_client", self._onstatechange)
    self.inst:RemoveEventCallback("tropicalmonsoonwindchanged", self._onstatechange, TheWorld)
    self.inst:RemoveEventCallback("tropicalhurricanestatechanged", self._onstatechange, TheWorld)
    self.inst:RemoveEventCallback("playeractivated", self._onactivate)
    self.inst:RemoveEventCallback("playerdeactivated", self._ondeactivate)
end

MonsoonVisuals.OnRemoveEntity = MonsoonVisuals.OnRemoveFromEntity

return MonsoonVisuals
