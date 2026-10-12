local ERUPTION_SCHEDULE = require("datadefs/volcanoschedule")
local ClimateProfiles = require("tools/climateprofiles")
local RegionDefs = require("tools/regiondefs")

-- Absolute schedule positions are fixed; offerings apply one shared offset.
local ERUPTION_SEGMENTS = {}
local segment = 0
for index, eruption in ipairs(ERUPTION_SCHEDULE) do
    segment = segment + eruption.delay_segments
    ERUPTION_SEGMENTS[index] = segment
end

local WARNING_SCALES = {
    small = .35,
    medium = .6,
    large = 1,
}

-- The schedule is expressed in season segments. Keep a lightweight watchdog
-- while Dry Season is active so a task cancelled by a time/season adjustment
-- cannot silently leave the volcano dormant for the rest of the season.
local SCHEDULE_WATCH_PERIOD = math.max(1, TUNING.SEG_TIME * .5)
local SCHEDULE_EPSILON = .001

local function GetTaskTimeRemaining(task)
    return task ~= nil and task.GetTimeRemaining ~= nil and task:GetTimeRemaining() or nil
end

local function CancelTask(task)
    if task ~= nil then
        task:Cancel()
    end
end

local function GetCurrentSeasonSegment()
    local state = TheWorld.state
    local segments_per_day = TUNING.TOTAL_DAY_TIME / TUNING.SEG_TIME
    -- DST's elapsed-day counter can be left stale by c_setseason when the
    -- requested season is already active. The replicated season progress is
    -- what the base game's season manager actually uses for weather timing,
    -- and mirrors Shipwrecked's GetPercentSeason() clock.
    local season = state.season
    local length = season ~= nil and state[season .. "length"] or nil
    if length == nil or length <= 0 then
        length = state.totaldaysinseason or 0
    end

    local elapsed_days = ClimateProfiles.GetProgress(state) * length
    return (elapsed_days + (state.time or 0)) * segments_per_day
end

local VolcanoManager = Class(function(self, inst)
    self.inst = inst
    self.active = false
    self.erupting = false
    self.schedule_index = 1
    self.appeasement_segments = 0
    self.warningtasks = {}
    self.scheduled_warnings = {}
    self.eruptiontask = nil
    self.next_eruption_segment = nil
    self.schedule_watchtask = nil
    self.last_observed_segment = nil
    self.firerain_starttask = nil
    self.firerain_task = nil
    self.firerain_endtask = nil
    self.ash_effects = {}
    self.smoke_effects = {}
    self.eruption_records = {}
    self.eruption_end_segment = nil
    self.ash_update_task = nil
    self.firerain_per_sec = 0
    self.firerain_scheduled_rate = 0
    self.firerain_accumulator = 0
    self.firerain_target_index = 0
    self.loaded_data = nil

    inst:WatchWorldState("season", function()
        self:RefreshSeason()
    end)
    inst:ListenForEvent("seasontick", function()
        self:OnSeasonTick()
    end)
    inst:DoTaskInTime(0, function()
        self:RefreshSeason()
    end)
end)

function VolcanoManager:IsActive()
    return self.active
end

function VolcanoManager:IsErupting()
    return self.erupting
end

function VolcanoManager:IsFireRaining()
    return GetTaskTimeRemaining(self.firerain_endtask) ~= nil
end

function VolcanoManager:GetAshRate()
    local now = GetTime()
    local rate = 0
    for _, effect in ipairs(self.ash_effects) do
        if effect.started and effect.ends_at > now then
            rate = math.max(rate, 20 * math.min((effect.ends_at - now) / effect.duration, 1))
        end
    end
    return rate
end

function VolcanoManager:GetSmokeRate()
    local now = GetTime()
    local rate = 0
    for _, effect in ipairs(self.smoke_effects) do
        if effect.started and effect.ends_at > now then
            rate = math.max(rate, math.min((effect.ends_at - now) / effect.duration, 1))
        end
    end
    return rate
end

function VolcanoManager:SyncNetworkState()
    local network = self.inst.net
    if network ~= nil then
        if network._tropical_volcano_active ~= nil then
            network._tropical_volcano_active:set(self.active)
        end
        if network._tropical_volcano_erupting ~= nil then
            network._tropical_volcano_erupting:set(self.erupting)
        end
        if network._tropical_volcano_ashrate ~= nil then
            network._tropical_volcano_ashrate:set(math.floor(self:GetAshRate() + .5))
        end
        if network._tropical_volcano_smokerate ~= nil then
            network._tropical_volcano_smokerate:set(math.floor(self:GetSmokeRate() * 100 + .5))
        end
    end
