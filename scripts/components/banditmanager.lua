--------------------------------------------------------------------------
--[[ Banditmanager class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)
    assert(TheWorld.ismastersim, "Banditmanager should not exist on client")

    local BANDIT_TIMER_NAME = "pig_bandit_respawn"
    local BANDIT_RESPAWN_TIME = TUNING.TOTAL_DAY_TIME * (math.random() + 0.1)

    -- Public
    self.inst = inst

    -- Private
    local _world = TheWorld
    local _map = _world.Map
    local _worldsettingstimer = _world.components.worldsettingstimer

    local _active_players = {}
    local _bandit



    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local function IsPlayerInCity(player)
        local x, y, z = player.Transform:GetWorldPosition()
        local tile = _map:GetTileAtPoint(x, 0, z)
        if IsCityTile(tile) then
            return true
        end

        return false
    end

    local function TrySpawnBanit()
        print("try to spawn a bandit!!!")

        if _world.state.isaporkalypse then
            return
        end

        local choices = {}
        for _, player in pairs(_active_players) do
            if not IsEntityDeadOrGhost(player) and IsPlayerInCity(player) then
                choices[#choices + 1] = player
            end
        end
        local player = GetRandomItem(choices)

        if not player then
            return
        end


        local value = player.components.inventory:HasMoney() or 0

        if _world.state.isdusk then
            value = value * 1.5
        end
        if _world.state.isnight then
            value = value * 3
        end

        local chance = 1 / 100
        if value >= 150 then
            chance = 1 / 4
        elseif value >= 100 then
            chance = 1 / 10
        elseif value >= 50 then
            chance = 1 / 20
        elseif value >= 10 then
            chance = 1 / 40
        elseif value == 0 then
            chance = 0
        end

        local roll = math.random()
        if roll < chance then
            self:SpawnBanditOnPlayer(player)
        end
    end

    local function StartRespawnTimer(time)
        _worldsettingstimer:StopTimer(BANDIT_TIMER_NAME)
        _worldsettingstimer:StartTimer(BANDIT_TIMER_NAME, time or BANDIT_RESPAWN_TIME, false)
    end

    local function OnBanditEscaped(src, data)
        if not (data and data.bandit and data.bandit:IsValid() and data.bandit == _bandit) then
            return
        end

        _bandit.components.health:SetPercent(1)
        _bandit.attacked = nil
        _bandit:Remove()
        _bandit = nil

        StartRespawnTimer()
    end

    local function OnBanditDeath(src, data)
        if not (data and data.bandit and data.bandit:IsValid() and data.bandit == _bandit) then
            return
        end
        StartRespawnTimer(BANDIT_RESPAWN_TIME)
        _bandit = nil
    end

    local function OnPlayerJoined(src, player)
        for _, v in ipairs(_active_players) do
            if v == player then
                return
            end
        end
        table.insert(_active_players, player)
    end

    local function OnPlayerLeft(src, player)
        for i, v in ipairs(_active_players) do
            if v == player then
                table.remove(_active_players, i)
                return
            end
        end
    end



    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------

    function self:SpawnBanditOnPlayer(player)
        --print("generate a bandit in world!!!")

        local x, y, z = player.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 40, { "bandit_cover" })

        local cover = GetRandomItem(ents)

        if cover then
            _bandit = SpawnPrefab("pigbandit")
            local cx, _, cz = cover.Transform:GetWorldPosition()
            local angle = TheCamera:GetHeadingTarget() * DEGREES
            cx = cx - 1 * math.cos(angle)
            cz = cz - 1 * math.sin(angle)
            _bandit.Transform:SetPosition(cx, 0, cz)
        end
    end

    function self:HasBandit()
        return _bandit ~= nil
    end

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------
    -- Initialize variables
    for i, v in ipairs(AllPlayers) do
        table.insert(_active_players, v)
    end

    -- Register events
    self.inst:ListenForEvent("bandit_death", OnBanditDeath)
    self.inst:ListenForEvent("bandit_escaped", OnBanditEscaped)
    self.inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
    self.inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)

    _worldsettingstimer:AddTimer(BANDIT_TIMER_NAME, BANDIT_RESPAWN_TIME, true, function()
        StartRespawnTimer()
        TrySpawnBanit()
    end)
    StartRespawnTimer()
end)
