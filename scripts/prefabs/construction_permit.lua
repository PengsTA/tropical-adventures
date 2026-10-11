local assets = {
    Asset("ANIM", "anim/permit_reno.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.15, 0.9)

    inst.AnimState:SetBank("permit_reno")
    inst.AnimState:SetBuild("permit_reno")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.foleysound = "dontstarve/movement/foley/jewlery"
    inst:AddComponent("tradable")

    return inst
end

return Prefab("construction_permit", fn, assets)
