local ClimateProfiles = require("tools/climateprofiles")
local RegionDefs = require("tools/regiondefs")

local soundremap = {
    shipwrecked = {
        ["dontstarve/music/music_epicfight"] = "dontstarve_DLC002/music/music_epicfight_season_1",
        ["dontstarve/music/music_epicfight_winter"] = "dontstarve_DLC002/music/music_epicfight_season_2",
        ["dontstarve_DLC001/music/music_epicfight_spring"] = "dontstarve_DLC002/music/music_epicfight_season_3",
        ["dontstarve_DLC001/music/music_epicfight_summer"] = "dontstarve_DLC002/music/music_epicfight_season_4",
        ["dontstarve/music/music_work"] = "dontstarve_DLC002/music/music_work_season_1",
        ["dontstarve/music/music_work_winter"] = "dontstarve_DLC002/music/music_work_season_2",
        ["dontstarve_DLC001/music/music_work_spring"] = "dontstarve_DLC002/music/music_work_season_3",
        ["dontstarve_DLC001/music/music_work_summer"] = "dontstarve_DLC002/music/music_work_season_4",
        ["dontstarve/music/music_dawn_stinger"] = "dontstarve_DLC002/music/music_dawn_stinger",
        ["dontstarve/music/music_dusk_stinger"] = "dontstarve_DLC002/music/music_dusk_stinger",
        ["dontstarve/music/music_danger"] = "dontstarve_DLC002/music/music_danger_season_1",
        ["dontstarve/music/music_danger_winter"] = "dontstarve_DLC002/music/music_danger_season_2",
        ["dontstarve_DLC001/music/music_danger_spring"] = "dontstarve_DLC002/music/music_danger_season_3",
        ["dontstarve_DLC001/music/music_danger_summer"] = "dontstarve_DLC002/music/music_danger_season_4",
    },
    hamlet = {
        ["dontstarve/music/music_epicfight"] = "dontstarve_DLC003/music/fight_epic_1",
        ["dontstarve/music/music_epicfight_winter"] = "dontstarve_DLC003/music/fight_epic_1",
        ["dontstarve_DLC001/music/music_epicfight_spring"] = "dontstarve_DLC003/music/fight_epic_1",
        ["dontstarve_DLC001/music/music_epicfight_summer"] = "dontstarve_DLC003/music/fight_epic_1",
        ["dontstarve/music/music_work"] = "dontstarve_DLC003/music/working_1",
        ["dontstarve/music/music_work_winter"] = "dontstarve_DLC003/music/working_2",
        ["dontstarve_DLC001/music/music_work_spring"] = "dontstarve_DLC003/music/working_2",
        ["dontstarve_DLC001/music/music_work_summer"] = "dontstarve_DLC003/music/working_3",
        ["dontstarve/music/music_dawn_stinger"] = "dontstarve_DLC003/music/dawn_stinger_1_temperate",
        ["dontstarve/music/music_dusk_stinger"] = "dontstarve_DLC003/music/dusk_stinger_1_temperate",
        ["dontstarve/music/music_danger"] = "dontstarve_DLC003/music/fight_1",
        ["dontstarve/music/music_danger_winter"] = "dontstarve_DLC003/music/fight_2",
        ["dontstarve_DLC001/music/music_danger_spring"] = "dontstarve_DLC003/music/fight_2",
        ["dontstarve_DLC001/music/music_danger_summer"] = "dontstarve_DLC003/music/fight_3",
    },
}

local HAMLET_STINGERS = {
    temperate = {
        dawn = "dontstarve_DLC003/music/dawn_stinger_1_temperate",
        dusk = "dontstarve_DLC003/music/dusk_stinger_1_temperate",
    },
    humid = {
        dawn = "dontstarve_DLC003/music/dawn_stinger_2_humid",
        dusk = "dontstarve_DLC003/music/dusk_stinger_2_humid",
    },
    -- The DST rainy bridge has no separate Hamlet music variant.
    rainy = {
        dawn = "dontstarve_DLC003/music/dawn_stinger_2_humid",
        dusk = "dontstarve_DLC003/music/dusk_stinger_2_humid",
    },
    lush = {
        dawn = "dontstarve_DLC003/music/dawn_stinger_3_lush",
        dusk = "dontstarve_DLC003/music/dusk_stinger_3_lush",
    },
}

