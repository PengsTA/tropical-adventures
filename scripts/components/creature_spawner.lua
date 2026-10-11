local Definitions = require("datadefs/creature_spawn_defs")
local CHECK_RADIUS = 60
local SCREEN_DISTANCE = 50
local MIN_DELAY, MAX_DELAY = 5, 10
local MAX_SPAWN_ATTEMPTS = 12
local BLOCKER_TAGS = { "tropicalspawnblocker" }
local PLAYER_TAGS = { "player" }
local IGNORE_TAGS = { "INLIMBO" }

return Class(function(self, inst)
    assert(TheWorld.ismastersim, "CreatureSpawner should not exist on client")
    self.inst = inst
    local tasks = {}
    local map = TheWorld.Map
    local removed = false

    local function SpawnForPlayer(player, reschedule)
        tasks[player] = nil
        if removed or not player:IsValid() then return end
        local info = self:GetSpawnPointInfo(player:GetPosition())
        if info ~= nil then self:SpawnSchool(info) end
        reschedule(player)
    end

    local function ScheduleSpawn(player)
        if not removed and player:IsValid() and tasks[player] == nil then
            tasks[player] = player:DoTaskInTime(GetRandomMinMax(MIN_DELAY, MAX_DELAY), SpawnForPlayer, ScheduleSpawn)
        end
    end

    local function OnPlayerJoined(_, player)
        ScheduleSpawn(player)
    end

    local function OnPlayerLeft(_, player)
        if tasks[player] ~= nil then
            tasks[player]:Cancel()
            tasks[player] = nil
        end
    end

    inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
    inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

    function self:OnPostInit()
        for _, player in ipairs(AllPlayers) do ScheduleSpawn(player) end
    end

    function self:OnRemoveFromEntity()
        removed = true
        for player in pairs(tasks) do OnPlayerLeft(nil, player) end
        inst:RemoveEventCallback("ms_playerjoined", OnPlayerJoined, TheWorld)
        inst:RemoveEventCallback("ms_playerleft", OnPlayerLeft, TheWorld)
    end

    function self:GetSpawnPointInfo(position)
        local info
        local offset = FindValidPositionByFan(math.random() * TWOPI, SCREEN_DISTANCE, 40, function(delta)
            local point = position + delta
            local tile = map:GetTileAtPoint(point:Get())
            local choices = Definitions.tiles[tile]
            local name = choices ~= nil and weighted_random_choice(choices) or nil
            local definition = name ~= nil and Definitions.creatures[name] or nil
            if definition ~= nil and map:GetPlatformAtPoint(point.x, point.z) == nil
                and #TheSim:FindEntities(point.x, point.y, point.z, CHECK_RADIUS, BLOCKER_TAGS) == 0
                and #TheSim:FindEntities(point.x, point.y, point.z, SCREEN_DISTANCE, PLAYER_TAGS) == 0 then
                info = { spawnpoint = point, tile = tile, schooldata = definition }
                return true
            end
            return false
        end)
        return offset ~= nil and info or nil
    end

    function self:SpawnSchool(info)
        local definition, point, tile = info.schooldata, info.spawnpoint, info.tile
        local tag = "spawned_" .. (definition.checkname or definition.prefab)
        local count = #TheSim:FindEntities(point.x, point.y, point.z, CHECK_RADIUS, { tag }, IGNORE_TAGS)
        if count >= definition.schoolmax or count > definition.schoolmin then return 0 end
        local missing = math.random(definition.schoolmin, definition.schoolmax) - count
        local spawned = 0
        -- Failed offsets and missing prefabs must also consume an attempt.
        for _ = 1, MAX_SPAWN_ATTEMPTS do
            if spawned >= missing then break end
            local radius = math.sqrt(math.random()) * definition.schoolrange
            local angle = math.random() * TWOPI
            local offset
            if IsLandTile(tile) then
                offset = FindWalkableOffset(point, angle, radius, 12)
            elseif IsOceanTile(tile) then
                offset = FindSwimmableOffset(point, angle, radius, 12)
            end
            if offset ~= nil then
                local creature = SpawnPrefab(definition.prefab)
                if creature == nil then break end
                creature:AddTag(tag)
                creature.Transform:SetPosition((point + offset):Get())
                spawned = spawned + 1
            end
        end
        if spawned > 0 then
            local blocker = SpawnPrefab("tropicalspawnblocker")
            if blocker ~= nil then blocker.Transform:SetPosition(point:Get()) end
        end
        return spawned
    end
end)
