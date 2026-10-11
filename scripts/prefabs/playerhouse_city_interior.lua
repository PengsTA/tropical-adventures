require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/pig_shop_doormats.zip"),
}

local function OnDoneTeleporting(inst, obj)
    if obj ~= nil and obj:HasTag("player") and inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_close")
    end
end

local function OnActivate(inst, doer)
    if doer ~= nil and doer:HasTag("player") and doer.SoundEmitter ~= nil then
        doer.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_open")
    end
    if inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/store/door_open")
    end
end

local function OnAccept(inst, giver, item)
    inst.components.inventory:DropItem(item)
    inst.components.teleporter:Activate(item)
end

local function OnHaunt(inst, haunter)
    inst.components.teleporter:Activate(haunter)
end

local function DoorMatFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("vamp_bat_cave.tex")

    inst.AnimState:SetBank("pig_shop_doormats")
    inst.AnimState:SetBuild("pig_shop_doormats")
    inst.AnimState:PlayAnimation("idle_old")
    inst.Transform:SetRotation(90)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)

    inst:AddTag("trader")
    inst:AddTag("alltrader")
    inst:AddTag("guard_entrance")
    inst:AddTag("hamletteleport")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("trader")
    inst.components.trader.acceptnontradable = true
    inst.components.trader.onaccept = OnAccept
    inst.components.trader.deleteitemonaccept = false

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate = OnActivate
    inst.components.teleporter.offset = 0
    inst.components.teleporter.hamlet = true
    inst.components.teleporter.travelcameratime = 0.2
    inst.components.teleporter.travelarrivetime = 0.1
    inst:ListenForEvent("doneteleporting", OnDoneTeleporting)

    inst:AddComponent("inventory")
    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    return inst
end

return Prefab("playerhouse_city_door_saida", DoorMatFn, assets)
