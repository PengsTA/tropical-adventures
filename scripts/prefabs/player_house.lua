require "prefabutil"
require "recipes"

local RoomLayouts = require "datadefs/interior"
local PlayerHouseLayout = RoomLayouts.player_house
local InteriorLayoutBuilder = require "tools/interior_layout_builder"
local InteriorRoomBuilder = require "tools/interior_room_builder"
local RoomExtensions = require "tools/interior_room_extensions"

local assets =
{
    -------house
    Asset("ANIM", "anim/pig_house_sale.zip"),


    Asset("ANIM", "anim/player_small_house1.zip"),
    Asset("ANIM", "anim/player_large_house1.zip"),
    Asset("ANIM", "anim/player_large_house1_manor_build.zip"),
    Asset("ANIM", "anim/player_large_house1_villa_build.zip"),
    Asset("ANIM", "anim/player_small_house1_cottage_build.zip"),
    Asset("ANIM", "anim/player_small_house1_tudor_build.zip"),
    Asset("ANIM", "anim/player_small_house1_gothic_build.zip"),
    Asset("ANIM", "anim/player_small_house1_brick_build.zip"),
    Asset("ANIM", "anim/player_small_house1_turret_build.zip"),


    ---------doors?-----------
    -- Asset("ANIM", "anim/pig_shop_doormats.zip"),
    Asset("ANIM", "anim/portas.zip"),
}





local prefabs =
{
}

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or inst:HasTag("fire") then
        data.burnt = true
    end

    data.build = inst.build
    data.bank = inst.bank
    data.icon = inst.icon

    data.room = inst.room or nil
    data.interiorID = inst.interiorID
end

local function onload(inst, data)
    if data and data.burnt then
        inst.components.burnable.onburnt(inst)
    end

    if data and data.build then
        inst.build = data.build
        inst.AnimState:SetBuild(inst.build)
    end

    if data and data.bank then
        inst.bank = data.bank
        inst.AnimState:SetBank(inst.bank)
    end

    if data and data.icon then
        inst.icon = data.icon
        inst.MiniMapEntity:SetIcon(inst.icon)
    end

    if data and data.sounds then
        inst.usesounds = data.sounds
    end

    if data and data.room then
        inst.room = data.room or false
    end

    if data and data.interiorID then
        inst.interiorID = data.interiorID
    end
end

local function BuildRoom(manager, room, definition)
    local size = PlayerHouseLayout.sizes[definition.kind] or definition
    room.room_template = definition.kind or room.room_template
    InteriorRoomBuilder.BuildShell(room, {
        width = definition.width or size.width,
        depth = definition.depth or size.depth,
        reference_width = definition.reference_width or size.reference_width,
        reference_depth = definition.reference_depth or size.reference_depth,
        surface_style = definition.surface_style or size.surface_style,
        center_prefab = definition.center_prefab or size.center_prefab or "playerhouse_room_center",
        perimeter_prefab = definition.perimeter_prefab or size.perimeter_prefab or "house_wall2",
    })
    InteriorLayoutBuilder.SpawnFixtures(room, definition, { playercrafted = true })
end

local function BuildPlayerHouseInterior(inst)
    local manager = TheWorld.components.interior_manager
    if manager == nil then
        return
    end

    local rooms = manager:BuildPlayerHouse(inst, PlayerHouseLayout)
    for _, definition in ipairs(PlayerHouseLayout.rooms) do
        BuildRoom(manager, rooms[definition.key], definition)
    end

    local hall_definition = PlayerHouseLayout.rooms[1]
    local hall = rooms.hall
    local exit = InteriorLayoutBuilder.SpawnFixture(hall, hall_definition.exterior_exit)
    if exit ~= nil and exit.components ~= nil and exit.components.teleporter ~= nil then
        inst.components.teleporter.targetTeleporter = exit
        exit.components.teleporter.targetTeleporter = inst
    end

    for _, connection in ipairs(PlayerHouseLayout.connections) do
        local source_room = rooms[connection.from]
        local target_room = rooms[connection.to]
        local source_door = SpawnPrefab("playerhouse_room_door")
        local target_door = SpawnPrefab("playerhouse_room_door")
        source_door.Transform:SetPosition(source_room.x + connection.from_x, 0, source_room.z + connection.from_z)
        target_door.Transform:SetPosition(target_room.x + connection.to_x, 0, target_room.z + connection.to_z)
        source_door.Transform:SetRotation(connection.rotation)
        target_door.Transform:SetRotation(connection.rotation + 180)
        local direction = RoomExtensions.NormalizeDirection(connection.direction or RoomExtensions.GetWallDirection(source_door, false))
        if direction ~= nil then
            RoomExtensions.LinkRoomDoors(
                source_door,
                source_room.id,
                direction,
                target_door,
                target_room.id
            )
        end
    end

    inst.room = true
