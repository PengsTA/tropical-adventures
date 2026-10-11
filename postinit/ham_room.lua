local Utils = require("tools/utils")
local RegionDefs = require("tools/regiondefs")

--限制制作的配方
-- local banrecipe = { "hua_player_house_recipe", "homesign", "townportal", "telebase", "hua_player_house1_recipe",
--     "hua_player_house_pvz_recipe", "hua_player_house_tardis_recipe", "infantree_carpet", "myth_house_bamboo",
--     "playerhouse_city"
-- }
-- for i, v in ipairs(banrecipe) do
--     local recipe = AllRecipes[v]
--     if recipe then
--         local old = recipe.testfn or nil
--         recipe.testfn = function(pt, rot, ...)
--             if IsHamRoomAtPoint(pt.x, 0, pt.z) then
--                 return false
--             end
--             if old ~= nil then
--                 return old(pt, rot, ...)
--             end
--             return true
--         end
--     end
-- end

-----------以下来自猪人部落-------------
local StopAmbientRainSound, StopTreeRainSound, StopUmbrellaRainSound, StopBarrierSound
local _rainfx, _snowfx, _lunarhailfx, _pollenfx
local _last_interior = false
local function WeatherClientOnUpdateBefore()
    if not ThePlayer then return end

    -- 只在客机执行，这里只改本地玩家视觉效果，实际效果在其他地方修改
    local is_interior = ThePlayer:HasTag(RegionDefs.INTERIOR_TAG)
    if is_interior == _last_interior then
        if is_interior then
            return nil, true
        end
        return
    end
    _last_interior = is_interior
    if not is_interior then
        return
    end

    if StopAmbientRainSound then StopAmbientRainSound() end
    if StopTreeRainSound then StopTreeRainSound() end
    if StopUmbrellaRainSound then StopUmbrellaRainSound() end
    if StopBarrierSound then StopBarrierSound() end

    if _rainfx then
        _rainfx.particles_per_tick = 0
        _rainfx.splashes_per_tick = 0
    end
    if _lunarhailfx then
        _lunarhailfx.particles_per_tick = 0
        _lunarhailfx.splashes_per_tick = 0
    end
    if _snowfx then
        _snowfx.particles_per_tick = 0
    end
    if _pollenfx then
        _pollenfx.particles_per_tick = 0
    end

    return nil, true
end

local _hasfx = not TheNet:IsDedicated()

AddClassPostConstruct("components/weather", function(self)
    StopAmbientRainSound = Upvaluehelper.GetUpvalue(self.OnUpdate, "StopAmbientRainSound")
    StopTreeRainSound = Upvaluehelper.GetUpvalue(self.OnUpdate, "StopTreeRainSound")
    StopUmbrellaRainSound = Upvaluehelper.GetUpvalue(self.OnUpdate, "StopUmbrellaRainSound")
    StopBarrierSound = Upvaluehelper.GetUpvalue(self.OnUpdate, "StopBarrierSound")

    if _hasfx then
        _rainfx = Upvaluehelper.GetUpvalue(self.OnPostInit, "_rainfx")
        _snowfx = Upvaluehelper.GetUpvalue(self.OnPostInit, "_snowfx")
        _lunarhailfx = Upvaluehelper.GetUpvalue(self.OnPostInit, "_lunarhailfx")
        _pollenfx = Upvaluehelper.GetUpvalue(self.OnPostInit, "_pollenfx")
    end

    Utils.FnDecorator(self, "OnUpdate", WeatherClientOnUpdateBefore)
    self.LongUpdate = self.OnUpdate
end)


--懒得找防寒隔热的组件了，直接覆盖onupdate更省事
local function OnTemperatureUpdateBefore(self)
    local regionaware = self.inst.components.regionaware
    if regionaware ~= nil and regionaware:IsInInterior() then
        local current_temperature = self:GetCurrent()
        local adjustment = current_temperature > 30 and -0.1 or (current_temperature < 20 and 0.1 or 0)
        if adjustment ~= 0 then
            self:SetTemperature(self.current + adjustment)
        end

        return nil, true
    end
end

local function OnMoistureUpdateBefore(self)
    local regionaware = self.inst.components.regionaware
    if regionaware ~= nil and regionaware:IsInInterior() then
        local adjustment = self.moisture > 0 and -0.1 or 0
        if adjustment ~= 0 then
            self:DoDelta(adjustment)
        end
        return nil, true
    end
end

