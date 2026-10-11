local assets =
{
    Asset("ANIM", "anim/earring.zip"),
}

--common to all gold prefabs below
local function shine(inst)
	inst.shinetask = nil
    if not inst.AnimState:IsCurrentAnimation("sparkle") then
        inst.AnimState:PlayAnimation("sparkle")
        inst.AnimState:PushAnimation("idle", false)
    end
	if not inst:IsAsleep() then
		inst.shinetask = inst:DoTaskInTime(4 + math.random() * 5, shine)
	end
end

--common to all gold prefabs below
local function OnEntityWake(inst)
	if inst.shinetask == nil then
		inst.shinetask = inst:DoTaskInTime(4 + math.random() * 5, shine)
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.AnimState:SetBank("earring")
    inst.AnimState:SetBuild("earring")
    inst.AnimState:PlayAnimation("idle")

    --inst:AddTag("molebait")
    --inst:AddTag("cattoy")
    inst:AddTag("trinket")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("inspectable")
    inst:AddComponent("stackable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 3
    --inst.components.tradable.dubloonvalue = 12


    MakeHauntableLaunch(inst)

    shine(inst)
	inst.OnEntityWake = OnEntityWake

    return inst
end

return Prefab("earring", fn, assets)
