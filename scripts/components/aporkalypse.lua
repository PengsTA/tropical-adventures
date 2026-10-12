local DAY_TIME = TUNING.TOTAL_DAY_TIME
local SEG_TIME = TUNING.SEG_TIME * 8
local PHASE_NAMES = { "fiesta", "calm", "near", "aporkalypse" }
local PHASES = table.invert(PHASE_NAMES)

local function IsFinite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function IsValidState(data)
    return type(data) == "table" and PHASE_NAMES[data.phase] ~= nil
        and IsFinite(data.begin_date) and IsFinite(data.real_start_date)
        and IsFinite(data.fiesta_begin_date) and type(data.first_time) == "boolean"
end

local function OnBeginDate(self, new, old)
    if new == old or self._updating then return end
    if not IsFinite(new) then
        self._updating = true
        self.begin_date = old
        self._updating = false
        return
    end
    if not self.inst.ismastershard then
        -- A secondary may request a change, but cannot change its cached master state.
        self._updating = true
        self.begin_date = old
        self._updating = false
        self:ScheduleAporkalypse(new)
    else
        self:SyncState()
    end
end

local function OnPhase(self, new, old)
    if new ~= old and not self._updating then self:SyncState() end
end

local Aporkalypse = Class(function(self, inst)
    assert(inst.ismastersim, "aporkalypse should not exist on client")
    self.inst = inst
    self.near_days = 7 * DAY_TIME
    self.aporkalypse_duration = 20 * DAY_TIME
    self.should_fiesta_duration = 3 * DAY_TIME
    self.fiesta_duration = 7 * DAY_TIME
    self.periodtime = 120 * DAY_TIME

    self._updating = true
    self.first_time = true
    self.begin_date = self.periodtime
    self.real_start_date = 0
    self.fiesta_begin_date = 0
    self._phase = PHASES.calm
    self._updating = false

    self._onclocktick = function() self:OnClockTick() end
    self._ontimerdone = function(_, data) self:OnTimerDone(data) end
    if inst.ismastershard then
        inst:ListenForEvent("clocktick", self._onclocktick)
        self:QueueInitialSync()
    end
    inst:ListenForEvent("timerdone", self._ontimerdone)
end, nil, { begin_date = OnBeginDate, _phase = OnPhase })

function Aporkalypse:GetTimeInSeconds()
    return (self.inst.state.cycles + self.inst.state.time) * DAY_TIME
end

function Aporkalypse:GetState()
    return {
        phase = self._phase,
        begin_date = self.begin_date,
        real_start_date = self.real_start_date,
        fiesta_begin_date = self.fiesta_begin_date,
        first_time = self.first_time,
    }
end

function Aporkalypse:RestoreState(data)
    if not IsValidState(data) then return false end
    self._updating = true
    self.begin_date = data.begin_date
    self.real_start_date = data.real_start_date
    self.fiesta_begin_date = data.fiesta_begin_date
    self.first_time = data.first_time
    self._phase = data.phase
    self._updating = false
    return true
end

function Aporkalypse:ApplyMasterState(data)
    if self.inst.ismastershard or not self:RestoreState(data) then return false end
    self:SyncState()
    return true
end

function Aporkalypse:SyncState()
    local inst = self.inst
    if inst.net ~= nil and inst.net._aporkalypse_phase ~= nil then
        inst.net._aporkalypse_phase:set(self._phase)
    end
    if inst.components.dsa_aporkalypse_proxy ~= nil then
        inst.components.dsa_aporkalypse_proxy:SetDate(self.begin_date)
    end
    if self._local_phase ~= self._phase then
        self._local_phase = self._phase
        if self:IsActive() then
            self:ScheduleAporkalypseTasks()
        else
            inst.components.timer:StopTimer("aporkalypse.herald")
            inst.components.timer:StopTimer("aporkalypse.vampire")
        end
        -- Server world state must update even on a dedicated server without clients.
        inst:PushEvent("aporkalypsephasechanged", PHASE_NAMES[self._phase])
    end
    if inst.ismastershard then inst:PushEvent("master_aporkalypseupdate") end
end

function Aporkalypse:QueueInitialSync()
    if self._initial_sync ~= nil then self._initial_sync:Cancel() end
    self._initial_sync = self.inst:DoTaskInTime(0, function()
        self._initial_sync = nil
        -- World timers and the saved state have finished loading by this point.
        self:SyncState()
    end)
end

function Aporkalypse:OnClockTick()
    if not self.inst.ismastershard then return end
    local now = self:GetTimeInSeconds()
    local old_phase, old_date = self._phase, self.begin_date
    self._updating = true
    if self._phase <= PHASES.calm and now >= self.begin_date - self.near_days then
        self._phase = PHASES.near
    end
    if self._phase <= PHASES.near then
        if now >= self.begin_date then
            self.real_start_date = now
            self._phase = PHASES.aporkalypse
        end
    elseif self:IsActive() then
        if now > self.begin_date then
            if now - self.real_start_date >= self.aporkalypse_duration then
                self.fiesta_begin_date = now
                self._phase = PHASES.fiesta
                self:ScheduleAporkalypse()
                self.first_time = false
            end
        else
            if now - self.real_start_date >= self.should_fiesta_duration then
                self.fiesta_begin_date = now
                self._phase = PHASES.fiesta
            else
                self._phase = PHASES.calm
            end
            self.first_time = false
        end
    end
    if self._phase == PHASES.fiesta and now - self.fiesta_begin_date > self.fiesta_duration then
        self._phase = PHASES.calm
    end
    self._updating = false
    if old_phase ~= self._phase or old_date ~= self.begin_date then self:SyncState() end