end


local function onbuild_interior(inst)
    return BuildPlayerHouseInterior(inst)
end

--------------------------------------do teleporter------------------------
local function OnDoneTeleporting(inst, obj) ------------这是从房间出来
    if obj ~= nil and obj.Transform then
        local pos = obj:GetPosition()
        local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 2, 10)
        if offset ~= nil then
            pos.x = pos.x + math.abs(offset.x)
            pos.z = pos.z + offset.z
        end
        if obj.Physics ~= nil then
            obj.Physics:Teleport(pos.x, pos.y, pos.z)
        elseif obj.Transform ~= nil then
            obj.Transform:SetPosition(pos.x, pos.y, pos.z)
        end
    end

    if obj and obj:HasTag("player") then

    end

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_close")
end


local function OnActivateByOther(inst, source, doer)
    if doer ~= nil and doer.Physics ~= nil then
        doer.Physics:CollidesWith(COLLISION.WORLD)
    end
end

local function OnActivate(inst, doer)
    if doer:HasTag("player") then

    end
    if inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_open")
    end

    if doer and doer:HasTag("player") then
        if doer.SoundEmitter ~= nil then
            doer.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_open")
        end
    end
end

local function ShouldAcceptItem(inst, item)
    if item.prefab == "packing_permit" then
        return true
    end
    if item:HasTag("decoradordecasa") then
        return true
    else
        return false
    end
end

local function onaccept(inst, giver, item)
    inst.components.inventory:DropItem(item)
    inst.components.teleporter:Activate(item)
end

local TryPackWithPermit

local function OnGetItemFromPlayer(inst, giver, item)
    if item ~= nil and item.prefab == "packing_permit" and not inst:HasTag("portadacasa") then
        TryPackWithPermit(inst, giver, item)
        return
    elseif item ~= nil and item.prefab == "packing_permit" then
        if giver ~= nil and item.components.inventoryitem ~= nil then
            item.Transform:SetPosition(giver.Transform:GetWorldPosition())
            item.components.inventoryitem:OnDropped(true)
        end
        return
    end
    if inst.prefab:find("playerhouse_city") then
        if item.prefab:find("player_house_") and item.prefab:find("_craft") then
            local craftname1 = item.prefab:gsub("player_house_", "", 1)
            local craftname = craftname1:gsub("_craft", "")


            inst.icon = "player_house_" .. craftname .. ".tex"

            if craftname == "villa" or craftname == "manor" then
                inst.bank = "playerhouse_large"
                inst.build = "player_large_house1_" .. craftname .. "_build"
            else
                inst.bank = "playerhouse_small"
                inst.build = "player_small_house1_" .. craftname .. "_build"
            end


            inst.AnimState:SetBank(inst.bank)
            inst.AnimState:SetBuild(inst.build)
            inst.MiniMapEntity:SetIcon(inst.icon)
        end
    else
        onaccept(inst, giver, item)
    end
    -- if item.prefab == "player_house_cottage_craft" then
    --     inst.build = "player_small_house1_cottage_build"
    --     inst.AnimState:SetBuild("player_small_house1_cottage_build")
    --     inst.bank = "playerhouse_small"
    --     inst.AnimState:SetBank("playerhouse_small")
    --     inst.MiniMapEntity:SetIcon("player_house_cottage.tex")
    -- end
end