-- PlayFootstep函数使用，我需要玩家在室内走路时有声音，但是因为没有地皮，只能覆盖函数，这里使用木板地皮的声音
local function GetCurrentTileTypeBefore(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if TheWorld.Map:IsInteriorAtPoint(x, 0, z) then
        return { WORLD_TILES.WOODFLOOR, GetTileInfo(WORLD_TILES.WOODFLOOR) }, true
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    Utils.FnDecorator(inst.components.temperature, "OnUpdate", OnTemperatureUpdateBefore)
    Utils.FnDecorator(inst.components.moisture, "OnUpdate", OnMoistureUpdateBefore)
    Utils.FnDecorator(inst, "GetCurrentTileType", GetCurrentTileTypeBefore)
end)



--以下大部分来自花花的神话方寸山
AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then
        return
    end
end)


---------spidereggsack
local _custom_candeploy_fn = function(inst, pt, mouseover, deployer, rot)
    local x, y, z = pt:Get()
    local judge = TheWorld.Map:CanDeployAtPoint(pt, inst, mouseover)
    if judge and not inst:IsInHamRoom() then
        return true
    end
    return false
end

AddPrefabPostInit("spidereggsack", function(inst)
    if TheWorld.ismastersim then
        inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
        inst._custom_candeploy_fn = _custom_candeploy_fn
    end
end)

local monster = { "hound", "firehound", "icehound", "moonhound", "mutatedhound", "warg",
    "warglet", "lunarthrall_plant", "vampirebat", "crawlinghorror", "terrorbeak", "gestalt", "warningshadow" }
for i, v in ipairs(monster) do --
    AddPrefabPostInit(v, function(inst)
        if TheWorld.ismastersim then
            inst:DoTaskInTime(0, function(...)
                if inst:IsInHamRoom() then
                    inst:Remove()
                end
            end)
        end
    end)
end
AddPrefabPostInit("telestaff", function(inst)
    if inst.components.spellcaster then
        local old = inst.components.spellcaster.CastSpell
        inst.components.spellcaster.CastSpell = function(self, target, pos, ...)
            local caster = inst.components.inventoryitem.owner or target
            if caster and caster:IsInHamRoom() then
                if TheWorld:HasTag("cave") then --------检查是地上还是地下世界
                    TheWorld:PushEvent("ms_miniquake", { rad = 3, num = 5, duration = 1.5, target = inst })
                else
                    SpawnPrefab("thunder_close")
                end
                if inst.components.finiteuses ~= nil then
                    inst.components.finiteuses:Use(1)
                end
                return
            end
            return old(self, target, pos, ...)
        end
    end
end)




--farming_manager
-- AddComponentPostInit("farming_manager", function(self, inst)
--     if not TheWorld.ismastersim then
--         return
--     end
--     local old_GetTileNutrients = self.GetTileNutrients
--     self.GetTileNutrients = function(self, x, y, ...)
--         if NU_GARDEN_TILES[tostring(x) .. "_" .. tostring(y)] then
--             return 100, 100, 100
--         end
--         return old_GetTileNutrients(self, x, y, ...)
--     end
-- end) --farmplantstress


-- AddComponentPostInit("farmplantstress", function(self, inst)
--     if not TheWorld.ismastersim then
--         return
--     end
--     --[[
--                 self.final_stress_state = stress <= 1 and FARM_PLANT_STRESS.NONE		-- allow one mistake
--                                 or stress <= 6 and FARM_PLANT_STRESS.LOW		-- one and half categories can fail, take your pick
--                                 or stress <= 11 and FARM_PLANT_STRESS.MODERATE  -- almost 3 categories can fail
--                                 or FARM_PLANT_STRESS.HIGH	
--         ]]
--     local old_CalcFinalStressState = self.CalcFinalStressState
--     self.CalcFinalStressState = function(...)
--         if self.inst:IsInHamRoom() then
--             if TUNING.FARM_BM == 100 then
--                 self.stress_points = 0
--                 self.final_stress_state = GLOBAL.FARM_PLANT_STRESS.NONE
--             else
--                 self.stress_points = math.max(self.stress_points - TUNING.FARM_BM, 0)
--             end
--         end
--         old_CalcFinalStressState(...)
--     end
-- end)



--落石--warningshadow---警告阴影
AddPrefabPostInit("cavein_boulder", function(inst)
    inst:ListenForEvent("startfalling", function(inst)
        if inst:IsInHamRoom() then
            local x, y, z = inst.Transform:GetWorldPosition()
            local fx = SpawnPrefab("cavein_debris") ---落石的警告
            fx.Transform:SetScale(1, 0.25 + math.random() * 0.07, 1)
            fx.Transform:SetPosition(x, 0, z)

            if inst:HasTag("FX") then
                inst:Hide()
            else
                inst:Remove()
            end
        end
    end)
end)


