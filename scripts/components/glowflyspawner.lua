--------------------------------------------------------------------------
--[[ GlowflySpawner class definition ]]
--------------------------------------------------------------------------
local ClimateProfiles = require("tools/climateprofiles")

return Class(function(self, inst)
    assert(TheWorld.ismastersim, "GlowflySpawner should not exist on client")

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------

    --Public
    self.inst = inst

    --Private
    local _activeplayers = {}
    local _scheduledtasks = {}
    local _worldstate = TheWorld.state
    local _updating = false
    local _glowflies = {}
    local _maxglowflies = TUNING.MAX_BUTTERFLIES

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local FLOWER_TAGS = { "flower_rainforest", "flower" }
    local GLOWFLY_TAGS = { "glowfly" }

    local function GetSpawnPoint(player)
        local rad = 25
        local mindistance = 36
        local x, y, z = player.Transform:GetWorldPosition()
        local flowers = TheSim:FindEntities(x, y, z, rad, FLOWER_TAGS)

        local candidates = {}
        for _, flower in ipairs(flowers) do
            if flower:IsValid() and player:GetDistanceSqToInst(flower) > mindistance then
                candidates[#candidates + 1] = flower
            end
        end

        return #candidates > 0 and candidates[math.random(#candidates)] or nil
    end

    local function SpawnGlowflyForPlayer(player, reschedule)
        _scheduledtasks[player] = nil
        if not _updating or not player:IsValid() then return end
        local pt = player:GetPosition()
        if TheWorld.Map:IsPrimaryRegionAtPoint(pt.x, pt.y, pt.z, "hamlet")
            and #TheSim:FindEntities(pt.x, pt.y, pt.z, 64, GLOWFLY_TAGS) < _maxglowflies then
            local spawnflower = GetSpawnPoint(player)
            if spawnflower ~= nil then
                local glowfly = SpawnPrefab("glowfly")
                if glowfly ~= nil then
                    if glowfly.components.pollinator ~= nil then
                        glowfly.components.pollinator:Pollinate(spawnflower)
                    end
                    if glowfly.components.homeseeker ~= nil then
                        glowfly.components.homeseeker:SetHome(spawnflower)
                    end
                    glowfly.Physics:Teleport(spawnflower.Transform:GetWorldPosition())
                end
            end
        end
        reschedule(player)
    end

    local function ScheduleSpawn(player, initialspawn)
        if _updating and player:IsValid() and _scheduledtasks[player] == nil then
            local basedelay = initialspawn and 0.3 or 10
            _scheduledtasks[player] = player:DoTaskInTime(basedelay + math.random() * 10, SpawnGlowflyForPlayer,
                ScheduleSpawn)
        end
    end

    local function CancelSpawn(player)
        if _scheduledtasks[player] ~= nil then
            _scheduledtasks[player]:Cancel()
            _scheduledtasks[player] = nil
        end
    end

    local function ToggleUpdate(force)
        if not _worldstate.isnight
            and not ClimateProfiles.IsHamletHumid(_worldstate)
            and _maxglowflies > 0 then
            if not _updating then
                _updating = true
                for i, v in ipairs(_activeplayers) do
                    ScheduleSpawn(v, true)
                end
            elseif force then
                for i, v in ipairs(_activeplayers) do
                    CancelSpawn(v)
                    ScheduleSpawn(v, true)
                end
            end
        elseif _updating then
            _updating = false
            for i, v in ipairs(_activeplayers) do
                CancelSpawn(v)
            end
        end
    end

    local function AutoRemoveTarget(inst, target)
        if _glowflies[target] ~= nil and target:IsAsleep() then
            target:Remove()
        end
    end

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local function OnTargetSleep(target)
        inst:DoTaskInTime(0, AutoRemoveTarget, target)
    end

    local function OnPlayerJoined(src, player)
        for i, v in ipairs(_activeplayers) do
            if v == player then
                return
            end
        end
        table.insert(_activeplayers, player)
        if _updating then
            ScheduleSpawn(player, true)
        end
    end

    local function OnPlayerLeft(src, player)
        for i, v in ipairs(_activeplayers) do
            if v == player then
                CancelSpawn(player)
                table.remove(_activeplayers, i)
                return
            end
        end
    end

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    --Initialize variables
    for i, v in ipairs(AllPlayers) do
        table.insert(_activeplayers, v)
    end

    --Register events
    inst:WatchWorldState("isnight", ToggleUpdate)
    inst:WatchWorldState("season", ToggleUpdate)
    inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
    inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

    --------------------------------------------------------------------------
    --[[ Post initialization ]]
    --------------------------------------------------------------------------

    function self:OnPostInit()
        ToggleUpdate(true)
    end

    function self:OnRemoveFromEntity()
        _updating = false
        for player in pairs(_scheduledtasks) do CancelSpawn(player) end
        inst:StopWatchingWorldState("isnight", ToggleUpdate)
        inst:StopWatchingWorldState("season", ToggleUpdate)
        inst:RemoveEventCallback("ms_playerjoined", OnPlayerJoined, TheWorld)
        inst:RemoveEventCallback("ms_playerleft", OnPlayerLeft, TheWorld)
        for glowfly in pairs(_glowflies) do self:StopTracking(glowfly) end
    end

    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------

    function self.StartTrackingFn(target)
        if _glowflies[target] == nil then
            local restore = target.persists and 1 or 0
            target.persists = false
            if target.components.homeseeker == nil then
                target:AddComponent("homeseeker")
            else
                restore = restore + 2
            end
            _glowflies[target] = restore
            inst:ListenForEvent("entitysleep", OnTargetSleep, target)
        end
    end

    function self:StartTracking(target)
        self.StartTrackingFn(target)
    end

    function self.StopTrackingFn(target)
        local restore = _glowflies[target]
        if restore ~= nil then
            target.persists = restore == 1 or restore == 3
            if restore < 2 then
                target:RemoveComponent("homeseeker")
            end
            _glowflies[target] = nil
            inst:RemoveEventCallback("entitysleep", OnTargetSleep, target)
        end
    end

    function self:StopTracking(target)
        self.StopTrackingFn(target)
    end

    --------------------------------------------------------------------------
    --[[ Debug ]]
    --------------------------------------------------------------------------

    function self:GetDebugString()
        local numglowflies = 0
        for k, v in pairs(_glowflies) do
            numglowflies = numglowflies + 1
        end
        return string.format("updating:%s glowflies:%d/%d", tostring(_updating), numglowflies, _maxglowflies)
    end

    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
end)
