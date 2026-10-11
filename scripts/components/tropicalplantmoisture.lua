local TropicalPlantMoisture = Class(function(self, inst)
    self.inst = inst
    self.moisture = 0
    self.wet = false
    self.task = inst:DoPeriodicTask(1, function()
        local state = TheWorld.state
        self:AddMoisture(state.israining and 0.5 * (state.precipitationrate or 1) or -1)
    end)
end)

function TropicalPlantMoisture:IsWet()
    return self.wet
end

function TropicalPlantMoisture:AddMoisture(delta)
    self.moisture = math.max(0, math.min(100, self.moisture + delta))
    local wet = self.moisture >= 20 or (self.wet and self.moisture > 10)
    if wet ~= self.wet then
        self.wet = wet
        self.inst:PushEvent(wet and "itemwet" or "itemdry")
    end
end

function TropicalPlantMoisture:OnSave()
    return { moisture = self.moisture, wet = self.wet }
end

function TropicalPlantMoisture:OnLoad(data)
    if data ~= nil then
        self.wet = data.wet == true
        self.moisture = tonumber(data.moisture) or 0
        self:AddMoisture(0)
    end
end

function TropicalPlantMoisture:OnRemoveFromEntity()
    self.task:Cancel()
end

return TropicalPlantMoisture