local function OnHammered(inst, worker)
    local package = SpawnAt("bundled_structure", inst)
    if package and package.components.bundled_structure then
        package.components.bundled_structure:Pack(inst)
        -- if inst.build then
        --     local build = inst.build:match("[^_]+_[^_]+$"):match("[^_]+")
        --     package.inv_image_bg = {
        --         image = "bundled_structure.tex",
        --         atlas = GetInventoryItemAtlas("bundled_structure.tex"),
        --     }
        --     package.components.inventoryitem:ChangeImageName("player_house_" .. build)
        -- end
        SpawnAt("collapse_small", inst)
        if worker and worker.SoundEmitter then
            worker.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
        end
        return true
    else
        if inst.components.workable ~= nil then
            inst.components.workable:SetWorkLeft(1)
        end
        return false
    end
end

local function PreHammered(inst, worker)
    if not (inst.components.teleporter ~= nil and inst.components.teleporter:IsBusy()) then
        return OnHammered(inst, worker)
    else
        inst:ListenForEvent("doneteleporting", OnHammered)
    end
end

function TryPackWithPermit(inst, giver, item)
    if inst.components.teleporter ~= nil and inst.components.teleporter:IsBusy() then
        if giver ~= nil and item ~= nil and item.components.inventoryitem ~= nil then
            item.Transform:SetPosition(giver.Transform:GetWorldPosition())
            item.components.inventoryitem:OnDropped(true)
        end
        return
    end

    local demolished = PreHammered(inst, giver)
    if demolished and item ~= nil then
        item:Remove()
    elseif giver ~= nil and item ~= nil and item.components.inventoryitem ~= nil then
        item.Transform:SetPosition(giver.Transform:GetWorldPosition())
        item.components.inventoryitem:OnDropped(true)
    end
end

local function onhammered_door(inst, worker)
    -- inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small") --这个是拆除动画
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function OnSnowCoveredChagned(inst, covered)
    if TheWorld.state.issnowcovered then
        inst.AnimState:OverrideSymbol("snow", inst.build, "snow")
    else
        inst.AnimState:OverrideSymbol("snow", inst.build, "emptysnow")
    end
end




local function updatelight(inst, phase)
    if phase == "night" or phase == "dusk" then
        inst.Light:Enable(true)
        inst.AnimState:PlayAnimation("lit") -------------光亮的动画有问题
    else
        inst.Light:Enable(false)
        inst.AnimState:PlayAnimation("idle")
    end
end

local function chuansong(inst, x, y, z, kill)
    if inst:HasTag("player") then
        inst:ScreenFade(false)
        inst:DoTaskInTime(1, function()
            inst:SnapCamera()
            inst:ScreenFade(true, 0.5)
        end)
    end
    if inst.Transform ~= nil then
        inst.Transform:SetPosition(x, y, z)
    end
    if kill then -----------------实测生物没有被杀
        -- inst:DoTaskInTime(0.2, function(inst)
        if inst and inst:IsValid() and inst.components.health ~= nil and not inst.components.health:IsDead() then
            -- inst and inst:IsValid() and inst:HasTag("player") and inst.components.health ~= nil and not inst.components.health:IsDead() then
            --如果不在水里 就kill
            inst.components.health:Kill()
        end
        -- end)
    end
end

