local birdvstile = {
    [WORLD_TILES.OCEAN_COASTAL] = { "puffin", "cormorant" },
    [WORLD_TILES.OCEAN_COASTAL_SHORE] = { "puffin", "cormorant" },
    [WORLD_TILES.OCEAN_SWELL] = { "puffin", "cormorant", "seagull" },
    [WORLD_TILES.OCEAN_ROUGH] = { "puffin", "seagull", "cormorant" },
    [WORLD_TILES.OCEAN_BRINEPOOL] = { "puffin", "seagull" },
    [WORLD_TILES.OCEAN_BRINEPOOL_SHORE] = { "puffin" },
    [WORLD_TILES.OCEAN_HAZARDOUS] = { "puffin", "seagull" },

    [WORLD_TILES.LILYPOND] = { "cormorant", "seagull" }, -------------------新添加----------------
    [WORLD_TILES.MANGROVE] = { "puffin", "seagull" },
    [WORLD_TILES.RAINFOREST] = { "toucan_hamlet", "kingfisher", "parrot_blue" },
    [WORLD_TILES.DEEPRAINFOREST] = { "toucan_hamlet", "parrot_blue", "kingfisher" },
    [WORLD_TILES.GASRAINFOREST] = { "parrot_blue" },
    [WORLD_TILES.FOUNDATION] = { "canary", "pigeon" },
    [WORLD_TILES.FIELDS] = { "crow", "pigeon" },
    [WORLD_TILES.SUBURB] = { "crow", "pigeon" },
    [WORLD_TILES.PAINTED] = { "kingfisher", "crow" },
    [WORLD_TILES.PLAINS] = { "toucan_hamlet", "kingfisher", "parrot_blue" },
    [WORLD_TILES.CHECKEREDLAWN] = { "canary", "pigeon" },
    [WORLD_TILES.COBBLEROAD] = { "canary", "pigeon" },
    [WORLD_TILES.TIDALMARSH] = { "toucan" },
    [WORLD_TILES.MAGMAFIELD] = { "toucan" },
    [WORLD_TILES.MEADOW] = { "parrot", "toucan" },
    [WORLD_TILES.BEACH] = { "toucan" },
    [WORLD_TILES.JUNGLE] = { "parrot" },
}

local SCARYTOPREY_TAGS = { "scarytoprey" }
local function IsDangerNearby(x, y, z)
    local ents = TheSim:FindEntities(x, y, z, 8, SCARYTOPREY_TAGS)
    return next(ents) ~= nil
end

local function PickTropicalBird(spawnpoint, tile)
    local x, y, z = spawnpoint:Get()
    tile = tile or TheWorld.Map:GetTileAtPoint(x, 0, z)
    local birds = birdvstile[tile]
    if birds == nil then
        return
    end

    local bird_prefab = type(birds) == "table" and GetRandomItem(birds) or birds
    if bird_prefab == "parrot" and math.random() < 0.1 then
        bird_prefab = "parrot_pirate"
    end

    if TheWorld.state.iswinter and not TheWorld.Map:IsTropicalRegionAtPoint(x, 0, z) and not IsOceanTile(tile) then
        return
    end

    return bird_prefab
end

local function RelevantSpawnBird(bird_prefab, spawnpoint, ignorebait)
    if not bird_prefab then
        return
    end

    local bird = SpawnPrefab(bird_prefab)

    if not bird then
        return
    end

    if math.random() < .5 then
        bird.Transform:SetRotation(180)
    end
    if bird:HasTag("bird") then
        spawnpoint.y = 15
    end

    if bird.components.eater and not ignorebait then
        local bait = TheSim:FindEntities(spawnpoint.x, 0, spawnpoint.z, 15)
        local _map = TheWorld.Map
        for k, v in pairs(bait) do
            local x, y, z = v.Transform:GetWorldPosition()

            -- if IsOnFlood(x, y, z) then -- birds can't spawn at flood
            --     break
            -- end

            if bird_prefab == "seagull" and v.components.pickable and v.components.pickable.product == "limpets" and v.components.pickable.canbepicked then
                local target_pos = Vector3(x, y, z)
                local angle = math.random(0, 360)
                local offset = FindWalkableOffset(target_pos, angle * DEGREES, math.random() + 0.5, 4, false, false)
                if offset ~= nil and bird_prefab == PickTropicalBird(target_pos + offset) then
                    spawnpoint = Vector3(target_pos.x, spawnpoint.y, target_pos.z) + offset
                    bird.bufferedaction = BufferedAction(bird, v, ACTIONS.PICK)
                end
                break
            elseif bird.components.eater:CanEat(v) and not v:IsInLimbo() and v.components.bait and
                not (v.components.inventoryitem and v.components.inventoryitem:IsHeld()) and not IsDangerNearby(x, y, z) and
                (bird.components.floater ~= nil or _map:IsPassableAtPoint(x, y, z)) then
                spawnpoint.x, spawnpoint.z = x, z
                bird.bufferedaction = BufferedAction(bird, v, ACTIONS.EAT)
                break
            elseif v.components.trap and v.components.trap.isset and
                (not v.components.trap.targettag or bird:HasTag(v.components.trap.targettag)) and
                not v.components.trap.issprung and math.random() < TUNING.BIRD_TRAP_CHANCE and
                not IsDangerNearby(x, y, z) and (bird.components.floater ~= nil or _map:IsPassableAtPoint(x, y, z)) then
                spawnpoint.x, spawnpoint.z = x, z
                break
            end
        end
    end

    bird.Physics:Teleport(spawnpoint:Get())

    return bird
end

AddComponentPostInit("birdspawner", function(self)
    local _SpawnBird = self.SpawnBird
    function self:SpawnBird(spawnpoint, ignorebait)
        -- if IsOnFlood(spawnpoint:Get()) then -- birds can't spawn at flood
        --     return
        -- end

        local x, y, z = spawnpoint:Get()
        local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)

        if birdvstile[tile] ~= nil then
            return RelevantSpawnBird(PickTropicalBird(spawnpoint, tile), spawnpoint, ignorebait)
        else
            if not TheWorld.Map:IsOutsideWorldAtPoint(x, 0, z) then
                return _SpawnBird(self, spawnpoint, ignorebait)
            end
        end
    end
end)
