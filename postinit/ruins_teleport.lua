local RuinsTeleport = require("tools/ruins_teleport")
RuinsTeleport.Install(GLOBAL)

-- Wormholes and watch portals use teleporter directly rather than blink checks.
AddComponentPostInit("teleporter", function(self)
    local oldactivate = self.Activate
    self.Activate = function(self, doer, ...)
        if doer ~= nil then
            local x, y, z = doer.Transform:GetWorldPosition()
            if RuinsTeleport.IsMazePoint(TheWorld, x, y, z) then return false end
            local target = self.targetTeleporterTemporary or self.targetTeleporter
            if target ~= nil and (target.IsValid == nil or target:IsValid()) then
                local tx, ty, tz = target.Transform:GetWorldPosition()
                if tx ~= nil and RuinsTeleport.IsMazePoint(TheWorld, tx, ty, tz) then return false end
            end
        end
        return oldactivate(self, doer, ...)
    end
end)

local TELEPORT_WATCHES = { pocketwatch_warp = true, pocketwatch_recall = true, pocketwatch_portal = true }
local function CanUseWatch(inst, doer)
    if not TELEPORT_WATCHES[inst.prefab] or doer == nil then return true end
    local x, y, z = doer.Transform:GetWorldPosition()
    if RuinsTeleport.IsMazePoint(TheWorld, x, y, z) then return false end
    local mark = inst.components.recallmark
    if mark ~= nil and mark:IsMarkedForSameShard() then
        local tx, ty, tz = mark:GetMarkedPosition()
        if tx ~= nil and RuinsTeleport.IsMazePoint(TheWorld, tx, ty, tz) then return false end
    end
    return true
end

AddComponentPostInit("pocketwatch", function(self)
    local oldcan, oldcast = self.CanCast, self.CastSpell
    self.CanCast = function(self, doer, ...)
        return CanUseWatch(self.inst, doer) and oldcan(self, doer, ...)
    end
    self.CastSpell = function(self, doer, ...)
        if not CanUseWatch(self.inst, doer) then return false, "NO_TELEPORT_ZONE" end
        return oldcast(self, doer, ...)
    end
end)

-- Old positional history may contain maze points recorded before the restriction.
AddComponentPostInit("positionalwarp", function(self)
    local oldhistory = self.GetHistoryPosition
    self.GetHistoryPosition = function(self, rewind)
        local tx, ty, tz = oldhistory(self, false)
        if tx ~= nil then
            local x, y, z = self.inst.Transform:GetWorldPosition()
            if not RuinsTeleport.IsPermitted(TheWorld, x, y, z, tx, ty, tz) then return nil end
        end
        if rewind then return oldhistory(self, rewind) end
        return tx, ty, tz
    end
end)
