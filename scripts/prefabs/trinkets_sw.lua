local function MakeTrinket(num)
    local name = "trinket_sw_" .. tostring(num)
    local prefabname = "common/inventory/" .. name

    local assets =
    {
        Asset("ANIM", "anim/trinkets_sw.zip"),
    }

    local function fn(Sim)
        local inst = CreateEntity()
        inst.entity:AddNetwork()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)

        inst.AnimState:SetBank("trinkets_sw")
        inst.AnimState:SetBuild("trinkets_sw")
        inst.AnimState:PlayAnimation(tostring(num))

        inst:AddTag("molebait")
        inst:AddTag("cattoy")
        inst:AddTag("trinket")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end


        inst:AddComponent("inspectable")
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("tradable")
        inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.TRINKETS[num] or 3

        inst:AddComponent("inventoryitem")

        inst:AddComponent("bait")

        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab(prefabname, fn, assets)
end

local function seaworther_fn()
    local inst = CreateEntity()
    inst.entity:AddNetwork()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("trinkets_sw")
    inst.AnimState:SetBuild("trinkets_sw")
    inst.AnimState:PlayAnimation("12")

    inst:AddTag("molebait")
    inst:AddTag("cattoy")
    inst:AddTag("trinket")
    inst:AddTag("irreplaceable")
    --inst:AddTag("nonpotatable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 1

    inst:AddComponent("inventoryitem")

    inst:AddComponent("bait")

    MakeHauntableLaunch(inst)

    return inst
end

local NUM_TRINKETS_SW = 23
local ret = {}
for k =13,NUM_TRINKETS_SW do
    table.insert(ret, MakeTrinket(k))
end

table.insert(ret, Prefab("sunken_boat_trinket_4", seaworther_fn, assets))

return unpack(ret)
