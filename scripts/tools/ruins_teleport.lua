local M = { TAG = "ta_ruins_maze" }

function M.IsMazePoint(world, x, y, z)
    if world == nil or world.Map == nil or world.topology == nil then return false end
    local index = world.Map:GetNodeIdAtPoint(x, y, z)
    local topology = world.topology
    local node = topology.nodes and topology.nodes[index]
    if node == nil then return false end
    for _, tag in ipairs(node.tags or {}) do
        if tag == M.TAG then return true end
    end
    -- Older worlds predate the tag but retain the generated room identifiers.
    local id = topology.ids and topology.ids[index] or node.id
    return type(id) == "string" and (id:find("TaHamRuinsMaze", 1, true) ~= nil
        or (id:find("HamArchiveMaze", 1, true) ~= nil and id:find("ArchiveMazeRooms", 1, true) ~= nil)) or false
end

function M.IsPermitted(world, fx, fy, fz, tx, ty, tz)
    return not M.IsMazePoint(world, fx, fy, fz) and not M.IsMazePoint(world, tx, ty, tz)
end

function M.Install(globals)
    local oldpoint = globals.IsTeleportingPermittedFromPointToPoint
    globals.IsTeleportingPermittedFromPointToPoint = function(fx, fy, fz, tx, ty, tz)
        return M.IsPermitted(globals.TheWorld, fx, fy, fz, tx, ty, tz)
            and oldpoint(fx, fy, fz, tx, ty, tz)
    end
    local oldlink = globals.IsTeleportLinkingPermittedFromPoint
    globals.IsTeleportLinkingPermittedFromPoint = function(x, y, z)
        return not M.IsMazePoint(globals.TheWorld, x, y, z) and oldlink(x, y, z)
    end
    -- Cross-shard destinations can only be classified by the receiving world.
    local oldmigration = globals.GetMigrationPortalLocation
    globals.GetMigrationPortalLocation = function(...)
        local x, y, z = oldmigration(...)
        if M.IsMazePoint(globals.TheWorld, x, y, z) then
            return globals.TheWorld.components.playerspawner:GetAnySpawnPoint()
        end
        return x, y, z
    end
end

return M
