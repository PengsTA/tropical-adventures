local RegionDefs = require("tools/regiondefs")

AddComponentPostInit("weather", function(self)
    --Private
    local _world = TheWorld
    local _map = _world.Map
    local _ismastersim = _world.ismastersim
    local _activatedplayer = nil

    --Precipiation
    local _rainsound = nil
    local _treerainsound = nil
    local _umbrellarainsound = nil
    local _barriersound = false

    local _rainfx
    local _snowfx
    for i, v in pairs(Ents) do
        if v.prefab then
            if v.prefab == "rain" then
                _rainfx = v
            elseif v.prefab == "snow" then
                _snowfx = v
            end
        end
    end


    local function StartAmbientRainSound(intensity)
        local sound = "dontstarve/AMB/rain"

        if _rainsound ~= sound then
            if _rainsound then
                _world.SoundEmitter:KillSound("rain")
            end
            _rainsound = sound
            _world.SoundEmitter:PlaySound(sound, "rain")
        end
        _world.SoundEmitter:SetParameter("rain", "intensity", intensity)
    end

    local function StopAmbientRainSound()
        if _rainsound then
            _rainsound = nil
            _world.SoundEmitter:KillSound("rain")
        end
    end

    local function StartTreeRainSound(intensity)
        local sound = "dontstarve_DLC001/common/rain_on_tree"

        if _treerainsound ~= sound then
            if _treerainsound then
                TheFocalPoint.SoundEmitter:KillSound("treerainsound")
            end
            _treerainsound = sound
            TheFocalPoint.SoundEmitter:PlaySound(sound, "treerainsound")
        end
        TheFocalPoint.SoundEmitter:SetParameter("treerainsound", "intensity", intensity)
    end

    local function StopTreeRainSound()
        if _treerainsound then
            _treerainsound = nil
            TheFocalPoint.SoundEmitter:KillSound("treerainsound")
        end
    end

    local function StartUmbrellaRainSound()
        local umbrella = _activatedplayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        local sound =
            umbrella and umbrella:HasTag("metal") and "meta4/winona_teleumbrella/rain_on_teleumbrella"
            or "dontstarve/rain/rain_on_umbrella"


        if _umbrellarainsound ~= sound then
            if _umbrellarainsound then
                TheFocalPoint.SoundEmitter:KillSound("umbrellarainsound")
            end
            _umbrellarainsound = sound
            TheFocalPoint.SoundEmitter:PlaySound(sound, "umbrellarainsound")
        end
    end

    local function StopUmbrellaRainSound()
        if _umbrellarainsound then
            _umbrellarainsound = nil
            TheFocalPoint.SoundEmitter:KillSound("umbrellarainsound")
        end
    end

    local function StartBarrierSound()
        if not _barriersound then
            _barriersound = true
            TheFocalPoint.SoundEmitter:PlaySound("meta2/voidcloth_umbrella/barrier_amb", "barriersound")
        end
    end

    local function StopBarrierSound()
        if _barriersound then
            _barriersound = false
            TheFocalPoint.SoundEmitter:KillSound("barriersound")
        end
    end

    local function GetLocalTropicalRainRate(player)
        if player == nil then
            return false, 0
        end

        if _ismastersim then
            local climate = player.components.regionalclimate
            if climate ~= nil and climate:IsTropical() then
                return true, climate:GetPrecipitationRate() or 0
            end
        end

        local is_shipwrecked = RegionDefs.HasPrimaryRegion(player, RegionDefs.PRIMARY.shipwrecked)
        local is_hamlet = RegionDefs.HasPrimaryRegion(player, RegionDefs.PRIMARY.hamlet)
        if not is_shipwrecked and not is_hamlet then
            return false, 0
        end

        -- Tropical interiors and Volcano do not inherit exterior precipitation.
        if player:HasTag(RegionDefs.INTERIOR_TAG) then
            return true, 0
        end

        if is_shipwrecked and not RegionDefs.HasSubregion(player, RegionDefs.SUBREGION.sw_vanilla) then
            return true, 0
        end

        local classified = player.player_classified
        local snow_as_rain = classified ~= nil
            and classified._regionalclimate_iswinterrain ~= nil
            and classified._regionalclimate_iswinterrain:value()
        return true, (_world.state.israining or snow_as_rain)
            and (_world.state.precipitationrate or 0) or 0
    end

    local function OnPlayerActivated(src, player)
        _activatedplayer = player
    end

    local function OnPlayerDeactivated(src, player)
        if _activatedplayer == player then
            _activatedplayer = nil
        end
    end

    local OnPlayerJoined = _ismastersim and function(src, player) end or nil
    local OnPlayerLeft = _ismastersim and function(src, player) end or nil

    --Register events
    self.inst:ListenForEvent("playeractivated", OnPlayerActivated, _world)
    self.inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated, _world)

    if _ismastersim then
        --Register master simulation events
        self.inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
        self.inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)
    end



    local OnUpdate_old = self.OnUpdate
    function self:OnUpdate(dt)
        OnUpdate_old(self, dt)

        -- if not _world.state.issnowing then return end

        local tropical, preciprate = GetLocalTropicalRainRate(_activatedplayer)
        if tropical then
            if _rainfx then
                _rainfx.particles_per_tick = 5 * preciprate
                _rainfx.splashes_per_tick = 2 * preciprate
            end

            if _snowfx then
                _snowfx.particles_per_tick = 0
            end

            local preciprate_sound = preciprate > 0 and preciprate or nil

            if preciprate_sound ~= nil then
                if _activatedplayer == nil then
                    StopTreeRainSound()
                    StopUmbrellaRainSound()
                    StopBarrierSound()
                elseif _activatedplayer.components.raindomewatcher ~= nil and _activatedplayer.components.raindomewatcher:IsUnderRainDome() then
                    StopTreeRainSound()
                    StopUmbrellaRainSound()
                    StartBarrierSound()
                    preciprate_sound = math.min(.1, preciprate_sound * .5)
                elseif _activatedplayer.replica.sheltered ~= nil and _activatedplayer.replica.sheltered:IsSheltered() then
                    StopUmbrellaRainSound()
                    StopBarrierSound()
                    StartTreeRainSound(preciprate_sound)
                    preciprate_sound = preciprate_sound - .4
                else
                    StopTreeRainSound()
                    StopBarrierSound()
                    if _activatedplayer.replica.inventory:EquipHasTag("umbrella") then
                        preciprate_sound = preciprate_sound - .4
                        StartUmbrellaRainSound()
                    else
                        StopUmbrellaRainSound()
                    end
                end
                if preciprate_sound > 0 then
                    StartAmbientRainSound(preciprate_sound)
                else
                    StopAmbientRainSound()
                end
            else
                StopAmbientRainSound()
                StopTreeRainSound()
                StopUmbrellaRainSound()
                StopBarrierSound()
            end
        else
            if not (_world.state.israining or _world.state.islunarhailing) then
                StopAmbientRainSound()
                StopTreeRainSound()
                StopUmbrellaRainSound()
            end
        end
    end

    self.LongUpdate = self.OnUpdate
end)
