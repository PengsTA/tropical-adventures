local Regrowth = require("tools/tropical_regrowth")
local Definitions = require("datadefs/tropical_regrowth")

Regrowth.Install()

AddComponentPostInit("plantregrowth", function(self)
    if Definitions.spreading[self.inst.prefab] == nil then
        return
    end
    local TrySpawnNearby = self.TrySpawnNearby
    self.TrySpawnNearby = function(component)
        if Regrowth.CanSpread(component.inst) then
            return TrySpawnNearby(component)
        end
        component:ResetGrowthTime()
    end
end)

for prefab, definition in pairs(Definitions.spreading) do
    AddPrefabPostInit(prefab, function(inst)
        inst:AddTag(definition.name)
        inst:AddTag(definition.searchtag)
        if not TheWorld.ismastersim or inst.components.plantregrowth ~= nil then
            return
        end
        inst:AddComponent("plantregrowth")
        local regrowth = inst.components.plantregrowth
        regrowth:SetProduct(definition.product)
        regrowth:SetSearchTag(definition.searchtag)
        regrowth:SetSkipCanPlantCheck(definition.water == true)
        regrowth:SetRegrowthRate(TUNING.EVERGREEN_REGROWTH.OFFSPRING_TIME)
    end)
end

local function VegetableTimeMultiplier()
    return not TheWorld.state.isnight and TUNING.CARROT_REGROWTH_TIME_MULT or 0
end

local function FlowerTimeMultiplier()
    local state = TheWorld.state
    if state.isnight or state.israining or state.wetness <= 1 then
        return 0
    end
    return TUNING.FLOWER_REGROWTH_TIME_MULT * (state.isspring and 2 or 1)
end

AddComponentPostInit("regrowthmanager", function(self)
    for prefab, definition in pairs(Definitions.harvested) do
        self:SetRegrowthForType(prefab,
            definition.flower and TUNING.FLOWER_REGROWTH_TIME or TUNING.CARROT_REGROWTH_TIME,
            prefab, definition.flower and FlowerTimeMultiplier or VegetableTimeMultiplier)
    end
    self:SetRegrowthForType("crabhole", TUNING.RABBITHOLE_REGROWTH_TIME, "crabhole", function()
        return TheWorld.state.issummer and TUNING.RABBITHOLE_REGROWTH_TIME_SUMMER_MULT
            or TUNING.RABBITHOLE_REGROWTH_TIME_MULT
    end)
end)

for prefab, definition in pairs(Definitions.harvested) do
    if not definition.reported then
        AddPrefabPostInit(prefab, function(inst)
            if not TheWorld.ismastersim or inst.components.pickable == nil then
                return
            end
            local OnPicked = inst.components.pickable.onpickedfn
            inst.components.pickable.onpickedfn = function(plant, ...)
                TheWorld:PushEvent("beginregrowth", plant)
                if OnPicked ~= nil then
                    return OnPicked(plant, ...)
                end
            end
        end)
    end
end