AddPrefabPostInit("farm_plow_item", function(inst)
    local old = inst._custom_candeploy_fn
    if old then
        inst._custom_candeploy_fn = function(...)
            if inst:IsInHamRoom() then
                return false
            else
                return old(...)
            end
        end
    end
end)


-- AddPrefabPostInit("deciduoustree", function(inst)
--     local old_load=inst.OnLoad or function (...) return end
--     inst.OnLoad=function (inst,...)
--         old_load(inst,...)
--         if inst and inst.components.growable and inst:IsInHamRoom() then
--             inst.components.growable:SetStage(3)
--         end
--     end
-- end)
--tall
--        inst.components.growable:SetStage(stage == 0 and math.random(1, 3) or stage)


--潮湿度--干燥
-- if TUNING.WATER_BM then
-- AddComponentPostInit("moisture", function(self) --房子里面不会降雨
--     local old = self.GetMoistureRate
--     function self:GetMoistureRate()
--         if self.inst:IsInHamRoom() then
--             return 0
--         end
--         return old(self)
--     end
-- end)
-- end


--如果在区域内就更新滤镜  ------------滤镜似乎没有效果
-- AddComponentPostInit("areaaware", function(self)
--     local old = self.UpdatePosition
--     function self:UpdatePosition(x, y, z, ...)
--         if TheWorld.Map:IsHamRoomAtPoint(x, 0, z) then
--             if self.current_area_data ~= nil then
--                 self.current_area = -1
--                 self.current_area_data = nil
--                 self.inst:PushEvent("changearea", self:GetCurrentArea())
--             end
--             return
--         end
--         return old(self, x, y, z, ...)
--     end
-- end)


-- --这个地方应该渺无鸟烟

AddComponentPostInit("birdspawner", function(self)
    local old_GetSpawnPoint = self.GetSpawnPoint
    function self:GetSpawnPoint(pt)
        if TheWorld.Map:IsInteriorAtPoint(pt:Get()) then
            return nil
        end
        return old_GetSpawnPoint(self, pt)
    end
end)




--是否枯萎
AddComponentPostInit("witherable", function(self)
    if self.inst then
        self.inst:DoTaskInTime(0.1, function(crop)
            local x, y, z = crop.Transform:GetWorldPosition()
            if TheWorld.Map:IsInteriorAtPoint(x, y, z) then
                self:Enable(false)
                -- print("是否枯萎",crop.prefab)
            end
        end)
    end
end)

--是否睡觉
-- AddComponentPostInit("sleeper", function(self)
--     local old_GoToSleep = self.GoToSleep
--     self.GoToSleep = function(...)
--         if self.inst:IsInHamRoom() then
--             return
--         else
--             old_GoToSleep(...)
--         end
--     end
-- end)

-----屏蔽 闪电 ---暂时先这样
AddPrefabPostInitAny(function(inst)
    if TheWorld.ismastersim and inst:HasTag("interior_center") then
        -- inst:AddTag("raindome") ----避雨标签
        -- inst:AddTag("shadecanopy") --防止自然、过热和玻璃雨的标签
        inst:AddComponent("lightningblocker")
        inst.components.lightningblocker:SetBlockRange(TUNING.SHADE_CANOPY_RANGE_SMALL)
        -- inst.components.lightningblocker:SetOnLightningStrike(OnLightningStrike)
    end
end)




AddPrefabPostInit("player_classified", function(inst)
    -- if not TheWorld.ismastersim then
    -- 	return
    -- end
    inst:DoTaskInTime(0.1, function()
        local play_theme_music = Upvaluehelper.GetEventHandle(inst, "play_theme_music")
        if play_theme_music ~= nil then
            inst:RemoveEventCallback("play_theme_music", play_theme_music)
            -- inst.entity:GetParent():RemoveEventCallback("play_theme_music",play_theme_music)
            local function new_play_theme_music(parent, data)
                if parent and parent:IsInHamRoom() then
                    return
                end
                -- print("没有屏蔽")
                play_theme_music(parent, data)
            end
            inst:ListenForEvent("play_theme_music", new_play_theme_music, inst.entity:GetParent())
            -- inst.entity:GetParent()
        end
    end)
end)

--消除雨雪
-- local old_update = { rain = nil, caverain = nil, snow = nil }
-- local emitters = EmitterManager --发射器
-- local oldPostUpdate = emitters.PostUpdate or nil
-- local nilfunc = function(...) end

