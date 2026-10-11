AddPrefabPostInit("forest", function(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("interior_manager")
        inst:AddComponent("economy")
        inst:AddComponent("bigfooter")
        inst:AddComponent("roottrunkinventory") ---------------这个是啥啊
        inst:AddComponent("creature_spawner")   ----不只有生物，还有旋涡，天光之类的内容
        -- inst:AddComponent("tropicalspawner")
        inst:AddComponent("whale_hunter")
        inst:AddComponent("rainbowjellymigration")
        inst:AddComponent("quaker_interior") ------------这是啥
        inst:AddComponent("glowflyspawner")
        inst:AddComponent("floodmanager")
        inst:AddComponent("floodmosquitospawner")
        inst:AddComponent("volcanomanager")
        inst:AddComponent("hurricanemanager")
        inst:AddComponent("monsoonmanager")
        inst:AddComponent("oceanwavemanager")


        if TUNING.sealnado then
            inst:AddComponent("twisterspawner")
        end


        if TUNING.hamlet then
            inst:AddComponent("bramblemanager")
            inst:AddComponent("banditmanager")

            if TUNING.roc then
                inst:AddComponent("rocmanager")
            end
        end
    end
end)


AddPrefabPostInit("cave", function(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("interior_manager")
        inst:AddComponent("roottrunkinventory")
        inst:AddComponent("quaker_interior")
        inst:AddComponent("economy")
    end
end)

AddPrefabPostInit("world", function(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("tigersharker")
    end
    if TUNING.aporkalypse and TheWorld.ismastersim then
        inst:AddComponent("aporkalypse")
        if KnownModIndex:IsModEnabled("workshop-2657513551") then
            inst:AddComponent("dsa_aporkalypse_proxy")
        end
    end
end)

--- world_network postinit
--- #1
--AddPrefabPostInitAny(function(inst)
--    if not TheWorld or TheWorld.net ~= inst then
--        return
--    end

--    if TUNING.aporkalypse then
--        -- print("add aporkalypse in world net")
--        inst:AddComponent("aporkalypse")
--    else
--        -- print("not add aporkalypse in world net")
--    end
--end)

--- #2
-- if TUNING.aporkalypse then
--     AddComponentPostInit("autosaver", function(self)
--         self.inst:AddComponent("aporkalypse")
--     end)
-- end

--- #3
-- if TUNING.aporkalypse then
--     print("add aporkalypse in world net  package load")
--     local worldnetworks = {}
--     local MakeWorldNetwork = require("prefabs/world_network")
--     local function WorldNetPostInit(inst)
--         inst:AddComponent("aporkalypse")
--     end
--     package.loaded["prefabs/world_network"] = function(name, ...)
--         if not worldnetworks[name] then
--             worldnetworks[name] = true
--             AddPrefabPostInit(name, WorldNetPostInit)
--         end
--         return MakeWorldNetwork(name, ...)
--     end
-- end
-------------------------
local PHASE_NAMES = { "fiesta", "calm", "near", "aporkalypse", }
local PHASES = table.invert(PHASE_NAMES)

local function NetAporkalypsePostInit(inst)
    if TUNING.aporkalypse then
        inst._aporkalypse_phase = net_tinybyte(inst.GUID, "aporkalypse.phase", "aporkalypse.phasedirty")
        inst._aporkalypse_phase:set_local(2)
        inst:ListenForEvent("aporkalypse.phasedirty", function()
            TheWorld:PushEvent("aporkalypsephasechanged", PHASE_NAMES[inst._aporkalypse_phase:value()])
        end)
        if TheWorld and TheWorld.ismastersim and TheWorld.components.aporkalypse then
            inst._aporkalypse_phase:set(TheWorld.components.aporkalypse._phase)
        end
    end
end

local function NetVolcanoPostInit(inst)
    inst._tropical_volcano_active = net_bool(inst.GUID, "tropical_volcano.active", "tropicalvolcanostatedirty")
    inst._tropical_volcano_erupting = net_bool(inst.GUID, "tropical_volcano.erupting", "tropicalvolcanostatedirty")
    inst._tropical_volcano_ashrate = net_byte(inst.GUID, "tropical_volcano.ashrate", "tropicalvolcanostatedirty")
    inst._tropical_volcano_smokerate = net_byte(inst.GUID, "tropical_volcano.smokerate", "tropicalvolcanostatedirty")
    inst._tropical_volcano_active:set_local(false)
    inst._tropical_volcano_erupting:set_local(false)
    inst._tropical_volcano_ashrate:set_local(0)
    inst._tropical_volcano_smokerate:set_local(0)

    inst:ListenForEvent("tropicalvolcanostatedirty", function()
        if TheWorld ~= nil then
            TheWorld:PushEvent("tropicalvolcanostatechanged", {
                active = inst._tropical_volcano_active:value(),
                erupting = inst._tropical_volcano_erupting:value(),
                ash_rate = inst._tropical_volcano_ashrate:value(),
                smoke_rate = inst._tropical_volcano_smokerate:value() / 100,
            })
        end
    end)
end

local function NetFloodPostInit(inst)
    inst._tropical_flood_level = net_byte(inst.GUID, "tropical_flood.level", "tropicalfloodleveldirty")
    inst._tropical_flood_hamletlevel = net_byte(inst.GUID, "tropical_flood.hamletlevel", "tropicalfloodleveldirty")
    inst._tropical_flood_level:set_local(0)
    inst._tropical_flood_hamletlevel:set_local(0)

    inst:ListenForEvent("tropicalfloodleveldirty", function()
        if TheWorld ~= nil then
            TheWorld:PushEvent("tropicalfloodlevelchanged", {
                level = inst._tropical_flood_level:value() / 100,
                shipwrecked_level = inst._tropical_flood_level:value() / 100,
                hamlet_level = inst._tropical_flood_hamletlevel:value() / 100,
            })
        end
    end)
end

local function NetMonsoonPostInit(inst)
    inst._tropical_monsoon_windstrength = net_byte(inst.GUID, "tropical_monsoon.windstrength", "tropicalmonsoonwinddirty")
    inst._tropical_monsoon_windangle = net_byte(inst.GUID, "tropical_monsoon.windangle", "tropicalmonsoonwinddirty")
    inst._tropical_monsoon_windstrength:set_local(0)
    inst._tropical_monsoon_windangle:set_local(0)

    inst:ListenForEvent("tropicalmonsoonwinddirty", function()
        if TheWorld ~= nil then
            TheWorld:PushEvent("tropicalmonsoonwindchanged", {
                strength = inst._tropical_monsoon_windstrength:value() / 100,
                angle = inst._tropical_monsoon_windangle:value() / 255 * 360,
            })
        end
    end)
end

local function NetHurricanePostInit(inst)
    inst._tropical_hurricane_active = net_bool(inst.GUID, "tropical_hurricane.active", "tropicalhurricanestatedirty")
    inst._tropical_hurricane_tease = net_bool(inst.GUID, "tropical_hurricane.tease", "tropicalhurricanestatedirty")
    inst._tropical_hurricane_stormstrength = net_byte(inst.GUID, "tropical_hurricane.stormstrength", "tropicalhurricanestatedirty")
    inst._tropical_hurricane_hailrate = net_byte(inst.GUID, "tropical_hurricane.hailrate", "tropicalhurricanestatedirty")
    inst._tropical_hurricane_windactive = net_bool(inst.GUID, "tropical_hurricane.windactive", "tropicalhurricanestatedirty")
    inst._tropical_hurricane_thunder = net_byte(inst.GUID, "tropical_hurricane.thunder", "tropicalhurricanethunderdirty")
    inst._tropical_hurricane_active:set_local(false)
    inst._tropical_hurricane_tease:set_local(false)
    inst._tropical_hurricane_stormstrength:set_local(0)
    inst._tropical_hurricane_hailrate:set_local(0)
    inst._tropical_hurricane_windactive:set_local(false)
    inst._tropical_hurricane_thunder:set_local(0)

    inst:ListenForEvent("tropicalhurricanestatedirty", function()
        if TheWorld ~= nil then
            TheWorld:PushEvent("tropicalhurricanestatechanged", {
                active = inst._tropical_hurricane_active:value(),
                tease = inst._tropical_hurricane_tease:value(),
                storm_strength = inst._tropical_hurricane_stormstrength:value() / 100,
                hail_rate = inst._tropical_hurricane_hailrate:value() / 100,
                wind_active = inst._tropical_hurricane_windactive:value(),
            })
        end
    end)
    inst:ListenForEvent("tropicalhurricanethunderdirty", function()
        if TheWorld ~= nil then
            TheWorld:PushEvent("tropicalhurricanethunder")
        end
    end)

    if TheWorld ~= nil and TheWorld.ismastersim and TheWorld.components.hurricanemanager ~= nil then
        TheWorld.components.hurricanemanager:SyncNetworkState()
    end
end

AddPrefabPostInit("forest_network", function(inst)
    NetAporkalypsePostInit(inst)
    NetVolcanoPostInit(inst)
    NetFloodPostInit(inst)
    NetHurricanePostInit(inst)
    NetMonsoonPostInit(inst)
    inst:AddComponent("weatherham")
end)

AddPrefabPostInit("cave_network", NetAporkalypsePostInit)

AddPrefabPostInit("shard_network", function(inst)
    if TUNING.aporkalypse then
        inst._aporkalypse_begin_date = net_uint(inst.GUID, "aporkalypse.begin_date", "aporkalypse.begin_datedirty")
        inst._aporkalypse_begin_date:set_local(57600)
        inst:ListenForEvent("aporkalypse.begin_datedirty", function()
            if TheWorld.components.aporkalypse ~= nil then
                TheWorld.components.aporkalypse.begin_date = inst._aporkalypse_begin_date:value()
            end
        end)
        if TheWorld.ismastershard then
            Shard_SyncAporkalypseBeginDate()
        end
    end
end)