local function makehousefn(name, build, bank, data)
    local function fn(Sim)
        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
        local light = inst.entity:AddLight()
        inst.entity:AddNetwork()
        inst.entity:AddSoundEmitter()
        inst.build = build
        inst.bank = bank

        local minimap = inst.entity:AddMiniMapEntity()
        minimap:SetIcon("pig_house_sale.tex")

        light:SetFalloff(1)     --没看出来干啥的
        light:SetIntensity(0.5) --设置光的衰减速度
        light:SetRadius(5)
        light:Enable(true)
        light:SetColour(180 / 255, 195 / 255, 50 / 255) ---RGB色彩调节
        -------SetColour(180 / 255, 195 / 255, 50 / 255)黄光太暖了
        inst.Transform:SetScale(0.75, 0.75, 0.75)

        MakeObstaclePhysics(inst, 0.75)

        anim:SetBank(bank)
        anim:SetBuild(build)
        anim:PlayAnimation("idle", true)
        inst.AnimState:Hide("boards")

        inst:AddTag(name)
        inst:AddTag("structure")
        inst:AddTag("hamletteleport")
        inst:AddTag("antlion_sinkhole_blocker")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")
        inst:AddComponent("interactions")

        inst:AddComponent("teleporter")
        inst.components.teleporter.onActivate = OnActivate
        inst.components.teleporter.onActivateByOther = OnActivateByOther
        inst.components.teleporter.offset = 0
        inst.components.teleporter.hamlet = true
        inst.components.teleporter.travelcameratime = 0.3
        inst.components.teleporter.travelarrivetime = 0
        inst:ListenForEvent("doneteleporting", OnDoneTeleporting)


        inst:AddComponent("inventory")
        inst:AddComponent("trader")
        inst.components.trader:SetAcceptTest(ShouldAcceptItem)
        inst.components.trader.acceptnontradable = true
        inst.components.trader.onaccept = OnGetItemFromPlayer
        inst.components.trader.deleteitemonaccept = false


        inst:AddComponent("inspectable")

        MakeSnowCovered(inst, .01)
        -- inst:WatchWorldState("issnowcovered", OnSnowCoveredChagned)
        -- OnSnowCoveredChagned(inst) --为啥要写两次啊，还少了个参数

        inst:WatchWorldState("phase", updatelight)
        updatelight(inst, TheWorld.state.phase)

        -- print("before dotaskintime !!!!!!!!!!!!!!!!!")
        -- print(inst.room) ------------这时候调用不到任何东西,所有需要调用onsave的东西需要在dotaskintime里

        inst:DoTaskInTime(0.1, function(inst)
            if not inst.room then
                onbuild_interior(inst)
            end
        end)

        inst:ListenForEvent("onbuilt", onbuilt)

        inst.OnSave = onsave
        inst.OnLoad = onload

        return inst
    end
    return fn
end

local function makehouse(name, build, bank, data)
    return Prefab("common/objects/" .. name, makehousefn(name, build, bank, data), assets, prefabs)
end


--------------------------------------do teleporter------------------------
local function OnDoneDoorTeleporting(inst, obj) ------------这是从房间出来
    if obj ~= nil and obj.Transform then
        local pos = obj:GetPosition()
        local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 2, 10)
        if offset ~= nil then
            pos.x = pos.x + 0.5 + math.abs(offset.x)
            pos.z = pos.z + offset.z
        end
        if obj.Physics ~= nil then
            obj.Physics:Teleport(pos.x, pos.y, pos.z)
        elseif obj.Transform ~= nil then
            obj.Transform:SetPosition(pos.x, pos.y, pos.z)
        end
    end

    if obj and obj:HasTag("player") then

    end

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_close")
end


local function OnActivateDoorByOther(inst, source, doer)
    -- if doer ~= nil and doer.Physics ~= nil then
    --     doer.Physics:CollidesWith(COLLISION.WORLD)
    -- end
end

local function OnActivateDoor(inst, doer)
    if doer:HasTag("player") then

    end
    if inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_open")
    end

    if doer and doer:HasTag("player") then
        if doer.SoundEmitter ~= nil then
            doer.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_open")
        end
    end
end