local HAMLET_TONES = {
    temperate = "dontstarve_DLC003/music/deeprainforest_enter_1",
    humid = "dontstarve_DLC003/music/deeprainforest_enter_2",
    rainy = "dontstarve_DLC003/music/deeprainforest_enter_2",
    lush = "dontstarve_DLC003/music/deeprainforest_enter_3",
}

local JUNGLE_TONE_DURATION = 75
local WORK_MUSIC_DURATION = 15
local BOAT_CHECK_INTERVAL = 0.5
local BOAT_MOVEMENT_DISTANCE_SQ = 0.2

-- Bind once, including nil-valued upvalues that recursive helpers cannot find.
local function BindState(fn, name)
    for index = 1, math.huge do
        local key = debug.getupvalue(fn, index)
        if key == nil then
            error("dynamicmusic is missing " .. name)
        elseif key == name then
            return {
                get = function() return select(2, debug.getupvalue(fn, index)) end,
                set = function(value) debug.setupvalue(fn, index, value) end,
            }
        end
    end
end

AddComponentPostInit("dynamicmusic", function(self, inst)
    if TheNet:IsDedicated() then
        return
    end

    -- Resolve everything before patching; an incompatible game update leaves
    -- vanilla music intact instead of partially replacing its event listeners.
    local ok, hooks = pcall(function()
        local activate = assert(inst:GetEventCallbacks("playeractivated", inst, "scripts/components/dynamicmusic.lua"))
        local enable = assert(inst:GetEventCallbacks("enabledynamicmusic", inst, "scripts/components/dynamicmusic.lua"))
        local listeners = assert(Upvaluehelper.GetUpvalue(activate, "StartPlayerListeners"))
        local startbusy = assert(Upvaluehelper.GetUpvalue(listeners, "StartBusy"))
        local stopbusy = assert(Upvaluehelper.GetUpvalue(enable, "StopBusy"))
        local startemitter = assert(Upvaluehelper.GetUpvalue(activate, "StartSoundEmitter"))
        return {
            startbusy = startbusy,
            workmusic = assert(Upvaluehelper.GetUpvalue(startbusy, "SEASON_BUSY_MUSIC")),
            stopbusy = stopbusy,
            starttheme = assert(Upvaluehelper.GetUpvalue(listeners, "StartBusyTheme")),
            themes = assert(Upvaluehelper.GetUpvalue(listeners, "BUSYTHEMES")),
            water = BindState(listeners, "StartTriggeredWater"),
            work = BindState(listeners, "StartBusy"),
            extendwork = BindState(listeners, "ExtendBusy"),
            stop = BindState(enable, "StopBusy"),
            season = BindState(startemitter, "OnSeason"),
            busytask = BindState(stopbusy, "_busytask"),
            busytheme = BindState(stopbusy, "_busytheme"),
            emitter = BindState(stopbusy, "_soundemitter"),
            extendtime = BindState(stopbusy, "_extendtime"),
            danger = BindState(startbusy, "_dangertask"),
            pirates = BindState(startbusy, "_pirates_near"),
            enabled = BindState(startbusy, "_isenabled"),
        }
    end)
    if not ok then
        print("[Tropical Adventures] Regional music disabled: " .. tostring(hooks))
        return
    end

    local player, profile, seasontag
    local updatetask, refreshtask
    local jungledeadline = 0
    local boat, boatx, boatz, boatmoving
    local boatdeadline = 0
    local workdeadline = 0
    local ownedthemes, soundthemes = {}, {}

    local function GetTheme(sound)
        local theme = soundthemes[sound]
        if theme == nil then
            local highest = 0
            for _, value in pairs(hooks.themes) do
                if type(value) == "number" then
                    highest = math.max(highest, value)
                end
            end
            theme = highest + 1
            hooks.themes["TA_" .. sound] = theme
            soundthemes[sound] = theme
            ownedthemes[theme] = true
        end
        return theme
    end

    local function IsOwnedTheme()
        return ownedthemes[hooks.busytheme.get()] == true
    end

    local function StopOwnedBusy()
        if IsOwnedTheme() then
            hooks.stopbusy()
            local emitter = hooks.emitter.get()
            if emitter ~= nil then
                emitter:KillSound("busy")
            end
            hooks.busytheme.set(nil)
        end
    end

    -- Vanilla StopBusy only lowers intensity. Entry tracks can retain audible
    -- tails, so release our channel completely on combat, stingers and timeout.
    hooks.stop.set(function(...)
        local owned = IsOwnedTheme()
        hooks.stopbusy(...)
        if owned and hooks.busytask.get() == nil then
            local emitter = hooks.emitter.get()
            if emitter ~= nil then
                emitter:KillSound("busy")
            end
            hooks.busytheme.set(nil)
        end
    end)

    local function IsRainforest(location)
        return location ~= nil and location.primary == "hamlet"
            and not location.isinterior and location.subregion == "ham_rainforest"
            and location.isdeeprainforest == true
    end

    local function GetBoat()
        if player == nil or profile == nil or profile.isinterior then
            return
        end
        local sailor = player.replica.sailor
        local solo = sailor ~= nil and sailor:GetBoat() or nil
        local vessel = solo or player:GetCurrentPlatform()
        if vessel ~= nil and vessel:IsValid() then
            return vessel, solo ~= nil
        end
    end

    local function GetSailingSound(solo)
        if solo then
            return TheWorld.state.isday
                and "dontstarve_DLC002/music/music_sailing_day"
                or "dontstarve_DLC002/music/music_sailing_night"
        elseif TheWorld.state.isday or inst:HasTag("cave") then
            return "turnoftides/music/sailing"
        end
    end

    local function GetDesiredMusic()
        local now = GetTime()
        if profile == nil then
            return
        end

        -- Resolve activity before environment. Occupying a boat also excludes
        -- land entry tones when its sailing window is silent or has expired.
        if now < workdeadline and (TheWorld.state.isday or inst:HasTag("cave")) then
            return "work"
        end
        local vessel, solo = GetBoat()
        if vessel ~= nil and now < boatdeadline then
            local sound = GetSailingSound(solo)
            if sound ~= nil then
                return "sailing", sound, boatdeadline - now
            end
        end
        if vessel ~= nil then
            return
        elseif profile.isinterior and profile.isshop then
            return "shop", "dontstarve_DLC003/music/shop_enter", 30
        elseif IsRainforest(profile) and now < jungledeadline then
            return "rainforest", HAMLET_TONES[ClimateProfiles.GetHamletProfile(TheWorld.state)]
                or HAMLET_TONES.temperate, jungledeadline - now
        end
    end

    local function IsWorkTheme()
        local theme, themes = hooks.busytheme.get(), hooks.themes
        return theme == themes.FOREST or theme == themes.CAVE
            or theme == themes.RUINS or theme == themes.LUNARISLAND
    end

    local function IsOrdinaryTheme(theme)
        local themes = hooks.themes
        return theme == nil or ownedthemes[theme]
            or theme == themes.FOREST or theme == themes.CAVE
            or theme == themes.RUINS or theme == themes.LUNARISLAND
            or theme == themes.OCEAN
    end

    local function UpdateMusic()
        if player == nil or not player:IsValid() then
            return
        end
        if player:HasTag("playerghost") or player:HasTag("dead")
            or not hooks.enabled.get() or hooks.emitter.get() == nil
            or hooks.danger.get() ~= nil or hooks.pirates.get() ~= nil then
            StopOwnedBusy()
            return
        end
        -- Preserve scripted events before resolving any lower-priority activity.
        if hooks.busytask.get() ~= nil and not IsOrdinaryTheme(hooks.busytheme.get()) then
            return
        end
        local activity, sound, duration = GetDesiredMusic()
        if activity == "work" then
            StopOwnedBusy()
            if hooks.busytask.get() == nil or not IsWorkTheme() then
                -- Keep vanilla's cave/lunar/seasonal selection and stinger gates.
                hooks.startbusy(player)
            end
            return
        elseif IsWorkTheme() and hooks.busytask.get() ~= nil and activity == nil then
            hooks.stopbusy()
        end
        local theme = sound ~= nil and GetTheme(sound) or nil
        if IsOwnedTheme() and hooks.busytheme.get() ~= theme then
            StopOwnedBusy()
        end
        if theme ~= nil and hooks.busytheme.get() == theme and hooks.busytask.get() ~= nil then
            if activity == "shop" then
                -- Keep the shop loop alive without replaying its entry every
                -- 30 seconds. StopBusy still cancels it immediately on combat.
                hooks.extendtime.set(GetTime() + 30)
            end
            return
        elseif theme == nil then
            return
        end
        -- Preserve vanilla's silence window after dawn/dusk/sanity stingers.
        local extendtime = hooks.extendtime.get()
        if hooks.busytask.get() == nil and extendtime ~= nil and GetTime() < extendtime then
            return
        end
        hooks.starttheme(player, theme, sound, duration)
    end

    local function QueueUpdate()
        if refreshtask == nil and player ~= nil then
            refreshtask = inst:DoTaskInTime(0, function()
                refreshtask = nil
                UpdateMusic()
            end)
        end
    end

    local function RemapMusic(primary)
        local remap = soundremap[primary]
        for sound in pairs(soundremap.shipwrecked) do
            RemapSound(sound, remap ~= nil and remap[sound] or nil)
        end
        if primary == "hamlet" then
            local stingers = HAMLET_STINGERS[ClimateProfiles.GetHamletProfile(TheWorld.state)]
                or HAMLET_STINGERS.temperate
            RemapSound("dontstarve/music/music_dawn_stinger", stingers.dawn)
            RemapSound("dontstarve/music/music_dusk_stinger", stingers.dusk)
        end
    end

    local function GetRegionalWorkSound(primary, season)
        local sound = hooks.workmusic[season]
        local remap = soundremap[primary]
        return remap ~= nil and remap[sound] or sound
    end

    local function OnRegionChanged(_, location)
        if player == nil then
            return
        end
        location = location or RegionDefs.GetRegionProfileFromTags(function(tag)
            return player:HasTag(tag)
        end)
        local season = TheWorld.state.season
        local primarychanged = profile == nil or profile.primary ~= location.primary
        if primarychanged or seasontag ~= season then
            -- Only FOREST work uses these remaps. Owned tracks are keyed by
            -- actual sound; UpdateMusic preserves them unless selection changes.
            if hooks.busytheme.get() == hooks.themes.FOREST
                and GetRegionalWorkSound(profile ~= nil and profile.primary or nil, seasontag)
                    ~= GetRegionalWorkSound(location.primary, season) then
                hooks.stopbusy()
                local emitter = hooks.emitter.get()
                if emitter ~= nil then
                    emitter:KillSound("busy")
                end
                hooks.busytheme.set(nil)
            end
            RemapMusic(location.primary)
            seasontag = season
        end
        if IsRainforest(location) and not IsRainforest(profile) then
            jungledeadline = GetTime() + JUNGLE_TONE_DURATION
        elseif not IsRainforest(location) then
            jungledeadline = 0
        end
        profile = location
        if profile.isinterior then
            boatdeadline = 0
        end
        UpdateMusic()
    end

    local function QueueRegionUpdate()
        if player ~= nil then
            if refreshtask ~= nil then
                refreshtask:Cancel()
            end
            refreshtask = inst:DoTaskInTime(0, function()
                refreshtask = nil
                OnRegionChanged()
            end)
        end
    end

    local oldseason = hooks.season.get()
    hooks.season.set(function(...)
        -- Preserve track identity through the dispatch. Regional work is
        -- compared by resolved sound, and owned tracks by UpdateMusic.
        if IsOrdinaryTheme(hooks.busytheme.get()) and not IsOwnedTheme() and not IsWorkTheme() then
            oldseason(...)
        end
        QueueRegionUpdate()
    end)

    local function SampleBoat()
        local vessel, solo = GetBoat()
        if vessel ~= boat then
            boat, boatx, boatz, boatmoving = vessel, nil, nil, false
            boatdeadline = 0
        end
        if vessel ~= nil then
            -- Solo boats are children of the player; platforms must use their
            -- own position so walking on an anchored deck is not sailing.
            local x, _, z = (solo and player or vessel).Transform:GetWorldPosition()
            local moving = boatx ~= nil
                and (x - boatx) ^ 2 + (z - boatz) ^ 2 >= BOAT_MOVEMENT_DISTANCE_SQ
            if moving and not boatmoving then
                boatdeadline = GetTime() + (solo and 75 or 30)
            end
            boatx, boatz, boatmoving = x, z, moving
        end
        UpdateMusic()
    end

    local function OnBoatMusic()
        local vessel, solo = GetBoat()
        if vessel ~= nil then
            boat = vessel
            boatdeadline = GetTime() + (solo and 75 or 30)
        end
        UpdateMusic()
    end
    hooks.water.set(OnBoatMusic)

    local function OnLeaveBoat()
        boat, boatx, boatz, boatmoving = nil, nil, nil, false
        boatdeadline = 0
        -- got_off_platform fires before vanilla clears its platform pointer.
        StopOwnedBusy()
        QueueUpdate()
    end

    local function OnPhase()
        if boatmoving then
            local vessel, solo = GetBoat()
            if vessel ~= nil then
                boatdeadline = GetTime() + (solo and 75 or 30)
            end
        end
        -- Vanilla's phase listener runs in the same dispatch; let it establish
        -- its stinger delay before attempting to resume regional music.
        QueueUpdate()
    end

    -- A work request is activity intent, not permission to extend whichever
    -- unrelated track currently owns the shared busy channel.
    hooks.work.set(function(worker, ...)
        if worker ~= player then
            return hooks.startbusy(worker, ...)
        elseif TheWorld.state.isday or inst:HasTag("cave") then
            workdeadline = GetTime() + WORK_MUSIC_DURATION
            if IsWorkTheme() and hooks.busytask.get() ~= nil then
                hooks.startbusy(worker, ...)
            end
            UpdateMusic()
        end
    end)

    local oldextendwork = hooks.extendwork.get()
    hooks.extendwork.set(function(...)
        if not IsOwnedTheme() then
            oldextendwork(...)
            if IsWorkTheme() and hooks.busytask.get() ~= nil then
                workdeadline = math.max(workdeadline, hooks.extendtime.get() or 0)
            end
        end
    end)

    local events = {
        regionchange_client = OnRegionChanged,
        boatdirty = SampleBoat,
        embarkboat = SampleBoat,
        disembarkboat = OnLeaveBoat,
        got_on_platform = SampleBoat,
        got_off_platform = OnLeaveBoat,
        stopboatmusic = OnLeaveBoat,
        death = QueueUpdate,
        ms_becameghost = QueueUpdate,
        respawnfromghost = QueueUpdate,
    }

    local function DetachPlayer()
        if player ~= nil then
            for event, fn in pairs(events) do
                inst:RemoveEventCallback(event, fn, player)
            end
        end
        if updatetask ~= nil then
            updatetask:Cancel()
            updatetask = nil
        end
        if refreshtask ~= nil then
            refreshtask:Cancel()
            refreshtask = nil
        end
        StopOwnedBusy()
        player, profile, seasontag = nil, nil, nil
        boat, boatx, boatz, boatmoving = nil, nil, nil, false
        jungledeadline, boatdeadline, workdeadline = 0, 0, 0
        RemapMusic(nil)
    end

    inst:ListenForEvent("playeractivated", function(_, activated)
        if activated == nil or activated == player then
            return
        end
        DetachPlayer()
        player = activated
        for event, fn in pairs(events) do
            inst:ListenForEvent(event, fn, player)
        end
        -- Wait until all activation listeners have initialized the emitter.
        refreshtask = inst:DoTaskInTime(0, function()
            refreshtask = nil
            OnRegionChanged()
            SampleBoat()
        end)
        updatetask = inst:DoPeriodicTask(BOAT_CHECK_INTERVAL, SampleBoat)
    end)
    inst:ListenForEvent("playerdeactivated", function(_, deactivated)
        if deactivated == player then
            DetachPlayer()
        end
    end)
    inst:ListenForEvent("enabledynamicmusic", QueueUpdate)
    inst:ListenForEvent("onremove", DetachPlayer)
    -- Vanilla does not watch seasons in caves, but regional remaps still do.
    inst:WatchWorldState("season", QueueRegionUpdate)
    inst:WatchWorldState("phase", OnPhase)
end)
