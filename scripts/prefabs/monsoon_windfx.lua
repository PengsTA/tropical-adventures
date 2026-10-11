local assets = {
    Asset("ANIM", "anim/wind_fx.zip"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.entity:SetCanSleep(false)
    inst.AnimState:SetBuild("wind_fx")
    inst.AnimState:SetBank("wind_fx")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:PlayAnimation("side_wind_loop")

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

return Prefab("monsoon_windfx", fn, assets)