local function makedoorfn(name, build, bank, animation, data)
    local function fn(Sim)
        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.entity:AddSoundEmitter()
        inst.build = build
        inst.bank = bank

        local minimap = inst.entity:AddMiniMapEntity()
        -- minimap:SetIcon("pig_house_sale.tex")


        inst.Transform:SetScale(2, 2, 2)

        -- MakeObstaclePhysics(inst, 0)

        anim:SetBank(bank)
        anim:SetBuild(build)

        anim:PlayAnimation(animation, true)

        inst:AddTag("structure")
        inst:AddTag("hamletteleport")
        inst:AddTag("trader")
        inst:AddTag("alltrader")
        inst:AddTag("guard_entrance")
        inst:AddTag("liberado")
        inst:AddTag("portadacasa")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")
        inst:AddComponent("interactions")

        inst:AddComponent("teleporter")
        inst.components.teleporter.onActivate = OnActivateDoor
        inst.components.teleporter.onActivateByOther = OnActivateDoorByOther
        inst.components.teleporter.offset = 0
        inst.components.teleporter.hamlet = true
        inst.components.teleporter.travelcameratime = 0.3
        inst.components.teleporter.travelarrivetime = 0
        inst:ListenForEvent("doneteleporting", OnDoneDoorTeleporting)


        inst:AddComponent("inventory")
        inst:AddComponent("trader")
        -- inst.components.trader:SetAcceptTest(ShouldAcceptItem)
        inst.components.trader.acceptnontradable = true
        inst.components.trader.onaccept = OnGetItemFromPlayer
        inst.components.trader.deleteitemonaccept = false


        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(onhammered_door)
        -- inst.components.workable:SetOnWorkCallback(onhit)



        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = "playerhouse_city_door_" .. animation .. "_cima"
        local instname = "PLAYERHOUSE_CITY_DOOR_" .. animation:upper() .. "_CIMA"
        inst.name = STRINGS.NAMES[instname] ----------套用别的prefab的名字

        inst:DoTaskInTime(0.1, function(inst)
            if not inst.room then
                onbuild_interior(inst)
            end
        end)

        -- inst:ListenForEvent("onbuilt", onbuilt)----------没有idle动画
        inst:ListenForEvent("onremove", function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if not x then
                for k, v in pairs(Ents) do
                    if v:HasTag("multiplayer_portal") then
                        x, y, z = v.Transform:GetWorldPosition()
                    end
                end
            end
            if not x then
                x, y, z = 0, 0, 0
            end

            if inst.components.teleporter and inst.components.teleporter.targetTeleporter ~= nil then
                local target = inst.components.teleporter.targetTeleporter
                local target_x, target_y, target_z = target.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(target_x, 0, target_z, 25, nil, { "INLIMBO" })


                for i, v in ipairs(ents) do
                    if v.components.workable ~= nil then --工作
                        v.components.workable:Destroy(v) --这里墙不会被摧毁,只会摧毁其他建筑
                    elseif v:HasTag("player") or v:HasTag("irreplaceable") or v.components.health ~= nil then
                        chuansong(v, x, y, z, true)
                    end
                end

                TheWorld:DoTaskInTime(0.5, function(world)
                    local ents2 = TheSim:FindEntities(target_x, 0, target_z, 20)
                    for i, v in ipairs(ents2) do
                        if v and v.components.inventoryitem ~= nil then
                            chuansong(v, x, y, z)
                        else
                            v:Remove()
                        end
                    end
                    -- local collapse = SpawnPrefab("collapse_big")
                    -- collapse.Transform:SetPosition(x, 0, z)
                end)
            end
        end)

        inst.OnSave = onsave
        inst.OnLoad = onload

        return inst
    end
    return fn
end



local function makedoor(name, build, bank, animation, data)
    return Prefab("common/objects/" .. name, makedoorfn(name, build, bank, animation, data), assets, prefabs)
end

local function placefn(inst)
    inst.Transform:SetScale(0.75, 0.75, 0.75)
    inst.AnimState:Hide("snow")
    inst.AnimState:Hide("boards")
end

local function placedoorfn(inst)
    inst.Transform:SetScale(2, 2, 2)
    -- inst.AnimState:Hide("snow")
    -- inst.AnimState:Hide("boards")
end

return makehouse("playerhouse_city", "pig_house_sale", "pig_house_sale", { indestructable = true }),
    makedoor("stone_door", "portas", "portas", "pedra", { indestructable = true }),
    makedoor("plate_door", "portas", "portas", "metal", { indestructable = true }),
    makedoor("organic_door", "portas", "portas", "peagank", { indestructable = true }), --森林
    makedoor("round_door", "portas", "portas", "pano", { indestructable = true }),      ---原木

    ---------------------------需要根据原本的调整camera
    -- MakePlacer("common/playerhouse_city_placer", "pig_house_sale", "pig_house_sale", "idle", false, false, false)
    MakePlacer("common/playerhouse_city_placer", "pig_house_sale", "pig_house_sale", "idle", nil, nil, nil, nil, nil, nil,
        placefn),
    MakePlacer("common/stone_door_placer", "portas", "portas", "pedra", nil, nil, nil, nil, nil, nil, placedoorfn),
    MakePlacer("common/plate_door_placer", "portas", "portas", "metal", nil, nil, nil, nil, nil, nil, placedoorfn),
    MakePlacer("common/organic_door_placer", "portas", "portas", "peagank", nil, nil, nil, nil, nil, nil, placedoorfn), --森林
    MakePlacer("common/round_door_placer", "portas", "portas", "pano", nil, nil, nil, nil, nil, nil, placedoorfn)       ---原木