end

function Aporkalypse:ScheduleAporkalypse(date)
    if date ~= nil and not IsFinite(date) then return end
    if not self.inst.ismastershard then
        SendModRPCToShard(GetShardModRPC("TropicalAdventures", "SyncAporkalypseBeginDate"), SHARDID.MASTER, date)
        return
    end
    local now = self:GetTimeInSeconds()
    local delta = date ~= nil and date - now or self.periodtime
    if delta > self.periodtime or delta < 0 then delta = delta % self.periodtime end
    self.begin_date = now + delta
end

function Aporkalypse:AdjustBeginDate(delta)
    if not IsFinite(delta) then return end
    if self.inst.ismastershard then
        self:ScheduleAporkalypse(self.begin_date + delta)
    else
        -- Deltas accumulate on the master even if a secondary's snapshot is delayed.
        SendModRPCToShard(GetShardModRPC("TropicalAdventures", "AdjustAporkalypseBeginDate"), SHARDID.MASTER, delta)
    end
end

function Aporkalypse:ScheduleHeraldCheck()
    local timer = self.inst.components.timer
    if not timer:TimerExists("aporkalypse.herald") then
        timer:StartTimer("aporkalypse.herald", math.random(SEG_TIME / 2, SEG_TIME) + SEG_TIME)
    end
end

function Aporkalypse:ScheduleVampireBatCheck()
    local timer = self.inst.components.timer
    if not timer:TimerExists("aporkalypse.vampire") then
        timer:StartTimer("aporkalypse.vampire", math.random(SEG_TIME / 8, SEG_TIME / 4))
    end
end

function Aporkalypse:ScheduleAporkalypseTasks()
    if self.inst:HasTag("cave") then self:ScheduleHeraldCheck() end
    self:ScheduleVampireBatCheck()
end

function Aporkalypse:OnTimerDone(data)
    if data == nil or not self:IsActive() then return end
    if data.name == "aporkalypse.herald" then
        for _, player in pairs(AllPlayers) do
            if player:IsValid() and player.components.health ~= nil and not player.components.health:IsDead() then
                local herald = GetClosestInstWithTag("ancient", player, 30)
                if herald == nil then
                    local position = FindNearbyLand(player:GetPosition())
                    if position ~= nil then herald = SpawnAt("ancient_herald", position) end
                end
                if herald ~= nil and herald.components.combat ~= nil then
                    herald.components.combat:SuggestTarget(player)
                    break
                end
            end
        end
        self.inst.components.timer:StartTimer("aporkalypse.herald", math.random(SEG_TIME / 2, SEG_TIME))
    elseif data.name == "aporkalypse.vampire" and #AllPlayers > 0 then
        local count = math.ceil(math.min(16 * #AllPlayers, 50) / #AllPlayers)
        for _, player in pairs(AllPlayers) do
            if player:IsInWorld() and player:IsValid() and player.components.health ~= nil and not player.components.health:IsDead() then
                for i = 1, count do
                    local x, y, z = player.Transform:GetWorldPosition()
                    local theta = math.random() * TWOPI
                    local radius = 4 + math.random() * 16
                    local bat = SpawnAt("circlingbat", Vector3(x + radius * math.sin(theta), 0, z + radius * math.cos(theta)))
                    if bat ~= nil and bat.components.combat ~= nil then bat.components.combat:SuggestTarget(player) end
                end
            end
        end
    end
end

function Aporkalypse:OnSave()
    if self.inst.ismastershard then return self:GetState() end
end

function Aporkalypse:OnLoad(data)
    if self.inst.ismastershard and self:RestoreState(data) then self:QueueInitialSync() end
end

function Aporkalypse:OnRemoveFromEntity()
    if self._initial_sync ~= nil then self._initial_sync:Cancel() end
    if self.inst.ismastershard then self.inst:RemoveEventCallback("clocktick", self._onclocktick) end
    self.inst:RemoveEventCallback("timerdone", self._ontimerdone)
    if self.inst.components.timer ~= nil then
        self.inst.components.timer:StopTimer("aporkalypse.herald")
        self.inst.components.timer:StopTimer("aporkalypse.vampire")
    end
end

Aporkalypse.OnRemoveEntity = Aporkalypse.OnRemoveFromEntity

function Aporkalypse:IsNear() return self._phase == PHASES.near end
function Aporkalypse:GetBeginDate() return self.begin_date end
function Aporkalypse:IsActive() return self._phase == PHASES.aporkalypse end
function Aporkalypse:GetFiestaActive() return self._phase == PHASES.fiesta end
function Aporkalypse:GetDebugString()
    return string.format("aporkalypse begin_date: %.2f phase: %s (%s)", self.begin_date,
        PHASE_NAMES[self._phase], self.inst.ismastershard and "master" or "replica")
end

return Aporkalypse
