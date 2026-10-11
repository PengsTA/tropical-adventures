local BoatHealth = Class(function(self, inst)
    self.inst = inst
    self._maxhealth = net_ushortint(inst.GUID, "ta_boathealth._maxhealth")
    self._currenthealth = net_ushortint(inst.GUID, "ta_boathealth._currenthealth", "boathealthdirty")
end)

function BoatHealth:GetMaxHealth()
    return self.inst.components.boathealth ~= nil and self.inst.components.boathealth.maxhealth or self._maxhealth:value()
end

function BoatHealth:GetCurrentHealth()
    return self.inst.components.boathealth ~= nil and self.inst.components.boathealth.currenthealth or self._currenthealth:value()
end

function BoatHealth:GetPercent()
    local max = self:GetMaxHealth()
    return max > 0 and self:GetCurrentHealth() / max or 0
end

function BoatHealth:IsFull()
    return self:GetCurrentHealth() >= self:GetMaxHealth()
end

function BoatHealth:IsEmpty()
    return self:GetCurrentHealth() <= 0
end

return BoatHealth
