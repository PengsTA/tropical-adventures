-------------一个冰雹没法沉到水里去,两个以上就可以，为啥呢
local assets =
{
    Asset("ANIM", "anim/hail.zip"),
}

local names = { "variant1", "variant2", "variant3" }

local function onsave(inst, data)
    data.anim = inst.animname
end

local function onload(inst, data)
    if data and data.anim then
        inst.animname = data.anim
        inst.AnimState:PlayAnimation(inst.animname)
    end
end

local function onperish(inst)
    local owner = inst.components.inventoryitem.owner
    if owner ~= nil then
        local stacksize = inst.components.stackable:StackSize()
        if owner.components.moisture ~= nil then
            owner.components.moisture:DoDelta(2 * stacksize)
        elseif owner.components.inventoryitem ~= nil then
            owner.components.inventoryitem:AddMoisture(4 * stacksize)
        end
        inst:Remove()
    else
        local stacksize = inst.components.stackable:StackSize()
        local x, y, z = inst.Transform:GetWorldPosition()
        TheWorld.components.farming_manager:AddSoilMoistureAtPoint(x, y, z,
            stacksize * TUNING.ICE_MELT_GROUND_MOISTURE_AMOUNT)

        inst.persists = false
        inst.components.inventoryitem.canbepickedup = false
        inst.AnimState:PlayAnimation("melt")
        inst:ListenForEvent("animover", inst.Remove)
    end
end

local function onfiremelt(inst)
    inst.components.perishable.frozenfiremult = true
end

local function onstopfiremelt(inst)
    inst.components.perishable.frozenfiremult = false
end

local function playfallsound(inst)
    local ice_fall_sound =
    {
        [GROUND.BEACH] = "dontstarve_DLC002/common/ice_fall_beach",
        [GROUND.JUNGLE] = "dontstarve_DLC002/common/ice_fall_jungle",
        [GROUND.TIDALMARSH] = "dontstarve_DLC002/common/ice_fall_marsh",
        [GROUND.MAGMAFIELD] = "dontstarve_DLC002/common/ice_fall_rocks",
        [GROUND.MEADOW] = "dontstarve_DLC002/common/ice_fall_grass",
        [GROUND.VOLCANO] = "dontstarve_DLC002/common/ice_fall_rocks",
        [GROUND.ASH] = "dontstarve_DLC002/common/ice_fall_rocks",
    }

    local tile = inst:GetCurrentTileType()
    if ice_fall_sound[tile] ~= nil then
        inst.SoundEmitter:PlaySound(ice_fall_sound[tile])
    else
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/ice_fall_beach")
    end
end

local function onhitground_hail(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst:RemoveEventCallback("on_landed", onhitground_hail)
    MakeInventoryPhysics(inst)
    inst.components.inventoryitem.canbepickedup = true

    if TheWorld.Map:IsOceanAtPoint(x, y, z) and inst:GetCurrentPlatform() == nil then
        local splash = SpawnPrefab("frogsplash")
        if splash ~= nil then
            splash.Transform:SetPosition(x, y, z)
        end
        inst:Remove()
    elseif math.random() < TUNING.HURRICANE_HAIL_BREAK_CHANCE then
        inst:Remove()
    else
        playfallsound(inst)
    end
end

local function StartFalling(inst, x, y, z)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:Teleport(x, y or 35, z)
    inst.components.inventoryitem.canbepickedup = false
    inst:ListenForEvent("on_landed", onhitground_hail)
    inst.components.inventoryitem:SetLanded(false, true)
end

local function hailfn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)
    inst.entity:AddNetwork()
    --inst.Transform:SetScale(1.5, 1.5, 1.5)

    inst.AnimState:SetBank("hail")
    inst.AnimState:SetBuild("hail")
    inst.animname = names[math.random(#names)]
    inst.AnimState:PlayAnimation(inst.animname)

    --MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("smotherer")

    inst:AddTag("frozen")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "ELEMENTAL"
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY / 8
    inst.components.edible.degrades_with_spoilage = false
    inst.components.edible.temperaturedelta = TUNING.COLD_FOOD_BONUS_TEMP
    inst.components.edible.temperatureduration = TUNING.FOOD_TEMP_BRIEF * 1.5

    inst:ListenForEvent("firemelt", onfiremelt)
    inst:ListenForEvent("stopfiremelt", onstopfiremelt)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_ONE_DAY)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(onperish)

    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")


    inst.components.inventoryitem:SetOnPickupFn(onstopfiremelt)

    inst.StartFalling = StartFalling
    inst.OnSave = onsave
    inst.OnLoad = onload
    MakeHauntableLaunchAndSmash(inst)
    inst:AddComponent("bait")
    inst:AddTag("molebait")
    return inst
end

return Prefab("common/inventory/hail_ice", hailfn, assets)
