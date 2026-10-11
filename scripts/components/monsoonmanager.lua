local RegionDefs = require("tools/regiondefs")
local WindProtection = require("tools/wind_protection")

local MIN_CALM_TIME = TUNING.WIND_GUSTDELAY_MIN or 15
local MAX_CALM_TIME = TUNING.WIND_GUSTDELAY_MAX or 16
local MIN_GUST_TIME = TUNING.WIND_GUSTLENGTH_MIN or 7
local MAX_GUST_TIME = TUNING.WIND_GUSTLENGTH_MAX or 10
local RAMP_UP_TIME = TUNING.WIND_GUSTRAMPUP_TIME or .5
local RAMP_DOWN_TIME = TUNING.WIND_GUSTRAMPDOWN_TIME or (32 / 30)
local MIN_PEAK_STRENGTH = TUNING.WIND_GUSTSPEED_PEAK_MIN or .9
local MAX_PEAK_STRENGTH = TUNING.WIND_GUSTSPEED_PEAK_MAX or 1

local PLAYER_WIND_SPEED = 2.25
local BOAT_WIND_SPEED = 1.75
local LOOSE_OBJECT_WIND_SPEED = 4
local EFFECT_RADIUS = 16
local UPDATE_PERIOD = .5

local PHASE_CALM = 0
local PHASE_RAMP_UP = 1
local PHASE_GUST = 2
local PHASE_RAMP_DOWN = 3

local function RandomRange(min, max)
    return min + math.random() * (max - min)
end

local function HasPhysics(inst)
    return inst ~= nil and inst:IsValid() and inst.Physics ~= nil
end

local function GetWorldTimeSeconds()
    local state = TheWorld.state
    return ((state.cycles or 0) + (state.time or 0)) * TUNING.TOTAL_DAY_TIME
end

local MonsoonManager = Class(function(self, inst)
    self.inst = inst
    self.phase = PHASE_CALM
    self.phase_time = 0
    self.phase_duration = RandomRange(MIN_CALM_TIME, MAX_CALM_TIME)
    self.angle = self:GetWindAngle()
    self.strength = 0
    self.peak_strength = 0
    self.affected = {}
    self._last_network_strength = nil
    self._last_network_angle = nil
    self.last_world_time = GetWorldTimeSeconds()

    -- DST's worldwind owns the global bearing. Monsoon only adds the
    -- Shipwrecked gust intensity and regional physical effects on top of it.
    self._onwindchange = function(_, data)
        self.angle = data ~= nil and data.angle or self:GetWindAngle()
        if self.strength > 0 then
            self:SyncNetworkState()
        end
    end
    inst:ListenForEvent("windchange", self._onwindchange)
    self._hurricane_wind_active = false
    self._onhurricanechange = function()
        local active = self:IsMonsoonActive()
        if active == self._hurricane_wind_active then
            return
        end
        self._hurricane_wind_active = active
        self.last_world_time = GetWorldTimeSeconds()
        self:ResetGustCycle()
        self:Update(0)
    end
    inst:ListenForEvent("tropicalhurricanestatechanged", self._onhurricanechange, TheWorld)

    self.task = inst:DoPeriodicTask(UPDATE_PERIOD, function()
        self:Update(UPDATE_PERIOD)
    end)
    self:SyncNetworkState()
end)

function MonsoonManager:IsMonsoonActive()
    local hurricane = TheWorld ~= nil and TheWorld.components.hurricanemanager or nil
    return TUNING.wind and hurricane ~= nil and hurricane:IsWindActive()
end

function MonsoonManager:GetWindAngle()
    local wind = TheWorld ~= nil and TheWorld.components.worldwind or nil
    return wind ~= nil and wind:GetWindAngle() or self.angle or 0
end

function MonsoonManager:SetPhase(phase, duration)
    self.phase = phase
    self.phase_time = 0
    self.phase_duration = duration
end

