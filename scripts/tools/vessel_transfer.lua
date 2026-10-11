local VesselTransfer = {}

function VesselTransfer.GetRadius(entity)
    -- Only platform boat prefabs expose the safe hull radius method.
    return entity.GetSafePhysicsRadius ~= nil and entity:GetSafePhysicsRadius()
        or entity:GetPhysicsRadius(0)
end

function VesselTransfer.Resolve(entity)
    if entity == nil or not entity:IsValid() then return end
    local sailor = entity.components.sailor
    local boat = sailor ~= nil and sailor:GetBoat() or nil
    if boat ~= nil and boat:IsValid() then return entity, boat end
    if entity.components.sailable ~= nil then
        local rider = entity.components.sailable:GetSailor()
        if rider ~= nil and rider:IsValid() then return rider, entity end
        return entity, entity
    end
    boat = entity.GetCurrentPlatform ~= nil and entity:GetCurrentPlatform() or nil
    if boat ~= nil and boat:IsValid() and boat.components.walkableplatform ~= nil
        and (boat:HasTag("boat") or boat.components.boatphysics ~= nil) then
        return boat, boat
    end
    return entity, entity.components.walkableplatform ~= nil and entity or nil
end

function VesselTransfer.MoveEntity(entity, x, y, z)
    if entity.Physics ~= nil then
        entity.Physics:Teleport(x, y, z)
    else
        entity.Transform:SetPosition(x, y, z)
    end
end

function VesselTransfer.GetPassengers(actor, boat)
    local players = {}
    if boat ~= nil and boat.components.walkableplatform ~= nil then
        for player in pairs(boat.components.walkableplatform:GetPlayersOnPlatform()) do
            if player:IsValid() then players[player] = true end
        end
    elseif actor:HasTag("player") then
        players[actor] = true
    end
    return players
end

function VesselTransfer.Relocate(actor, boat, x, y, z)
    local platform = boat ~= nil and boat.components.walkableplatform or nil
    if platform ~= nil then
        -- Register freshly dropped cargo before the native followers move.
        platform:SetEntitiesOnPlatform()
    end
    VesselTransfer.MoveEntity(actor, x, y, z)
    if platform ~= nil and boat.boat_item_collision ~= nil then
        VesselTransfer.MoveEntity(boat.boat_item_collision, x, y, z)
    end
    if actor ~= boat and boat ~= nil then
        -- The occupied solo boat is a child: move its sailor only.
        local sailor = actor.components.sailor
        local tail = sailor:GetTail()
        if tail ~= nil then tail:PushEvent("oceanwrapped") end
        sailor:CacheBoatSaveRecord()
    end
end

return VesselTransfer
