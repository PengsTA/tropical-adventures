local function Check(inst)
    local climate = inst.components.regionalclimate
    if TUNING.fog and climate ~= nil and climate:IsFogActive() then
        inst.components.foggroggy:Enable()
    else
        inst.components.foggroggy:Disable()
    end
end

local UPDATE_PERIOD = .5

--- 哈姆雷特雾气
local Foggroggy = Class(function(self, inst)
    self.inst              = inst
    self.inv               = self.inst.components.inventory
    self.enabled           = false
    self.groggy_bcz_foggy  = false
    self.should_clear      = false
    self.has_venting_equip = false
    self.foggroggylevel    = 0
    self.loco              = self.inst.components.locomotor
    self.updatetask        = nil
    inst:ListenForEvent("regionalclimatechanged", Check)
    inst:DoTaskInTime(0, Check)
end)

function Foggroggy:SetFogGroggyLevel(level)
    level = math.clamp(level, 0, 1)
    if self.foggroggylevel == level then
        return
    end

    self.foggroggylevel = level
    local classified = self.inst.player_classified
    if classified ~= nil and classified._tropical_foggroggylevel ~= nil then
        classified._tropical_foggroggylevel:set(math.floor(level * 100 + .5))
    end
end

function Foggroggy:ShouldBeClear()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local hasequip = self.inv and self.inv:EquipHasTag("clearfog")
    local regionaware = self.inst.components.regionaware
    return hasequip or regionaware == nil or regionaware:IsInInterior()
        or not regionaware:IsInPrimaryRegion("hamlet") or
        #TheSim:FindEntities(x, y, z, TUNING.FAN_RANGE, { "blows_air" }) > 0
end

function Foggroggy:HasVentingEquip()
    return self.should_clear or self.inv and self.inv:EquipHasTag("venting")
end

function Foggroggy:CanGroggy()
    return not self.has_venting_equip and not self.should_clear
end

function Foggroggy:OnUpdate(dt)
    self.should_clear = self:ShouldBeClear()
    self.has_venting_equip = self:HasVentingEquip()
    local climate = self.inst.components.regionalclimate
    local foggyrate = math.clamp((climate ~= nil and climate:GetFogRate() or 0) * 5, 0, 0.7)


    local level = 0
    if self.should_clear then
        level = 0
    else
        if self.has_venting_equip then
            level = foggyrate * 0.5
        else
            level = foggyrate
            if foggyrate > 0.5 then
                if not self.inst:HasTag("groggy") then
                    self.inst:AddTag("groggy")
                    self.groggy_bcz_foggy = true
                end
                self.loco:SetExternalSpeedMultiplier(self.inst, "hamfogspeed",
                    1 - foggyrate)
                self:SetFogGroggyLevel(level)
                return
            end
        end
    end
    self:SetFogGroggyLevel(level)
    if self.groggy_bcz_foggy and self.inst:HasTag("groggy") then
        self.inst:RemoveTag("groggy")
        self.groggy_bcz_foggy = false
        self.loco:RemoveExternalSpeedMultiplier(self.inst, "hamfogspeed")
    end
end

Foggroggy.LongUpdate = Foggroggy.OnUpdate

function Foggroggy:OnSave()
    local data = {}
    local references = {}
    data.groggy_bcz_foggy = self.groggy_bcz_foggy
    return data, references
end

function Foggroggy:OnLoad(data, newents)
    if data then
        if data.groggy_bcz_foggy then
            self.groggy_bcz_foggy = data.groggy_bcz_foggy
        end
    end
end

function Foggroggy:Enable()
    if self.enabled then
        return
    end

    self.enabled = true
    self:OnUpdate(UPDATE_PERIOD)
    self.updatetask = self.inst:DoPeriodicTask(UPDATE_PERIOD, function()
        self:OnUpdate(UPDATE_PERIOD)
    end)
    if self.inst.components.talker and not self.inst.components.health:IsDead() then
        -- 修复模组角色未定义 ANNOUNCE_TOO_HUMID 时, GetString 返回 nil 导致 format 报错的 bug
        -- NOTE: 测试时, 这段代码会导致长达几秒钟的断线加载, 不能确定是否是普遍情况, 没有找到原因
        local s = GetString(self.inst, "ANNOUNCE_TOO_HUMID")
        if s == nil then
            local idx = math.random(#STRINGS.CHARACTERS.GENERIC.ANNOUNCE_TOO_HUMID)
            s = STRINGS.CHARACTERS.GENERIC.ANNOUNCE_TOO_HUMID[idx]
        end
        self.inst.components.talker:Say(string.format(s, " "))
    end
end

function Foggroggy:Disable()
    if self.enabled == true then
        if self.updatetask ~= nil then
            self.updatetask:Cancel()
            self.updatetask = nil
        end
        self:SetFogGroggyLevel(0)
        if self.groggy_bcz_foggy and self.inst:HasTag("groggy") then
            self.inst:RemoveTag("groggy")
        end
        self.groggy_bcz_foggy = false
        self.loco:RemoveExternalSpeedMultiplier(self.inst, "hamfogspeed")
        self.enabled = false
        if self.inst.components.talker and not self.inst.components.health:IsDead() then
            local message = GetString(self.inst, "ANNOUNCE_DEHUMID")
            if message ~= nil then
                self.inst.components.talker:Say(message)
            end
        end
    end
end

function Foggroggy:OnRemoveEntity()
    self:Disable()
    self.inst:RemoveEventCallback("regionalclimatechanged", Check)
end

return Foggroggy