end

function VolcanoManager:UpdateAshNetworkState()
    self:SyncNetworkState()
    if #self.ash_effects == 0 and self.ash_update_task ~= nil then
        self.ash_update_task:Cancel()
        self.ash_update_task = nil
    end
end

function VolcanoManager:EnsureAshNetworkTask()
    if self.ash_update_task == nil then
        self.ash_update_task = self.inst:DoPeriodicTask(1, function()
            self:UpdateAshNetworkState()
        end)
    end
end

function VolcanoManager:GetTimeUntilEruption()
    if self.next_eruption_segment ~= nil then
        return math.max(0, self.next_eruption_segment - GetCurrentSeasonSegment()) * TUNING.SEG_TIME
    end
    return nil
end

function VolcanoManager:GetScheduledEruptionSegment(index)
    if index == 0 then return self.appeasement_segments end
    local scheduled = ERUPTION_SEGMENTS[index]
    return scheduled ~= nil and scheduled + self.appeasement_segments or nil
end

function VolcanoManager:GetEruptionCycleDuration()
    local eruption = ERUPTION_SCHEDULE[self.schedule_index]
    return eruption ~= nil and eruption.delay_segments * TUNING.SEG_TIME or nil
end

function VolcanoManager:IsEligiblePlayer(player)
    local regionaware = player.components.regionaware
    return regionaware ~= nil
        and regionaware:IsInPrimaryRegion(RegionDefs.PRIMARY.shipwrecked)
        and not regionaware:IsInInterior()
end

function VolcanoManager:ForEachEligiblePlayer(fn)
    for _, player in ipairs(AllPlayers) do
        if player:IsValid() and self:IsEligiblePlayer(player) then
            fn(player)
        end
    end
end

function VolcanoManager:ShakePlayers(duration, scale)
    self:ForEachEligiblePlayer(function(player)
        ShakeAllCameras(CAMERASHAKE.FULL, duration, .02, scale, player, 40)
    end)
end

function VolcanoManager:ClearWarningTasks()
    for _, task in ipairs(self.warningtasks) do
        CancelTask(task)
    end
    self.warningtasks = {}
    self.scheduled_warnings = {}
end

function VolcanoManager:ClearScheduledEruption()
    self:ClearWarningTasks()
    CancelTask(self.eruptiontask)
    self.eruptiontask = nil
    self.next_eruption_segment = nil
end

function VolcanoManager:EnsureScheduleWatch()
    if self.schedule_watchtask == nil then
        self.schedule_watchtask = self.inst:DoPeriodicTask(SCHEDULE_WATCH_PERIOD, function()
            self:ReconcileSchedule()
        end)
    end
end

function VolcanoManager:StopScheduleWatch()
    CancelTask(self.schedule_watchtask)
    self.schedule_watchtask = nil
end

function VolcanoManager:ClearEffects()
    CancelTask(self.firerain_task)
    CancelTask(self.firerain_starttask)
    CancelTask(self.firerain_endtask)
    self.firerain_starttask = nil
    self.firerain_task = nil
    self.firerain_endtask = nil
    for _, effect in ipairs(self.ash_effects) do
        CancelTask(effect.starttask)
        CancelTask(effect.endtask)
    end
    for _, effect in ipairs(self.smoke_effects) do
        CancelTask(effect.starttask)
        CancelTask(effect.endtask)
    end
    for _, record in ipairs(self.eruption_records) do
        CancelTask(record.endtask)
    end
    self.ash_effects = {}
    self.smoke_effects = {}
    self.eruption_records = {}
    self.eruption_end_segment = nil
    CancelTask(self.ash_update_task)
    self.ash_update_task = nil
    self.firerain_per_sec = 0
    self.firerain_scheduled_rate = 0
    self.firerain_accumulator = 0
    self.firerain_target_index = 0
    self.erupting = false
    self:SyncNetworkState()
end

function VolcanoManager:Stop(push_event)
    local waserupting = self.erupting
    self:ClearScheduledEruption()
    self:StopScheduleWatch()
    self.last_observed_segment = nil
    self:ClearEffects()
    if push_event and waserupting then
        self.inst:PushEvent("volcanoeruptionend")
        self.inst:PushEvent("OnVolcanoEruptionEnd")
    end
