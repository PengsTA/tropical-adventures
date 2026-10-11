local Teleporter = require "components/teleporter"
local Util = require "tools/utils"
local function RefreshVision(inst)
    inst = inst or ThePlayer
    if not inst then return end
    inst:DoTaskInTime(0, function()
        if inst.components.playervision ~= nil then
            inst.components.playervision:UpdateCCTable()
        end
    end)
end


AddClientModRPCHandler("tropical_adventures", "player.teleport", RefreshVision)

local old_IsActive = Teleporter.IsActive
function Teleporter:IsActive(...)
    if self.targetTeleporterTemporary ~= nil and self.targetTeleporterTemporary.IsValid ~= nil and not self.targetTeleporterTemporary:IsValid() then
        self.targetTeleporterTemporary = nil
    end
    if self.targetTeleporter ~= nil and self.targetTeleporter.IsValid ~= nil and not self.targetTeleporter:IsValid() then
        self.targetTeleporter = nil
    end
    return old_IsActive(self, ...)
end

local function DisembarkBeforeTeleport(self, obj)
    local targetDesination = self.targetTeleporterTemporary or self.targetTeleporter
    local targetTeleporter = self.targetTeleporterTemporary or (self.selfmanaged and self.inst) or self.targetTeleporter
    if targetTeleporter == nil or (not self.selfmanaged and targetTeleporter.IsValid ~= nil and not targetTeleporter:IsValid()) then
        return nil, true
    end
    if targetDesination == nil or (targetDesination.IsValid ~= nil and not targetDesination:IsValid()) then
        return nil, true
    end

    if obj ~= nil and obj:HasTag("player") and obj.components.sailor ~= nil then
        obj.components.sailor:ForceDisembark("teleport")
    end
end

Util.FnDecorator(Teleporter, "Teleport", DisembarkBeforeTeleport, function(rets, self, obj)
    if obj ~= nil and obj:HasTag("player") then
        RefreshVision(obj)
        SendModRPCToClient(GetClientModRPC("tropical_adventures", "player.teleport"), obj)
    end
    return rets
end)
