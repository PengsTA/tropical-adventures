require "prefabutil"

local assets = {
    Asset("ANIM", "anim/boat_hud_encrusted.zip"),
    Asset("ANIM", "anim/boat_hud_cargo.zip"),
    Asset("ANIM", "anim/boat_hud_row.zip"),
    Asset("ANIM", "anim/boat_inspect_encrusted.zip"),
    Asset("ANIM", "anim/boat_inspect_cargo.zip"),
    Asset("ANIM", "anim/boat_inspect_raft.zip"),
    Asset("ANIM", "anim/boat_inspect_row.zip"),
    Asset("ANIM", "anim/corkboat.zip"),
    Asset("ANIM", "anim/pirate_boat_build.zip"),
    Asset("ANIM", "anim/raft_basic.zip"),
    Asset("ANIM", "anim/raft_build.zip"),
    Asset("ANIM", "anim/raft_log_build.zip"),
    Asset("ANIM", "anim/raft_surfboard_build.zip"),
    Asset("ANIM", "anim/rowboat_armored_build.zip"),
    Asset("ANIM", "anim/rowboat_basic.zip"),
    Asset("ANIM", "anim/rowboat_build.zip"),
    Asset("ANIM", "anim/rowboat_cargo_build.zip"),
    Asset("ANIM", "anim/rowboat_encrusted_build.zip"),
    Asset("ANIM", "anim/swap_lantern_boat.zip"),
    Asset("ANIM", "anim/swap_sail.zip"),
    Asset("ANIM", "anim/waxwell_shadowboat_build.zip"),
}

local BASE_TAGS = {
    "boatsw",
    "aquatic",
    "sailable",
    "ignorewalkableplatforms",
    "outofreach",
}

local function OnLoad(inst, data)
    inst:DoTaskInTime(0, function(inst)
        local owner = inst.components.inventoryitem.owner
        if owner ~= nil and owner.components.inventory ~= nil and owner.components.sailor ~= nil then
            owner.components.inventory:DropItem(inst)
            owner.components.sailor:BoatJump(inst)
        end
    end)
end

local function GetPercentUsed(inst)
    if inst.percentused and inst.percentused:value() ~= 255 then
        return inst.percentused:value() / 100
    end
    return 0
end

local function SetPercentUsed(inst, data)
    if inst.percentused and data and data.percent then
        local percent = data.percent
        inst.percentused:set((percent == nil and 255) or (percent <= 0 and 0) or
            math.clamp(math.floor(percent * 100 + .5), 1, 100))
    end
end

local function OnBoatHealthChanged(inst, data)
    if data ~= nil then
        SetPercentUsed(inst, data)
    end
end

local function OnBoatImpact(inst)
    local fx = SpawnPrefab("boat_hit_fx_quackeringram")
    if fx ~= nil then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx.Transform:SetRotation(inst.Transform:GetRotation())
    end
end

local function OnHammered(inst)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end
    SpawnAt("collapse_small", inst)
    for _, v in ipairs(inst.loottable or {}) do
        Launch(SpawnAt(v, inst), inst, 1)
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst.components.container:DropEverything()
    inst:Remove()
end

local function OnCollapsed(inst)
    local collapse = SpawnAt(inst.collapse, inst)
    SpawnAt("collapse_small", inst)
    if not inst.components.container or inst.components.container:IsEmpty() then
        inst:Remove()
        if collapse and collapse.components.pickable then
            collapse.components.pickable.canbepicked = false
        end
        return
    end
    collapse:SetChest(inst)
end

local function AddTags(inst, tags)
    for _, tag in ipairs(tags or {}) do
        inst:AddTag(tag)
    end
end

local function ConfigureBoatHealth(inst, config)
    inst:AddComponent("boathealth")
    inst.components.boathealth:SetMaxHealth(config.maxuses)
    inst.components.boathealth:SetHealth(config.maxuses)
    inst.components.boathealth.rate = (config.useamount or 0) * 30
    inst.components.boathealth:SetDepletedFn(function()
        if inst:IsValid() and inst.OnCollapse ~= nil then
            local sailor = inst.components.sailable ~= nil and inst.components.sailable:GetSailor() or nil
            if sailor ~= nil and sailor.components.sailor ~= nil then
                sailor.components.sailor:Disembark(nil, true)
            end
            inst:OnCollapse()
        end
    end)
end

local function ConfigureServerBoat(inst, config)
    inst:AddComponent("interactions")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(OnHammered)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.canbepickedup = false

    inst:AddComponent("container")
    inst.components.container:WidgetSetup(config.name or "rowboat")

    inst:AddComponent("boatequipment")
    inst:AddComponent("sailable")
    ConfigureBoatHealth(inst, config)

    inst:ListenForEvent("boathealthchange", OnBoatHealthChanged)
    inst:ListenForEvent("boatimpact", OnBoatImpact)

    inst.OnCollapse = OnCollapsed
    inst.OnHammer = OnHammered
    inst.OnLoad = OnLoad

    inst.collapse = config.collapse
    inst.loottable = config.loottable
    inst.SetPercentUsed = SetPercentUsed

    AddTags(inst, config.tags)

    if config.postfn then
        config.postfn(inst)
    end
end

local function makeBoatFn(config)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.Transform:SetFourFaced()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(config.bank or "rowboat")
        inst.banc = config.bank or "rowboat"
        inst.AnimState:SetBuild(config.build)
        inst.AnimState:PlayAnimation("run_loop", true)
        inst.overridebuild = config.build

        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon(config.icon)

        MakeWaterObstaclePhysics(inst, 0.5, 2, 1.25)
        inst:SetPhysicsRadiusOverride(0.5)
        AddTags(inst, BASE_TAGS)

        inst.percentused = net_byte(inst.GUID, "boatrow._percentused", "boatrow._percentuseddirty")
        inst.percentused:set_local(100)
        inst.GetPercentUsed = GetPercentUsed

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        ConfigureServerBoat(inst, config)

        return inst
    end
end

local prefabs = {}

for _, boat in pairs(require("datadefs/boat_defs")) do
    table.insert(prefabs, Prefab(boat.name, makeBoatFn(boat), assets))
end

return unpack(prefabs)
