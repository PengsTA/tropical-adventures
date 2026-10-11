local BoatHealth = Class(function(self, inst)
    self.inst = inst
    self.maxhealth = 100
    self.currenthealth = 100
    self.rate = 0
    self.consuming = false
    self.moving = false
    self.depletedfn = nil
    self.impactcooldowns = {}
end)

local function Sync(inst, self)
    if inst.replica.boathealth ~= nil then
        inst.replica.boathealth._maxhealth:set(math.max(0, math.floor(self.maxhealth + 0.5)))
        inst.replica.boathealth._currenthealth:set(math.max(0, math.floor(self.currenthealth + 0.5)))
    end
end

function BoatHealth:TryApplyImpact(amount, damage_type, source, cooldown)
    if amount == nil or amount >= 0 then
        return false
    end

    local now = GetTime()
    local key = damage_type or "impact"
    if (self.impactcooldowns[key] or 0) > now then
        return false
    end

    self.impactcooldowns[key] = now + (cooldown or 0)
    self:DoDelta(amount, damage_type, source)
    self.inst:PushEvent("boatimpact", {
        damage = -amount,
        damage_type = damage_type,
        source = source,
    })
    return true
end

function BoatHealth:SetDepletedFn(fn)
    self.depletedfn = fn
end

function BoatHealth:SetHealth(health, perish_time)
    self.maxhealth = health or self.maxhealth
    self.currenthealth = self.maxhealth
    self.rate = perish_time and perish_time > 0 and self.maxhealth / perish_time or self.rate
    Sync(self.inst, self)
end

function BoatHealth:SetMaxHealth(health)
    self.maxhealth = health or self.maxhealth
    self.currenthealth = math.min(self.currenthealth, self.maxhealth)
    Sync(self.inst, self)
end

function BoatHealth:SetCurrentHealth(health)
    local oldpercent = self:GetPercent()
    self.currenthealth = math.clamp(health or self.currenthealth, 0, self.maxhealth)
    Sync(self.inst, self)
    self.inst:PushEvent("boathealthchange", {
        percent = self:GetPercent(),
        oldpercent = oldpercent,
        damage = false,
        currenthealth = self.currenthealth,
        maxhealth = self.maxhealth,
    })
end

function BoatHealth:GetPercent()
    return self.maxhealth > 0 and self.currenthealth / self.maxhealth or 0
end

function BoatHealth:IsFull()
    return self.currenthealth >= self.maxhealth
end

function BoatHealth:IsEmpty()
    return self.currenthealth <= 0
end

function BoatHealth:StartConsuming()
    self.consuming = true
    self.inst:StartUpdatingComponent(self)
end

function BoatHealth:StopConsuming()
    self.consuming = false
    self.moving = false
    self.inst:StopUpdatingComponent(self)
end

function BoatHealth:SetIsMoving(moving)
    self.moving = moving == true
end

function BoatHealth:DoDelta(amount, damage_type, source)
    if amount == nil or amount == 0 then
        return
    end

    local oldpercent = self:GetPercent()
    self.currenthealth = math.clamp(self.currenthealth + amount, 0, self.maxhealth)
    Sync(self.inst, self)

    local damage = amount < 0
    self.inst:PushEvent("boathealthchange", {
        percent = self:GetPercent(),
        oldpercent = oldpercent,
        damage = damage,
        currenthealth = self.currenthealth,
        maxhealth = self.maxhealth,
        damage_type = damage_type,
        source = source,
    })

    if self.currenthealth <= 0 and self.depletedfn ~= nil then
        self.inst:DoTaskInTime(0, self.depletedfn)
    end
end

function BoatHealth:OnUpdate(dt)
    if self.consuming and self.moving and self.rate > 0 then
        self:DoDelta(-dt * self.rate, "usage")
    end
end

function BoatHealth:OnSave()
    return {
        health = self.currenthealth,
        maxhealth = self.maxhealth,
        rate = self.rate,
    }
end

function BoatHealth:OnLoad(data)
    if data ~= nil then
        self.maxhealth = data.maxhealth or self.maxhealth
        self.currenthealth = data.health or self.currenthealth
        self.rate = data.rate or self.rate
        Sync(self.inst, self)
    end
end

return BoatHealth
