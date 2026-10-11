function IsSwLandTile(tile)
    return SW_LAND_TILES[tile] ~= nil
end

function IsHamLandTile(tile)
    return HAM_LAND_TILES[tile] ~= nil
end

function IsTroLandTile(tile)
    return TRO_LAND_TILES[tile] ~= nil
end

function IsTroWaterTile(tile)
    return TRO_OCEAN_TILES[tile] ~= nil
end

function IsCityTile(tile)
    return tile == WORLD_TILES.CHECKEREDLAWN or
        tile == WORLD_TILES.SUBURB or
        tile == WORLD_TILES.FOUNDATION or
        tile == WORLD_TILES.COBBLEROAD
end

function IsOnFlood(x, y, z)
    x, y, z = GetWorldPosition(x, y, z)
    local floodmanager = TheWorld.components.floodmanager
    return floodmanager ~= nil and floodmanager:IsFloodedAtPoint(x, z)
end

function IsOnOcean(x, y, z, onflood, ignoreboat)
    x, y, z = GetWorldPosition(x, y, z)
    local _map = TheWorld.Map

    return onflood and IsOnFlood(x, y, z) or _map:IsOceanAtPoint(x, y, z, ignoreboat)
end

function IsValidNodeTile(tile)
    return (IsLandTile(tile) or IsTroWaterTile(tile)) and true or false
end
