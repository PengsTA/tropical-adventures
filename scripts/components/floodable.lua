local Floodable = Class(function(self, inst)
    self.inst = inst
    self.onStartFlooded = nil
    self.onStopFlooded = nil
    self.flooded = false
    self.floodEffect = nil
    self.floodSound = nil
    self.fxPeriod = 5
    self.fxtask = nil

    inst:AddTag("floodable")
    inst:DoTaskInTime(0, function()
        local manager = TheWorld.components.floodmanager
        if manager ~= nil then
            manager:RegisterFloodable(inst)
            self:Refresh()
        end
    end)
end)

function Floodable:SpawnEffect()
    if not self.flooded or self.floodEffect == nil then
        return
    end

    local fx = SpawnPrefab(self.floodEffect)
    if fx ~= nil then
        fx.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
    end
    if self.floodSound ~= nil and self.inst.SoundEmitter ~= nil then
        self.inst.SoundEmitter:PlaySound(self.floodSound)
    end
end

function Floodable:SetFlooded(flooded)
    if flooded == self.flooded then
        return
    end

    self.flooded = flooded
    if flooded then
        self.inst:AddTag("flooded")
        if self.onStartFlooded ~= nil then
            self.onStartFlooded(self.inst)
        end
        self:SpawnEffect()
        if self.floodEffect ~= nil then
            self.fxtask = self.inst:DoPeriodicTask(self.fxPeriod, function()
                self:SpawnEffect()
            end)
        end
    else
        self.inst:RemoveTag("flooded")
        if self.fxtask ~= nil then
            self.fxtask:Cancel()
            self.fxtask = nil
        end
        if self.onStopFlooded ~= nil then
            self.onStopFlooded(self.inst)
        end
    end
    self.inst:PushEvent("floodstatechanged", { flooded = flooded })
end

function Floodable:Refresh()
    if self.inst:GetIsFlooded() then
        self:SetFlooded(true)
    else
        self:SetFlooded(false)
    end
end

function Floodable:OnEntityWake()
    self:Refresh()
end

function Floodable:OnRemoveFromEntity()
    self:SetFlooded(false)
    local manager = TheWorld.components.floodmanager
    if manager ~= nil then
        manager:UnregisterFloodable(self.inst)
    end
    self.inst:RemoveTag("floodable")
end

return Floodable
