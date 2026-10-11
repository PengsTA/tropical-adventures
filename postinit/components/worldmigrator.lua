local WorldMigrator = require "components/worldmigrator"
local Utils = require "tools/utils"

local function r_print(msg, ...)
    print(string.format(">> Torpical Reconnector(%s): ", tostring(TheShard:GetShardId())), string.format(msg, ...))
end

Utils.FnDecorator(WorldMigrator, "Activate", function(self, doer)
    if doer ~= nil and doer:HasTag("player") and doer.components.sailor ~= nil then
        doer.components.sailor:ForceDisembark("migration")
    end

    if GetModConfigData("dev_portal_reconnector") == false then
        return
    end
    if not self._isreconnect
        and self.id and tonumber(self.id)
        and tonumber(self.id) < 100
        and tonumber(self.id) ~= tonumber(self.receivedPortal) then -- ignore other mods portals, maybe
        self.receivedPortal = self.id
        -- self._shouldreconnect = true
    end
end --[[, function(rets, self, doer)
    if rets[1] == true and self._shouldreconnect == true then
        self._shouldreconnect = nil
        SendModRPCToShard(GetShardModRPC("Tropical adventures", "ForceMatchPortal"),
                          self.linkedWorld, doer.Network:GetNetworkID(), self.id, self.receivedPortal)
    end
    return rets
end]])

-- Utils.FnDecorator(WorldMigrator, "OnSave", nil, function(rets, self)
--     if self._isreconnect then
--         rets[1]._isreconnect = self._isreconnect
--     end
--     return rets
-- end)

-- Utils.FnDecorator(WorldMigrator, "OnLoad", nil, function(rets, self, data)
--     if data._isreconnect then
--         self._isreconnect = data._isreconnect
--     end
--     return rets
-- end)
