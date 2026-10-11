local BoatEquip = require("tools/boat_equipment_helper")

local Rammer = Class(function(self, inst)
    self.inst = inst
    self.minSpeed = 2.0
    self.cooldown = 0.0
    self.checkRadius = 3
    self.hitRadius = 1

    self.wasActive = false

    self.ramFilters = {}
    self.onActivate = function() end
    self.onDeactivate = function() end
    self.onUpdate = function(dt) end
    self.onRamTarget = function(target) end

    if self.inst == nil then
        error("Rammer Component needs to be initialized with a valid Entity instance!")
    end

    self.inst:StartUpdatingComponent(self)
end)

function Rammer:StartCooldown()
    self.cooldown = 5 * FRAMES
end

function Rammer:CheckRamHit()
    if self.inst == nil or self.inst:IsValid() == false then
        return
    end

    if self.onRamTarget == nil then
        return
    end

    local pilot = self:FindPilot()

    if pilot == nil then
        return
    end

    local pilotVelocity = Vector3(pilot.Physics:GetVelocity())
    local pilotPosition = Vector3(pilot.Transform:GetWorldPosition())

    local function isInHitCone(item)
        local origin = pilotPosition
        local point = Vector3(item.Transform:GetWorldPosition())

        if pilot == nil or pilot.Physics == nil or item == nil or item.Physics == nil then
            return false
        end

        local maxDistance = self.hitRadius + pilot.Physics:GetRadius() + item.Physics:GetRadius()
        local offset = point - origin
        if offset:LengthSq() > (maxDistance * maxDistance) then
            return false
        end

        local direction = offset:GetNormalized()
        local velocity = pilotVelocity:GetNormalized()
        return velocity:Dot(direction) > 0.75
    end

    local yestags = {}
    local notags = { "falling", "FX", "NOCLICK", "DECOR", "INLIMBO", "unramable" }

    local ents = TheSim:FindEntities(pilotPosition.x, pilotPosition.y, pilotPosition.z, pilot.Physics:GetRadius() + self.hitRadius * 2, yestags,
        notags)

    for i = #ents, 1, -1 do
        local item = ents[i]
        local remove = false

        if item.components.health and item.components.health.currenthealth <= 0 then
            remove = true
        end

        if not remove and item:HasTag("shadow") and pilot.components.sanity and not pilot.components.sanity:IsCrazy() then
            remove = true
        end

        if remove then
            table.remove(ents, i)
        end
    end

    for k, v in pairs(ents) do
        if v ~= pilot then
            if isInHitCone(v) then
                self.onRamTarget(self.inst, v)
                if not self.inst:IsValid() or self.cooldown > 0 then return end
            end
        end
    end
end

function Rammer:OnUpdate(dt)
    local isActive = self:IsActive()

    if isActive == true and self.wasActive == false then
        self.onActivate()
    elseif isActive == false and self.wasActive == true then
        self.onDeactivate()
    end

    if isActive then
        self:CheckRamHit()
        if not self.inst:IsValid() then return end

        if self.onUpdate ~= nil then
            self.onUpdate(dt)
        end
    end
    --self:DebugRender()

    if self.cooldown > 0.0 then
        self.cooldown = self.cooldown - dt
    elseif self.cooldown < 0.0 then
        self.cooldown = 0.0
    end

    self.wasActive = isActive
end

function Rammer:FindPilot()
    if self.inst == nil or self.inst:IsValid() == false then
        return nil
    end
    return BoatEquip.GetItemSailor(self.inst)
end

function Rammer:IsActive()
    local pilot = self:FindPilot()

    if pilot == nil then
        return false
    end

    local v = Vector3(pilot.Physics:GetVelocity())
    local minSpeedSq = self.minSpeed * self.minSpeed

    return (v:LengthSq() >= minSpeedSq) and (self.cooldown <= 0.0)
end

function Rammer:DebugRender()
    if TheSim:GetDebugRenderEnabled() then
        if self.inst.draw then
            self.inst.draw:Flush()
            self.inst.draw:SetRenderLoop(true)
            self.inst.draw:SetZ(0.15)

            local dim = 2.0 * self.range
            local x, y, z = self.inst.Transform:GetWorldPosition()

            self.inst.draw:Box(x - self.range, z - self.range, dim, dim, 0, 1, 0, 1)
        else
            --TheSim:SetDebugRenderEnabled(true)
            self.inst.draw = self.inst.entity:AddDebugRender()
        end
    end
end

return Rammer
