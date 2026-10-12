local json = require("json")

local ShardAporkalypse = Class(function(self, inst)
    assert(TheWorld.ismastersim, "shard_aporkalypse should not exist on client")
    self.inst = inst
    -- One snapshot keeps phase and fractional dates together during replication.
    self._state = net_string(inst.GUID, "shard_aporkalypse.state", "aporkalypsestatedirty")
    self._state:set_local("")
    self._onupdate = function() self:PublishMasterState() end
    self._ondirty = function() self:ApplyMasterState() end
    if TheWorld.ismastershard then
        inst:ListenForEvent("master_aporkalypseupdate", self._onupdate, TheWorld)
    else
        inst:ListenForEvent("aporkalypsestatedirty", self._ondirty)
    end
end)

function ShardAporkalypse:PublishMasterState()
    if not TheWorld.ismastershard then return end
    local aporkalypse = TheWorld.components.aporkalypse
    local state = aporkalypse ~= nil and aporkalypse:GetState() or {}
    state.enabled = aporkalypse ~= nil
    self._state:set(json.encode(state))
end

function ShardAporkalypse:ApplyMasterState()
    if TheWorld.ismastershard or self._state:value() == "" then return end
    local ok, state = pcall(json.decode, self._state:value())
    if not ok or type(state) ~= "table" or type(state.enabled) ~= "boolean" then return end
    local world = TheWorld
    TA_CONFIG.SetAporkalypseEnabled(state.enabled)
    if state.enabled then
        if world.components.aporkalypse == nil then
            world:AddComponent("aporkalypse")
            if KnownModIndex:IsModEnabled("workshop-2657513551") then
                world:AddComponent("dsa_aporkalypse_proxy")
            end
        end
        if not world.components.aporkalypse:ApplyMasterState(state) then return end
    elseif world.components.aporkalypse ~= nil then
        if world.components.dsa_aporkalypse_proxy ~= nil then world:RemoveComponent("dsa_aporkalypse_proxy") end
        world:RemoveComponent("aporkalypse")
        world:PushEvent("aporkalypsephasechanged", "calm")
    end
    if world.net ~= nil then
        world.net._ta_aporkalypse_enabled:set(state.enabled)
        if not state.enabled then world.net._aporkalypse_phase:set(2) end
    end
end

function ShardAporkalypse:OnPostInit()
    if TheWorld.ismastershard then
        self:PublishMasterState()
    else
        -- The initial snapshot can arrive before dirty listeners are registered.
        self:ApplyMasterState()
    end
end

function ShardAporkalypse:OnRemoveFromEntity()
    if TheWorld.ismastershard then
        self.inst:RemoveEventCallback("master_aporkalypseupdate", self._onupdate, TheWorld)
    else
        self.inst:RemoveEventCallback("aporkalypsestatedirty", self._ondirty)
    end
end

return ShardAporkalypse
