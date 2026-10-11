local Utils = require("tools/utils")
local RegionDefs = require("tools/regiondefs")

--温度变化更加丝滑
local function OnTemperatureUpdateBefore(self)
    local climate = self.inst.components.regionalclimate
    local modifier = climate ~= nil and climate:GetTemperatureModifier() or nil
    if modifier ~= nil then
        self:SetModifier("regionalclimate", modifier)
    else
        self:RemoveModifier("regionalclimate")
    end

    return nil, false
end

-- local function GetMoistureRateBefore(self)
--     if TheWorld.state.issnowing and self.inst:AwareInTropicalArea() then
--         return { self:_GetMoistureRateAssumingRain() }, false
--     end
--     return nil, false
-- end



AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    Utils.FnDecorator(inst.components.temperature, "OnUpdate", OnTemperatureUpdateBefore)
    -- Utils.FnDecorator(inst.components.weather, "OnUpdate", OnWeatherUpdateAfter)
    -- Utils.FnDecorator(inst.components.moisture, "GetMoistureRate", GetMoistureRateBefore)
end)



local Moisture = require("components/moisture")

local function GetGlobalPrecipitationRate()
    return (TheWorld.state.israining or TheWorld.state.issnowing)
        and math.max(0, TheWorld.state.precipitationrate or 0)
        or 0
end

local function GetRegionalPrecipitationRate(inst)
    if TheWorld == nil or TheWorld.Map == nil or inst.Transform == nil then
        return nil
    end

    local x, _, z = inst.Transform:GetWorldPosition()
    local map = TheWorld.Map
    -- Regional climates never rain through an interior. Returning a concrete
    -- zero also prevents the coincident DST weather clock from wetting Hamlet
    -- rooms or Volcano.
    if map:IsInteriorAtPoint(x, 0, z) then
        return 0
    end

    local primary = map:GetPrimaryRegionAtPoint(x, 0, z)
    if primary == "dst" then
        return nil
    end

    local subregion = map:GetSubregionAtPoint(x, 0, z)
    if primary == "shipwrecked" then
        if subregion ~= RegionDefs.GetSubregionName(RegionDefs.SUBREGION.sw_vanilla) then
            return 0
        end
        return GetGlobalPrecipitationRate()
    end

    if primary == "hamlet" then
        return GetGlobalPrecipitationRate()
    end

    return nil
end
function Moisture:GetMoistureRate()
    local floodmanager = TheWorld.components.floodmanager
    if floodmanager ~= nil and self.inst.Transform ~= nil then
        local x, _, z = self.inst.Transform:GetWorldPosition()
        local driving = self.inst.components.driver ~= nil
            and self.inst.components.driver.GetIsDriving ~= nil
            and self.inst.components.driver:GetIsDriving()
        if not driving and floodmanager:IsFloodedAtPoint(x, z) then
            return 1 - self:GetWaterproofness()
        end
    end

    local climate = self.inst.components.regionalclimate
    local regional_rate = climate ~= nil
        and climate:GetPrecipitationRate()
        or GetRegionalPrecipitationRate(self.inst)
    if regional_rate ~= nil then
        return regional_rate > 0
            and self:_GetMoistureRateAssumingRain() * regional_rate
            or -0.005
    end

    if not TheWorld.state.israining then
        return -0.005 ---没搞懂为什么冬天不会自然干燥
    end

    return self:_GetMoistureRateAssumingRain()
end

-- 用于控制熊大和巨鹿刷新条件，组件没有可以hook的方法，只好通过该方式来阻止生成
local function AreaAwareCurrentlyInTagBefore(self, tag)
    if tag == "nohasslers" and (self:CurrentlyInTag("tropical"))
    then
        return { true }, true
    end
end

AddComponentPostInit("areaaware", function(self)
    Utils.FnDecorator(self, "CurrentlyInTag", AreaAwareCurrentlyInTagBefore)
end)


----毒蜘蛛刷新
for _, prefab in pairs({ "spider_warrior" }) do
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        inst:DoTaskInTime(0, function(inst)
            local map = GLOBAL.TheWorld.Map
            local x, y, z = inst.Transform:GetWorldPosition()
            if x and y and z then
                local ground = map:GetTile(map:GetTileCoordsAtPoint(x, y, z))
                if IsSwLandTile(ground) then
                    local bolha = SpawnPrefab("spider_tropical")
                    if bolha then
                        bolha.Transform:SetPosition(x, y, z)
                    end
                    inst:Remove()
                end
            end
        end)
    end)
end


----热带蝴蝶和发光飞虫刷新
-- for _, prefab in pairs({ "butterfly" }) do
--     AddPrefabPostInit(prefab, function(inst)
--         if not TheWorld.ismastersim then
--             return
--         end

--         inst:DoTaskInTime(0, function(inst)
--             local map = TheWorld.Map
--             local x, y, z = inst.Transform:GetWorldPosition()
--             if x and y and z then
--                 local butterfly
--                 local ground = map:GetTile(map:GetTileCoordsAtPoint(x, y, z))
--                 if IsSwLandTile(ground) then
--                     butterfly = SpawnPrefab("butterfly_tropical")
--                 elseif IsHamLandTile(ground) then
--                     butterfly = SpawnPrefab("glowfly")
--                 end

--                 if butterfly then
--                     -- if butterfly.components.pollinator ~= nil then
--                     --     butterfly.components.pollinator:Pollinate(spawnflower)
--                     -- end
--                     -- if butterfly.components.homeseeker ~= nil then
--                     --     butterfly.components.homeseeker:SetHome(spawnflower)
--                     -- end
--                     butterfly.Transform:SetPosition(x, y, z)
--                     inst:Remove()
--                 end
--             end
--         end)
--     end)
-- end