end

function VolcanoManager:Warn(warning)
    if not self.active or self.erupting then
        return
    end

    local severity = warning.severity or "medium"
    self:ShakePlayers(.7, WARNING_SCALES[severity] or WARNING_SCALES.medium)
    self.inst:PushEvent("volcanowarning", {
        severity = severity,
        segments = warning.segments,
    })
    self.inst:PushEvent("OnVolcanoWarningQuake", {
        severity = severity,
        segments = warning.segments,
    })
end

function VolcanoManager:GetNextFireRainTarget()
    local players = {}
    self:ForEachEligiblePlayer(function(player)
        table.insert(players, player)
    end)
    if #players == 0 then
        return nil
    end

    self.firerain_target_index = self.firerain_target_index % #players + 1
    return players[self.firerain_target_index]
end

function VolcanoManager:SpawnFireRain()
    -- firerain_per_sec is a world-wide eruption budget. A target is selected
    -- round-robin so extra players redistribute hazards instead of multiplying
    -- the number of meteors produced by one eruption tick.
    local player = self:GetNextFireRainTarget()
    if player == nil then
        return
    end

    local x, y, z = player.Transform:GetWorldPosition()
    local function SpawnAt(target_x, target_z)
        if TheWorld.Map:IsInteriorAtPoint(target_x, 0, target_z) then
            return false
        end

        local prefab = math.random() <= (TUNING.VOLCANO_DRAGOONEGG_CHANCE or .25)
            and "dragoonegg_falling"
            or "firerain"
        local firerain = SpawnPrefab(prefab)
        if firerain == nil then
            return false
        end

        firerain.Transform:SetPosition(target_x, y, target_z)
        firerain:StartStep()
        return true
    end

    for _ = 1, 6 do
        local angle = math.random() * TWOPI
        local radius = math.sqrt(math.random()) * TUNING.VOLCANO_FIRERAIN_RADIUS
        local target_x = x + math.cos(angle) * radius
        local target_z = z + math.sin(angle) * radius
        if TheWorld.Map:IsPrimaryRegionAtPoint(target_x, 0, target_z, RegionDefs.PRIMARY.shipwrecked)
            and SpawnAt(target_x, target_z) then
            return
        end
    end

    -- Visual topology nodes can be absent over ocean and freshly stamped map
    -- terrain. The selected player is already confirmed as an exterior
    -- Shipwrecked target, so preserve the original local fire-rain behaviour
    -- instead of silently dropping an eruption tick.
    local angle = math.random() * TWOPI
    local radius = math.sqrt(math.random()) * TUNING.VOLCANO_FIRERAIN_RADIUS
    SpawnAt(x + math.cos(angle) * radius, z + math.sin(angle) * radius)
end

function VolcanoManager:OnFireRainTick()
    self.firerain_accumulator = self.firerain_accumulator + self.firerain_per_sec
    while self.firerain_accumulator >= 1 do
        self:SpawnFireRain()
        self.firerain_accumulator = self.firerain_accumulator - 1
    end
end

function VolcanoManager:StartFireRain(delay, duration, rate, accumulator, target_index)
    self.firerain_scheduled_rate = rate
    local function Begin()
        self.firerain_per_sec = self.firerain_scheduled_rate
        self.firerain_accumulator = math.max(0, accumulator or 0)
        self.firerain_target_index = target_index or 0
        self.firerain_task = self.inst:DoPeriodicTask(1, function()
            self:OnFireRainTick()
        end, 1)
    end

    if delay > 0 then
        self.firerain_starttask = self.inst:DoTaskInTime(delay, function()
            self.firerain_starttask = nil
            Begin()
        end)
    else
        Begin()
    end
    self.firerain_endtask = self.inst:DoTaskInTime(delay + duration, function()
        CancelTask(self.firerain_task)
        self.firerain_task = nil
        self.firerain_endtask = nil
        self.firerain_per_sec = 0
        self.firerain_scheduled_rate = 0
        self.firerain_accumulator = 0
        self.firerain_target_index = 0
        self.inst:PushEvent("OnVolcanoFireRainEnd")
    end)
end

