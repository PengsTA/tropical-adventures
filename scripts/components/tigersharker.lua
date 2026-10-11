local RESPAWN_TIME = 30 * (TUNING.TOTAL_DAY_TIME or 480)

local TigerSharker = Class(function(self, inst)
    assert(inst.ismastersim, "TigerSharker requires the master simulation")
    self.inst = inst
    self.key_dropped = false
    self.onbossremoved = function(boss)
        if self.boss == boss then
            self.boss = nil
            self:ScheduleRespawn(RESPAWN_TIME)
        end
    end
end)

function TigerSharker:GetBoss()
    local boss = self.boss
    return boss ~= nil and boss:IsValid() and not boss.components.health:IsDead() and boss or nil
end

function TigerSharker:RegisterBoss(boss)
    if boss.components.health:IsDead() then return false end
    local current = self:GetBoss()
    if current ~= nil and current ~= boss then return false end
    if self.boss ~= boss then
        self.boss = boss
        self.inst:ListenForEvent("onremove", self.onbossremoved, boss)
    end
    if self.respawn_task ~= nil then self.respawn_task:Cancel(); self.respawn_task = nil end
    self.respawn_time = nil
    return true
end

function TigerSharker:SpawnAtPoint(point)
    local boss = self:GetBoss()
    if boss ~= nil then return boss end
    if self.respawn_time ~= nil and self.respawn_time > GetTime() then return nil end
    point = point or self.home
    if point == nil or not self.inst.Map:IsPassableAtPoint(point.x, 0, point.z, true) then return nil end
    local spawned = SpawnPrefab("tigershark")
    if spawned ~= nil then
        if not self:RegisterBoss(spawned) then spawned:Remove(); return self:GetBoss() end
        spawned.Transform:SetPosition(point.x, 0, point.z)
        if self.home == nil then self.home = { x = point.x, z = point.z } end
    end
    return spawned
end

function TigerSharker:RegisterHome(point)
    if self.home == nil then self.home = { x = point.x, z = point.z } end
    return self:SpawnAtPoint(point)
end

function TigerSharker:ScheduleRespawn(delay)
    if self.respawn_task ~= nil then self.respawn_task:Cancel() end
    self.respawn_time = GetTime() + delay
    self.respawn_task = self.inst:DoTaskInTime(delay, function()
        self.respawn_task = nil
        if self:SpawnAtPoint() == nil then self:ScheduleRespawn(30) end
    end)
end

function TigerSharker:DropPendingKey(delay)
    if self.key_task ~= nil then self.key_task:Cancel() end
    self.key_task = self.inst:DoTaskInTime(delay, function()
        self.key_task = nil
        if self.pending_key ~= nil then
            local key = SpawnPrefab("woodlegs_key3")
            if key ~= nil then
                key.Transform:SetPosition(self.pending_key.x, 0, self.pending_key.z)
                self.pending_key = nil
            else
                self:DropPendingKey(1)
            end
        end
    end)
end

function TigerSharker:OnBossDeath(boss)
    if self.boss ~= boss then return end
    local x, _, z = boss.Transform:GetWorldPosition()
    self.inst:RemoveEventCallback("onremove", self.onbossremoved, boss)
    self.boss = nil
    self.home = { x = x, z = z }
    if not self.key_dropped then
        self.key_dropped = true
        self.pending_key = { x = x, z = z }
        self:DropPendingKey(50 * FRAMES)
    end
    self:ScheduleRespawn(RESPAWN_TIME)
end

function TigerSharker:Protect(point, target)
    if target == nil or not target:IsValid() or target:HasTag("playerghost") then return end
    local boss = self:SpawnAtPoint(point)
    if boss ~= nil and boss.components.combat:CanTarget(target) then
        boss.components.combat:SuggestTarget(target)
        if boss:HasTag("aquatic") and not boss.sg:HasStateTag("specialattack") then
            boss:Hide()
            boss.Transform:SetPosition(point.x, 0, point.z)
            boss.sg:GoToState("fallwarn")
        end
    end
    return boss
end

function TigerSharker:OnSave()
    local boss = self:GetBoss()
    return { boss = boss ~= nil and boss.GUID or nil, home = self.home,
        key_dropped = self.key_dropped, pending_key = self.pending_key,
        respawn_remaining = self.respawn_time ~= nil and math.max(0, self.respawn_time - GetTime()) or nil },
        boss ~= nil and { boss.GUID } or nil
end

function TigerSharker:OnLoad(data)
    if data == nil then return end
    self.home = data.home
    self.key_dropped = data.key_dropped == true
    self.pending_key = data.pending_key
    if self.pending_key ~= nil then self:DropPendingKey(0) end
    if data.respawn_remaining ~= nil then self:ScheduleRespawn(data.respawn_remaining) end
end

function TigerSharker:LoadPostPass(newents, data)
    if data == nil then return end
    local entry = data.boss ~= nil and newents[data.boss] or nil
    if entry ~= nil and entry.entity:IsValid() then self:RegisterBoss(entry.entity) end
end

function TigerSharker:OnRemoveFromEntity()
    if self.respawn_task ~= nil then self.respawn_task:Cancel() end
    if self.key_task ~= nil then self.key_task:Cancel() end
    if self.boss ~= nil then self.inst:RemoveEventCallback("onremove", self.onbossremoved, self.boss) end
end

return TigerSharker
