local assets =
{
    Asset("ANIM", "anim/key_to_city.zip"),
    Asset("INV_IMAGE", "key_to_city"),
}

local function OnTurnOn(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_run", "sound")
end

local function OnTurnOff(inst)
    inst:DoTaskInTime(1.5, function()
        inst.SoundEmitter:KillSound("sound")
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_ding", "sound")
    end)
end

local function storeincontainer(inst, container)
    if container ~= nil and container.components.container ~= nil then
        inst:ListenForEvent("onputininventory", inst._oncontainerownerchanged, container)
        inst:ListenForEvent("ondropped", inst._oncontainerownerchanged, container)
        inst:ListenForEvent("onremove", inst._oncontainerremoved, container)
        inst._container = container
    end
end

local function unstore(inst)
    if inst._container ~= nil then
        inst:RemoveEventCallback("onputininventory", inst._oncontainerownerchanged, inst._container)
        inst:RemoveEventCallback("ondropped", inst._oncontainerownerchanged, inst._container)
        inst:RemoveEventCallback("onremove", inst._oncontainerremoved, inst._container)
        inst._container = nil
    end
end

local function tostore(inst, owner)
    if inst._container ~= owner then
        unstore(inst)
        storeincontainer(inst, owner)
    end
    owner = owner.components.inventoryitem ~= nil and owner.components.inventoryitem:GetGrandOwner() or owner
    if inst._owner ~= owner then
        inst._owner = owner
        inst.icon.entity:SetParent(owner.entity)
    end
end

local function topocket(inst, owner)
    tostore(inst, owner)
end

local function toground(inst)
    unstore(inst)
    inst._owner = nil
    inst.icon.entity:SetParent(inst.entity)
end

local function OnRemoveEntity(inst)
    unstore(inst)
    if inst.icon ~= nil then
        inst.icon:Remove()
        inst.icon = nil
    end
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("keytocity")
    inst.AnimState:SetBuild("key_to_city")
    inst:AddTag("prototyper")
    inst:AddTag("exterior_prototyper")
    inst:AddTag("irreplaceable")

    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._owner = nil
    inst._container = nil

    inst._oncontainerownerchanged = function(container)
        tostore(inst, container)
    end

    inst._oncontainerremoved = function()
        unstore(inst)
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst.icon = SpawnPrefab("key_to_city_icon")
    inst.icon.entity:SetParent(inst.entity)
    inst.OnRemoveEntity = OnRemoveEntity
    inst:ListenForEvent("onputininventory", topocket)
    inst:ListenForEvent("ondropped", toground)

    inst:AddComponent("prototyper")
    inst.components.prototyper.onturnon = OnTurnOn
    inst.components.prototyper.onturnoff = OnTurnOff
    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.CITY_TWO

    return inst
end

local function icon_init(inst)
    inst.icon = SpawnPrefab("globalmapicon")
    inst.icon.MiniMapEntity:SetPriority(11)
    if inst.icon.TrackEntity then
        inst.icon:TrackEntity(inst) ----按理来说这个函数肯定存在的，但是却找不到
    end
end

local function iconfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("key_to_city.tex")
    inst.MiniMapEntity:SetPriority(11)
    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)

    inst:AddTag("CLASSIFIED")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.icon = nil
    inst:DoTaskInTime(0, icon_init)
    inst.OnRemoveEntity = OnRemoveEntity
    inst.persists = false

    return inst
end

return Prefab("common/inventory/key_to_city", fn, assets),
    Prefab("key_to_city_icon", iconfn)