function VolcanoManager:StartAshRain(delay, duration, remaining)
    local effect = { duration = duration, started = false }
    local active_duration = remaining or duration
    table.insert(self.ash_effects, effect)
    effect.starttask = self.inst:DoTaskInTime(delay, function()
        effect.starttask = nil
        effect.started = true
        effect.ends_at = GetTime() + active_duration
        self:EnsureAshNetworkTask()
        self:SyncNetworkState()
        self.inst:PushEvent("ashstart")
    end)
    effect.endtask = self.inst:DoTaskInTime(delay + active_duration, function()
        for index, other in ipairs(self.ash_effects) do
            if other == effect then
                table.remove(self.ash_effects, index)
                break
            end
        end
        self:UpdateAshNetworkState()
        if #self.ash_effects == 0 then
            self.inst:PushEvent("ashstop")
        end
    end)
end

function VolcanoManager:StartSmoke(delay, duration, remaining)
    local effect = { duration = duration, started = false }
    local active_duration = remaining or duration
    table.insert(self.smoke_effects, effect)
    effect.starttask = self.inst:DoTaskInTime(delay, function()
        effect.starttask = nil
        effect.started = true
        effect.ends_at = GetTime() + active_duration
        self:SyncNetworkState()
    end)
    effect.endtask = self.inst:DoTaskInTime(delay + active_duration, function()
        for index, other in ipairs(self.smoke_effects) do
            if other == effect then
                table.remove(self.smoke_effects, index)
                break
            end
        end
        self:SyncNetworkState()
    end)
end

function VolcanoManager:EndEruption(record)
    for index, other in ipairs(self.eruption_records) do
        if other == record then
            table.remove(self.eruption_records, index)
            break
        end
    end
    if #self.eruption_records == 0 and self.erupting then
        self.erupting = false
        self.eruption_end_segment = nil
        self:SyncNetworkState()
        self.inst:PushEvent("volcanoeruptionend")
        self.inst:PushEvent("OnVolcanoEruptionEnd")
    end
end

function VolcanoManager:StartEruption(eruption)
    if not self.active then
        return
    end

    self:ClearScheduledEruption()
    local waserupting = self.erupting
    self.erupting = true
    self:SyncNetworkState()

    local firerain_delay = eruption.firerain_delay_segments * TUNING.SEG_TIME
    local firerain_duration = eruption.firerain_segments * TUNING.SEG_TIME
    local ash_delay = eruption.ash_delay_segments * TUNING.SEG_TIME
    local ash_duration = eruption.ash_segments * TUNING.SEG_TIME
    local smoke_delay = eruption.smoke_delay_segments * TUNING.SEG_TIME
    local smoke_duration = eruption.smoke_segments * TUNING.SEG_TIME
    local eruption_duration = math.max(
        firerain_delay + firerain_duration,
        ash_delay + ash_duration,
        smoke_delay + smoke_duration
    )
    self.eruption_end_segment = GetCurrentSeasonSegment() + eruption_duration / TUNING.SEG_TIME

    self:ShakePlayers(2, 1.5)
    if not waserupting then
        self.inst:PushEvent("volcanoeruptionbegin")
        self.inst:PushEvent("OnVolcanoEruptionBegin")
    end
    self:StartFireRain(firerain_delay, firerain_duration, eruption.firerain_per_sec)
    self:StartAshRain(ash_delay, ash_duration)
    self:StartSmoke(smoke_delay, smoke_duration)
    local record = {}
    table.insert(self.eruption_records, record)
    record.endtask = self.inst:DoTaskInTime(eruption_duration, function()
        self:EndEruption(record)
    end)

    self.schedule_index = self.schedule_index + 1
    self:ScheduleNextEruption()
end

function VolcanoManager:ScheduleNextEruption()
    self:ClearScheduledEruption()
    if not self.active then
        return
    end

    local eruption = ERUPTION_SCHEDULE[self.schedule_index]
    local target_segment = self:GetScheduledEruptionSegment(self.schedule_index)
    if eruption == nil or target_segment == nil then
        self.inst:PushEvent("volcanoeruptionrescheduled", { time_remaining = nil })
        return
    end

    self.next_eruption_segment = target_segment
    local current_segment = GetCurrentSeasonSegment()
    local delay = math.max(0, target_segment - current_segment) * TUNING.SEG_TIME

    for _, warning in ipairs(eruption.warnings) do
        local warning_segment = target_segment - warning.segments
        local warning_delay = (warning_segment - current_segment) * TUNING.SEG_TIME
        if warning_delay > 0 then
            local scheduled = { warning = warning, segment = warning_segment, fired = false }
            table.insert(self.scheduled_warnings, scheduled)
            scheduled.task = self.inst:DoTaskInTime(warning_delay, function()
                scheduled.task = nil
                if not scheduled.fired and self.next_eruption_segment == target_segment then
                    scheduled.fired = true
                    self:Warn(warning)
                end
            end)
            table.insert(self.warningtasks, scheduled.task)
        end
    end

    if delay > 0 then
        self.eruptiontask = self.inst:DoTaskInTime(delay, function()
            if self.active and self.next_eruption_segment == target_segment then
                self:StartEruption(eruption)
            end
        end)
    end
    self.inst:PushEvent("volcanoeruptionrescheduled", { time_remaining = delay })
