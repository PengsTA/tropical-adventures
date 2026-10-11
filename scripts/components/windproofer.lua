local Windproofer = Class(function(self, inst)
    self.inst = inst
    self.effectiveness = 0
end)

function Windproofer:SetEffectiveness(value)
    self.effectiveness = math.max(0, math.min(1, value))
end

function Windproofer:GetEffectiveness()
    return self.effectiveness
end

return Windproofer
