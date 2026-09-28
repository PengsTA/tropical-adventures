local modimport = modimport

if TA_CONFIG.DEVELOP.test_mode then --开发人员测试时才可以使用
    modimport "postinit/seafork"
    modimport "postinit/opengift"
    modimport "postinit/widgets/hoverer_info"
    --modimport "postinit/components/clockstop"
end

if TA_CONFIG.DEVELOP.test_map then --开发人员测试时才可以使用
    modimport "postinit/prefabs/test_world"
end

if not TheNet:IsDedicated() then ---客机读取主机的overrides---似乎也只能在这里读取了
    -- print("reupdate overrides in client")
    AddSimPostInit(function()
        modimport "main/ta_config"
    end)
end


modimport "postinit/world_map"    --theworld.map相关
modimport "postinit/entityscript" --修改entity相关


-----对数据表、参数常量的一些直接修改
modimport "postinit/oceanfishdef"  --引入热带鱼群
modimport "postinit/sw_fertilizer" --肥料值定义
modimport "postinit/naughty"       --淘气值
modimport "postinit/farm"          --种植相关  --通过veggies改变随机种子权重
modimport "postinit/wx78_module"
modimport "postinit/oceancolor"


----对entity C层组件的修改
-- modimport "postinit/entity/creep"  ---都放在entityscript中修改


--成系统的内容修改

modimport "postinit/prefabs/lots_of_things" ---对各种prefab追加一些标签或组件
modimport "postinit/actionrelated"
modimport "postinit/components/weather"     --热带气候（冬季降雨   ------冬雨和室内怎么联动是个问题
modimport "postinit/climate_tropical"       --热带气候
modimport "postinit/climate_nonforest"      --非大陆气候
modimport "postinit/ham_room"               --新的room
modimport "postinit/room_camera"            --房间镜头
modimport "postinit/boat"                   --单人船相关修改
modimport "postinit/natureskin_variants"    --和自然皮肤切换相关的所有内容
modimport "postinit/player_vision_post"     --四眼镜、蝙蝠帽所用
modimport "postinit/tile_post"              --特殊地皮挖起
modimport "postinit/poisonables"            --毒素debuff接口--and loot dropper--
-- modimport "postinit/camera"               --旧的房间镜头
-- modimport "postinit/sim_rain_effect"
-- modimport "postinit/player_darkness" --没有用
-- modimport "postinit/sim_ham" --ham cloud
-- modimport "postinit/entity" --不知道这个是干啥的


--components
-- modimport "postinit/components/container"
-- modimport "postinit/components/oceancolor"
-- modimport "postinit/components/playervision"
-- modimport "postinit/components/spooked"  --黄蘑菇孢子
-- modimport "postinit/components/trap"

-- modimport "postinit/components/a__template"
modimport "postinit/components/finiteuses"
modimport "postinit/components/snowball"
modimport "postinit/components/actionqueuer"
modimport "postinit/components/ambientlighting"
modimport "postinit/components/ambientsound"
modimport "postinit/components/animstate"
modimport "postinit/components/armor"
modimport "postinit/components/birdspawner"
modimport "postinit/components/boatphysics"
modimport "postinit/components/builder"
modimport "postinit/components/colourcube"
modimport "postinit/components/combat"
modimport "postinit/components/container_replica"
modimport "postinit/components/curseditem"
modimport "postinit/components/dynamicmusic"
modimport "postinit/components/edible"
modimport "postinit/components/embarker"
modimport "postinit/components/flotsamgenerator" --漂浮物刷新，TODO可能不生效
modimport "postinit/components/groundpounder"    --这个组件拍地板的？
modimport "postinit/components/hatchable"
modimport "postinit/components/healthtrigger"
modimport "postinit/components/hounded"
modimport "postinit/components/inventory_prevent_pick" ----可能和船拿不起来有关系
modimport "postinit/components/inventory"              ----主要是物品栏的钱的计算
modimport "postinit/components/inventoryitem"
modimport "postinit/components/locomotor_boat"
modimport "postinit/components/locomotor" --这两个内容需要整合一下
modimport "postinit/components/map"
modimport "postinit/components/oceanfishingrod"
modimport "postinit/components/penguinspawner"
modimport "postinit/components/plantregrowth" --植物再生
modimport "postinit/components/playercontroller"
modimport "postinit/components/playerspawner"
modimport "postinit/components/snowtile" -- disable snow effeccts
modimport "postinit/components/soundemitter"
modimport "postinit/components/thief"
modimport "postinit/components/unwrappable" ---为批量交易提供支持
modimport "postinit/components/wavemanager"
modimport "postinit/components/worldmigrator"
modimport "postinit/components/worldstate"
modimport "postinit/components/teleporter" -- 其实这是小房子的夜视
-- modimport "postinit/components/hunter_insight"

--prefabs
-- modimport "postinit/prefabs/cave"
-- modimport "postinit/prefabs/farm_plants"--目前不太需要
-- modimport "postinit/prefabs/forest"
-- modimport "postinit/prefabs/image_minisign" --会影响到其他mod
-- modimport "postinit/prefabs/player_hayfever"
modimport "postinit/prefabs/blueprints"
modimport "postinit/prefabs/dock_kit" --甲板相关
modimport "postinit/prefabs/floatable_items"
modimport "postinit/prefabs/gears"
modimport "postinit/prefabs/hats"
modimport "postinit/prefabs/inventory_classified"
-- modimport "postinit/prefabs/meatrack"
modimport "postinit/prefabs/mosquitosack"
modimport "postinit/prefabs/mushroom_farm"
modimport "postinit/prefabs/player_classified"
modimport "postinit/prefabs/player" --shopper, drownable, infestable
modimport "postinit/prefabs/spawned_creature"
modimport "postinit/prefabs/sword_lunarplant"
modimport "postinit/prefabs/tea" -- 冰茶转换小巧思
modimport "postinit/prefabs/trinket_1"
modimport "postinit/prefabs/warningshadow"
modimport "postinit/prefabs/wobster"
modimport "postinit/prefabs/world"
modimport "postinit/prefabs/wurt"

--screens and widgets
modimport "postinit/screens/playerhud" ---雾和花粉症效果在这里
modimport "postinit/widgets/mapstyle"
modimport "postinit/widgets/container_boat"
modimport "postinit/widgets/container_widget_boat"
modimport "postinit/widgets/container_woodleg_boat"
modimport "postinit/widgets/craftingmenu_ingredients"
modimport "postinit/widgets/crafttabs"
modimport "postinit/widgets/craftslot"      -- 配方tooltip
modimport "postinit/widgets/healthbadge"
modimport "postinit/widgets/inventorybar"   -- 船HUD自适应
modimport "postinit/widgets/seasonsdisplay" --还有树荫
modimport "postinit/widgets/statusdisplays_speed"
modimport "postinit/widgets/uiclock"        -- 血月时钟
modimport "postinit/widgets/seasonclock"    -- 静态季节表兼容
modimport "postinit/widgets/wikibook"

--stagegraph
-- modimport "postinit/stategraphs/stagegraph_wilson" --需要整理
modimport "postinit/stategraphs/SGwilson"
modimport "postinit/stategraphs/SGwilson_client"
modimport "postinit/stategraphs/AddIronLordStates"
modimport "postinit/stategraphs/AddIronLordStates_client"