end

function VolcanoManager:ReconcileSchedule()
    if not self.active then
        return
    end

    local current_segment = GetCurrentSeasonSegment()
    if self.last_observed_segment ~= nil
        and current_segment + SCHEDULE_EPSILON < self.last_observed_segment then
        -- Rewinding a day or setting the season directly does not necessarily
        -- emit a new season event. Rebuild from the new season position rather
        -- than leaving a future schedule index from the old clock.
        self.schedule_index = 1
        self:ClearScheduledEruption()
    end
    self.last_observed_segment = current_segment

    if self.erupting then
        return
    end

    while self.schedule_index <= #ERUPTION_SCHEDULE do
        local target_segment = self:GetScheduledEruptionSegment(self.schedule_index)
        if target_segment == nil then
            return
        end

        if current_segment + SCHEDULE_EPSILON < target_segment then
            -- Do not replace a valid timer every day. Recreating it at a
            -- season tick can race its due callback and was able to skip the
            -- eruption entirely on a busy host.
            if self.eruptiontask == nil or self.next_eruption_segment ~= target_segment then
                self:ScheduleNextEruption()
            end
            return
        end

        local missed_segments = current_segment - target_segment
        local eruption = ERUPTION_SCHEDULE[self.schedule_index]
        self:ClearScheduledEruption()
        if missed_segments < 1 + SCHEDULE_EPSILON then
            self:StartEruption(eruption)
            return
        end

        -- A time or season jump has already passed this eruption and all of
        -- its weather phases. Do not replay an expired disaster at the new date.
        self.schedule_index = self.schedule_index + 1
    end
end

function VolcanoManager:OnSeasonTick()
    if not ClimateProfiles.IsShipwreckedDry(TheWorld.state) then
        return
    end

    if not self.active then
        self:RefreshSeason()
    end
    if self.erupting and self.eruption_end_segment ~= nil
        and GetCurrentSeasonSegment() >= self.eruption_end_segment then
        self:ClearEffects()
        self.inst:PushEvent("volcanoeruptionend")
        self.inst:PushEvent("OnVolcanoEruptionEnd")
    end
    self:ReconcileSchedule()
end

function VolcanoManager:Appease(segments)
    if not self.active or self:IsFireRaining() or segments == nil or segments == 0 then
        return false
    end

    local target_segment = self:GetScheduledEruptionSegment(self.schedule_index)
    if target_segment == nil then
        return false
    end

    self.appeasement_segments = self.appeasement_segments + segments
    if segments < 0 and target_segment + segments <= GetCurrentSeasonSegment() then
        self:StartEruption(ERUPTION_SCHEDULE[self.schedule_index])
    else
        -- Offerings only move the next timer; no calendar catch-up is needed.
        self:ScheduleNextEruption()
    end
    self.inst:PushEvent("volcanoappeased", {
        segments = segments,
        time_remaining = self:GetTimeUntilEruption() or 0,
    })
    return true
end

function VolcanoManager:RefreshSeason()
    local should_be_active = TUNING.volcano and ClimateProfiles.IsShipwreckedDry(TheWorld.state) or false
    if should_be_active == self.active then
        if should_be_active then
            self:EnsureScheduleWatch()
            if not self.erupting and (self.eruptiontask == nil or self.next_eruption_segment == nil) then
                self:ReconcileSchedule()
            end
        elseif not should_be_active then
            self.loaded_data = nil
        end
        return
    end

    self.active = should_be_active
    if not self.active then
        self:Stop(true)
        self.schedule_index = 1
        self.appeasement_segments = 0
        self.loaded_data = nil
        self:SyncNetworkState()
        self.inst:PushEvent("volcanoactivechanged", { active = false })
        return
    end

    self:SyncNetworkState()
    self.inst:PushEvent("volcanoactivechanged", { active = true })
    self.last_observed_segment = nil
    self:EnsureScheduleWatch()
    local data = self.loaded_data
    self.loaded_data = nil
    self.schedule_index = data ~= nil and data.schedule_index or self.schedule_index
    self.appeasement_segments = data ~= nil and data.appeasement_segments or 0
    self:ScheduleNextEruption()
    self:ReconcileSchedule()
    if data ~= nil and data.effects ~= nil then
        self.eruption_end_segment = data.eruption_end_segment
        if self.eruption_end_segment == nil or GetCurrentSeasonSegment() < self.eruption_end_segment then
            self:ResumeEffects(data.effects)
        else
            self.eruption_end_segment = nil
        end
    end