-- function emitters:PostUpdate(...)
--     for inst, data in pairs(self.awakeEmitters.infiniteLifetimes) do
--         local x, y, z = inst.Transform:GetWorldPosition()
--         if TheWorld.Map:IsHamRoomAtPoint(x, y, z) then
--             if data.updateFunc ~= nil and data.updateFunc ~= nilfunc then
--                 old_update[inst.prefab] = data.updateFunc
--             end
--             data.updateFunc = nilfunc
--         else
--             if old_update[inst.prefab] ~= nil then
--                 data.updateFunc = old_update[inst.prefab]
--             end
--         end
--     end
--     if oldPostUpdate ~= nil then
--         oldPostUpdate(emitters, ...)
--     end
-- end

--脚步声音
-- local Old_PlayFootstep = GLOBAL.PlayFootstep
-- GLOBAL.PlayFootstep = function(inst, volume, ispredicted, ...)
--     if inst:IsInHamRoom() then
--         local sound = inst.SoundEmitter
--         if sound ~= nil then
--             sound:PlaySound(
--                 inst.sg ~= nil and inst.sg:HasStateTag("running") and "dontstarve/movement/run_woods" or
--                 "dontstarve/movement/walk_woods"
--                 ..
--                 ((inst:HasTag("smallcreature") and "_small") or
--                     (inst:HasTag("largecreature") and "_large" or "")
--                 ),
--                 nil,
--                 volume or 1,
--                 ispredicted
--             )
--         end
--     else
--         Old_PlayFootstep(inst, volume, ispredicted, ...)
--     end
-- end



------------------------------------------------------------------------------更改相关生物的大脑
--猪在小房子里面不回家
-- local function MakePigsNotGoHome(brain)
--     local flag = 0
--     for i, node in ipairs(brain.bt.root.children) do
--         if node.name == "Parallel" and node.children[1].name == "IsDay" then
--             node.children[1].fn = function() return TheWorld.state.isday or brain.inst:IsInHamRoom() end
--             flag = flag + 1
--         elseif node.name == "Parallel" and node.children[1].name == "IsNight" then
--             node.children[1].fn = function() return not TheWorld.state.isday and not brain.inst:IsInHamRoom() end
--             flag = flag + 1
--         end
--         if flag >= 2 then break end
--     end
-- end

-- AddBrainPostInit("pigbrain", MakePigsNotGoHome)


--蜜蜂晚上和冬天依然工作
-- local function MakeBeesNotGoHome(brain)
--     local flag = 0
--     for i, node in ipairs(brain.bt.root.children) do
--         if node.name == "Sequence" and node.children[1].name == "IsWinter" then
--             local old_fn = node.children[1].fn
--             node.children[1].fn = function(...) return old_fn(...) and not brain.inst:IsInHamRoom() end
--             flag = flag + 1
--         elseif node.name == "Sequence" and node.children[1].name == "IsNight" then
--             local old_fn = node.children[1].fn
--             node.children[1].fn = function(...) return old_fn(...) and not brain.inst:IsInHamRoom() end
--             flag = flag + 1
--         end
--         if flag >= 2 then break end
--     end
-- end
-- AddBrainPostInit("beebrain", MakeBeesNotGoHome)


--晚上继续产生蝴蝶，蝴蝶不回家
local function MakeButterflyNotGoHome(brain)
    local flag = 0
    for i, node in ipairs(brain.bt.root.children) do
        if node.name == "Sequence" and (node.children[1].name == "IsNight" or node.children[1].name == "IsFullOfPollen") then
            local old_fn = node.children[1].fn
            node.children[1].fn = function(...) return old_fn(...) and not brain.inst:IsInHamRoom() end
        end
    end
end
AddBrainPostInit("butterflybrain", MakeButterflyNotGoHome)

-- local function MakePerdNotGoHome(brain)
--     for i, node in ipairs(brain.bt.root.children) do
--         if node.name == "Parallel" and node.children[1].name == "IsNight" then
--             node.children[1].fn = function() return not TheWorld.state.isday and not brain.inst:IsInHamRoom() end
--         end
--     end
-- end

-- AddBrainPostInit("perdbrain", MakePerdNotGoHome)







-- local DEPLOY_IGNORE_TAGS = { "NOBLOCK", "player", "FX", "INLIMBO", "DECOR", "walkableplatform", "walkableperipheral",
--     "alt_tile", "centerlight", "liberado" }


---------------------------------------------------------------
