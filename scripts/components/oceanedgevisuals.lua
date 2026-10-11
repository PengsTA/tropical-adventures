local OceanWrap = require("tools/ocean_wrap")

local OceanEdgeVisuals = Class(function(self, inst)
    self.inst = inst
    self.active = true
    self._activate = function() self.active = true; self:Refresh() end
    self._deactivate = function() self.active = false; self:Stop() end
    inst:ListenForEvent("playeractivated", self._activate)
    inst:ListenForEvent("playerdeactivated", self._deactivate)
    self:Refresh()
end)

function OceanEdgeVisuals:Update()
    local inst = self.inst
    local bounds = self.bounds
    local x, _, z = inst.Transform:GetWorldPosition()
    if self.active and bounds ~= nil and not inst:HasTag("playerghost")
        and not inst:HasTag("region_interior")
        and OceanWrap.Distance(bounds, x, z) >= 0
        and OceanWrap.Distance(bounds, x, z) <= OceanWrap.FOG_VIEW_TILES * TILE_SCALE then
        if self.fog == nil then self.fog = SpawnPrefab("edgefog") end
        if self.fog ~= nil then
            self.fog:SetBoundary(bounds, inst)
            if not TheWorld._ta_edgefog_started then
                TheWorld._ta_edgefog_started = true
                print("[Ocean] Edge fog started for local player")
            end
        end
    elseif self.fog ~= nil then
        self.fog:Remove()
        self.fog = nil
    end
end

function OceanEdgeVisuals:Refresh()
    if not TheNet:IsDedicated() and self.active and OceanWrap.IsEnabled(TheWorld) then
        local width, height = TheWorld.Map:GetSize()
        self.bounds = OceanWrap.GetBounds(width, height)
        if self.bounds == nil then return end
        if not TheWorld._ta_edgefog_logged then
            TheWorld._ta_edgefog_logged = true
            print(string.format("[Ocean] Local edge fog active: %d x %d", width, height))
        end
        if self.task == nil then
            self.task = self.inst:DoPeriodicTask(OceanWrap.CHECK_PERIOD, function() self:Update() end)
        end
        self:Update()
    else
        self:Stop()
    end
end

function OceanEdgeVisuals:Stop()
    if self.task ~= nil then self.task:Cancel(); self.task = nil end
    if self.fog ~= nil then self.fog:Remove(); self.fog = nil end
end

function OceanEdgeVisuals:OnRemoveFromEntity()
    self:Stop()
    self.inst:RemoveEventCallback("playeractivated", self._activate)
    self.inst:RemoveEventCallback("playerdeactivated", self._deactivate)
end
OceanEdgeVisuals.OnRemoveEntity = OceanEdgeVisuals.OnRemoveFromEntity

return OceanEdgeVisuals