end

function VolcanoManager:OnSave()
    local effects = {
        eruptions = {},
        ash = {},
        smoke = {},
    }
    for _, record in ipairs(self.eruption_records) do
        local time_remaining = GetTaskTimeRemaining(record.endtask)
        if time_remaining ~= nil then
            table.insert(effects.eruptions, { time_remaining = time_remaining })
        end
    end
    for _, effect in ipairs(self.ash_effects) do
        local remaining = GetTaskTimeRemaining(effect.endtask)
        if remaining ~= nil then
            table.insert(effects.ash, {
                delay = GetTaskTimeRemaining(effect.starttask) or 0,
                remaining = remaining,
                duration = effect.duration,
            })
        end
    end
    for _, effect in ipairs(self.smoke_effects) do
        local remaining = GetTaskTimeRemaining(effect.endtask)
        if remaining ~= nil then
            table.insert(effects.smoke, {
                delay = GetTaskTimeRemaining(effect.starttask) or 0,
                remaining = remaining,
                duration = effect.duration,
            })
        end
    end
    local firerain_end = GetTaskTimeRemaining(self.firerain_endtask)
    if firerain_end ~= nil then
        effects.firerain = {
            delay = GetTaskTimeRemaining(self.firerain_starttask) or 0,
            remaining = firerain_end,
            rate = self.firerain_scheduled_rate,
            accumulator = self.firerain_accumulator,
            target_index = self.firerain_target_index,
        }
    end
    return {
        schedule_index = self.schedule_index,
        appeasement_segments = self.appeasement_segments,
        next_eruption_segment = self.next_eruption_segment,
        eruption_end_segment = self.eruption_end_segment,
        effects = effects,
    }
end

function VolcanoManager:ResumeEffects(effects)
    if effects == nil or effects.eruptions == nil or #effects.eruptions == 0 then
        return
    end

    self.erupting = true
    self:SyncNetworkState()
    self.inst:PushEvent("volcanoeruptionbegin")
    self.inst:PushEvent("OnVolcanoEruptionBegin")

    for _, saved in ipairs(effects.eruptions) do
        local record = {}
        table.insert(self.eruption_records, record)
        record.endtask = self.inst:DoTaskInTime(saved.time_remaining, function()
            self:EndEruption(record)
        end)
    end
    for _, saved in ipairs(effects.ash or {}) do
        local remaining = math.max(0, saved.remaining - saved.delay)
        if remaining > 0 then
            self:StartAshRain(saved.delay, saved.duration, remaining)
        end
    end
    for _, saved in ipairs(effects.smoke or {}) do
        local remaining = math.max(0, saved.remaining - saved.delay)
        if remaining > 0 then
            self:StartSmoke(saved.delay, saved.duration, remaining)
        end
    end
    if effects.firerain ~= nil then
        local remaining = math.max(0, effects.firerain.remaining - effects.firerain.delay)
        if remaining > 0 then
            self:StartFireRain(
                effects.firerain.delay,
                remaining,
                effects.firerain.rate,
                effects.firerain.accumulator,
                effects.firerain.target_index
            )
        end
    end
end

function VolcanoManager:OnLoad(data)
    self.loaded_data = ClimateProfiles.IsShipwreckedDry(TheWorld.state) and data or nil
    if self.active then
        self:Stop(true)
        self.active = false
        self:RefreshSeason()
    end
end

function VolcanoManager:OnRemoveEntity()
    self:Stop(false)
end

function VolcanoManager:GetDebugString()
    return string.format("active:%s, erupting:%s, schedule:%d, next:%0.1f, ash:%0.1f, smoke:%0.2f",
        tostring(self.active),
        tostring(self.erupting),
        self.schedule_index,
        self:GetTimeUntilEruption() or 0,
        self:GetAshRate(),
        self:GetSmokeRate())
end

return VolcanoManager
