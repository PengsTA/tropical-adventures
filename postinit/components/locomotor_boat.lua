local speed_bonus = {
    raft_old = 5 / 6,
    lograft_old = 4 / 6,
    rowboat = 6 / 6,
    armouredboat = 6 / 6,
    cargoboat = 5 / 6,
    encrustedboat = 4 / 6,
    surfboard = 6.5 / 6,
    woodlegsboat = 6 / 6,
    corkboat = 4 / 6,
    -- more entries here
}

local BoatEquip = require("tools/boat_equipment_helper")

local sail_bonus = {
    sail = 1.2,
    clothsail = 1.3,
    snakeskinsail = 1.35,
    feathersail = 1.4,
    ironwind = 1.5,
    woodlegssail = 1.01,
    trawlnet = 0.75,
    malbatrossail = 1.5,
    -- more entries here
}

local function GetBoatSpeedAdjustment(boat, sail)
    local boatbonus = speed_bonus[boat.prefab] or 1
    local sailbonus = sail and (sail.sail_speed_mult ~= nil and 1 + sail.sail_speed_mult or sail_bonus[sail.prefab]) or 1
    local adjustment = math.min(boatbonus * sailbonus - 1, 1)
    return sail ~= nil and sail:HasTag("trawlnet") and adjustment or math.max(adjustment, 0)
end

local function getspeedbonus(inst)
    if inst.replica.sailor ~= nil then
        local boat = inst.replica.sailor:GetBoat()
        if boat ~= nil then
            local sail = BoatEquip.GetSail(BoatEquip.GetBoatContainer(boat))
            return GetBoatSpeedAdjustment(boat, sail)
        end
    end
    return 0
end

--------------------这里控制水上的速度-------------------------

AddComponentPostInit("locomotor", function(self)
    local OldGetSpeedMultiplier = self.GetSpeedMultiplier
    function self:GetSpeedMultiplier()
        if (self.inst and self.inst:HasTag("aquatic") and self.inst:HasTag("player")) then
            return getspeedbonus(self.inst) + OldGetSpeedMultiplier(self) ------乘算改为加算
        end
        return OldGetSpeedMultiplier(self)
    end

    local OldStartHopping = self.StartHopping
    function self:StartHopping(x, z, target_platform)
        if self.inst.components.sailor ~= nil and self.inst.components.sailor:IsSailing() then
            self.inst.components.sailor:Disembark(nil, true)
        end
        OldStartHopping(self, x, z, target_platform)
    end
end)


AddComponentPostInit("oar", function(self, inst)
    inst:AddTag("oar") --科雷真抠门，桨连个自己的标签也没有
end)