function MonsoonManager:ResetGustCycle()
    self.phase = PHASE_CALM
    self.phase_time = 0
    self.phase_duration = RandomRange(MIN_CALM_TIME, MAX_CALM_TIME)
    self.peak_strength = 0
end

function MonsoonManager:BeginGust()
    self.angle = self:GetWindAngle()
    self.peak_strength = RandomRange(MIN_PEAK_STRENGTH, MAX_PEAK_STRENGTH)
    self:SetPhase(PHASE_RAMP_UP, RAMP_UP_TIME)
end

function MonsoonManager:UpdateState(dt)
    while dt > 0 do
        local remaining = math.max(0, self.phase_duration - self.phase_time)
        if dt < remaining then
            self.phase_time = self.phase_time + dt
            return
        end

        dt = dt - remaining
        if self.phase == PHASE_CALM then
            self:BeginGust()
        elseif self.phase == PHASE_RAMP_UP then
            self:SetPhase(PHASE_GUST, RandomRange(MIN_GUST_TIME, MAX_GUST_TIME))
        elseif self.phase == PHASE_GUST then
            self:SetPhase(PHASE_RAMP_DOWN, RAMP_DOWN_TIME)
        else
            self:SetPhase(PHASE_CALM, RandomRange(MIN_CALM_TIME, MAX_CALM_TIME))
        end
    end
end

function MonsoonManager:UpdateStrength()
    if self.phase == PHASE_RAMP_UP then
        self.strength = self.peak_strength * math.min(1, self.phase_time / self.phase_duration)
    elseif self.phase == PHASE_GUST then
        self.strength = self.peak_strength
    elseif self.phase == PHASE_RAMP_DOWN then
        self.strength = self.peak_strength * math.max(0, 1 - self.phase_time / self.phase_duration)
    else
        self.strength = 0
    end
end

function MonsoonManager:SyncNetworkState()
    local net = TheWorld ~= nil and TheWorld.net or nil
    if net == nil or net._tropical_monsoon_windstrength == nil then
        return
    end

    local strength = math.floor(self.strength * 100 + .5)
    if strength == 0 then
        if self._last_network_strength ~= nil and self._last_network_strength ~= 0 then
            net._tropical_monsoon_windstrength:set(0)
        end
        self._last_network_strength = 0
        return
    end

    local angle = math.floor((self.angle % 360) / 360 * 255 + .5)
    if self._last_network_strength == strength and self._last_network_angle == angle then
        return
    end

    if self._last_network_strength ~= strength then
        net._tropical_monsoon_windstrength:set(strength)
        self._last_network_strength = strength
    end
    if self._last_network_angle ~= angle then
        net._tropical_monsoon_windangle:set(angle)
        self._last_network_angle = angle
    end
end

function MonsoonManager:RemoveWindFrom(inst)
    local physics = inst ~= nil and inst.components.physicsmodifiedexternally or nil
    if physics ~= nil then
        physics:RemoveSource(self.inst)
    end
end

function MonsoonManager:ClearAffected()
    for inst in pairs(self.affected) do
        if inst:IsValid() then
            self:RemoveWindFrom(inst)
        end
    end
    self.affected = {}
end

function MonsoonManager:ApplyWind(next_affected, inst, speed)
    if not HasPhysics(inst) then
        return
    end

    local physics = inst.components.physicsmodifiedexternally
    if physics == nil then
        inst:AddComponent("physicsmodifiedexternally")
        physics = inst.components.physicsmodifiedexternally
    end
    if physics == nil then
        return
    end

    local angle = self.angle * DEGREES
    physics:AddSource(self.inst)
    physics:SetVelocityForSource(self.inst, math.cos(angle) * speed, -math.sin(angle) * speed)
    next_affected[inst] = true
end

function MonsoonManager:GetPlayerWindSpeed(player)
    local inventory = player.components.inventory
    local protection = WindProtection.Get(inventory)
    return PLAYER_WIND_SPEED * self.strength * (1 - math.min(.8, protection or 0))
end

