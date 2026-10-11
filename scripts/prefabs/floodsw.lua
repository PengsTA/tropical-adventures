local assets = {
    Asset("ANIM", "anim/flood.zip"),
}

local function SetFloodLevel(inst, level)
    local scale = 0.9 + 0.7 * math.clamp(level, 0, 1)
    inst.Transform:SetScale(scale, scale, scale)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("flood")
    inst.AnimState:SetBuild("flood")
    inst.AnimState:PlayAnimation("chega")
    inst.AnimState:PushAnimation("idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("mare")
    inst:AddTag("tropical_floodwater")
    inst.persists = false

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SetFloodLevel = SetFloodLevel
    SetFloodLevel(inst, 1)

    return inst
end

return Prefab("floodsw", fn, assets)
