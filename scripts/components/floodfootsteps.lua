local STEP_PERIOD = .32

local FloodFootsteps = Class(function(self, inst)
    self.inst = inst
    self.task = inst:DoPeriodicTask(STEP_PERIOD, function()
        self:TrySpawnFootstep()
    end)
end)

function FloodFootsteps:IsMovingInFlood()
    if self.inst:HasTag("playerghost") or self.inst:HasTag("sailing")
        or self.inst:GetCurrentPlatform() ~= nil
        or self.inst.sg == nil or not self.inst.sg:HasStateTag("moving") then
        return false
    end

    local visuals = self.inst.components.floodwatervisuals
    if visuals == nil then
        return false
    end

    local x, _, z = self.inst.Transform:GetWorldPosition()
    return visuals:IsFloodedAtPoint(x, z)
end

function FloodFootsteps:TrySpawnFootstep()
    if not self:IsMovingInFlood() then
        return
    end

    local splash = SpawnPrefab("splash_footstep")
    if splash ~= nil then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        splash.Transform:SetPosition(x, y, z)
        splash.Transform:SetRotation(self.inst.Transform:GetRotation())
    end
end

function FloodFootsteps:OnRemoveFromEntity()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

return FloodFootsteps