function MonsoonManager:GetStrength()
    return self.strength
end

function MonsoonManager:IsExposedShipwreckedPlayer(player)
    local aware = player.components.regionaware
    return player.components.health ~= nil
        and not player.components.health:IsDead()
        and aware ~= nil
        and aware:IsInSubregion(RegionDefs.SUBREGION.sw_vanilla)
        and not aware:IsInInterior()
end

function MonsoonManager:ReconcileWind()
    local next_affected = {}
    for _, player in ipairs(AllPlayers) do
        if self:IsExposedShipwreckedPlayer(player) then
            local boat = player.components.sailor ~= nil and player.components.sailor:GetBoat() or nil
            if boat ~= nil and boat:IsValid() then
                self:ApplyWind(next_affected, boat, BOAT_WIND_SPEED * self.strength)
            else
                self:ApplyWind(next_affected, player, self:GetPlayerWindSpeed(player))
            end

            local x, y, z = player.Transform:GetWorldPosition()
            local nearby = TheSim:FindEntities(x, y, z, EFFECT_RADIUS, nil,
                { "INLIMBO", "FX", "NOCLICK", "player", "structure", "wall", "boat", "platform" },
                { "_inventoryitem", "smallcreature" })
            for _, entity in ipairs(nearby) do
                if entity.components.inventoryitem == nil or entity.components.inventoryitem.owner == nil then
                    self:ApplyWind(next_affected, entity, LOOSE_OBJECT_WIND_SPEED * self.strength)
                end
            end
        end
    end

    for inst in pairs(self.affected) do
        if not next_affected[inst] and inst:IsValid() then
            self:RemoveWindFrom(inst)
        end
    end
    self.affected = next_affected
end

function MonsoonManager:Update(dt)
    local now = GetWorldTimeSeconds()
    local world_dt = now - self.last_world_time
    self.last_world_time = now

    if not self:IsMonsoonActive() then
        if self.strength > 0 or next(self.affected) ~= nil then
            self.strength = 0
            self:ClearAffected()
            self:SyncNetworkState()
        end
        if self.phase ~= PHASE_CALM or self.phase_time ~= 0 then
            self:ResetGustCycle()
        end
        return
    end

    if world_dt < 0 then
        self:ResetGustCycle()
        world_dt = 0
    end
    self:UpdateState(world_dt)
    self:UpdateStrength()
    if self.strength > 0 then
        self:ReconcileWind()
    elseif next(self.affected) ~= nil then
        self:ClearAffected()
    end
    self:SyncNetworkState()
end

function MonsoonManager:OnSave()
    return {
        phase = self.phase,
        phase_time = self.phase_time,
        phase_duration = self.phase_duration,
        angle = self.angle,
        peak_strength = self.peak_strength,
    }
end

function MonsoonManager:OnLoad(data)
    data = data or {}
    if data.phase ~= nil then
        self.phase = data.phase
    end
    if data.phase_time ~= nil then
        self.phase_time = math.max(0, data.phase_time)
    end
    if data.phase_duration ~= nil then
        self.phase_duration = math.max(.001, data.phase_duration)
    end
    if data.angle ~= nil then
        self.angle = data.angle
    end
    if data.peak_strength ~= nil then
        self.peak_strength = math.max(0, data.peak_strength)
    end

    -- World time is restored independently of component save data. Resetting
    -- this baseline avoids treating a load as one enormous gust simulation.
    self._hurricane_wind_active = self:IsMonsoonActive()
    self.last_world_time = GetWorldTimeSeconds()
    self:UpdateStrength()
    self:SyncNetworkState()
end

function MonsoonManager:OnRemoveFromEntity()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
    self.inst:RemoveEventCallback("windchange", self._onwindchange)
    self.inst:RemoveEventCallback("tropicalhurricanestatechanged", self._onhurricanechange, TheWorld)
    self.strength = 0
    self:ClearAffected()
    self:SyncNetworkState()
end

return MonsoonManager
