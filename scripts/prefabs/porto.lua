require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/boat_hud_raft.zip"),
    Asset("ANIM", "anim/coracle_boat_build.zip"),
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
    Asset("ANIM", "anim/seafarer_boatsw.zip"),
    Asset("ANIM", "anim/surfboard.zip"),
}

local function OnDeploy(boatname, postfn)
    local function GetItemHealth(inst)
        if inst == nil then
            return nil
        end
        if inst.boat_item_health ~= nil then
            return inst.boat_item_health
        end
        local finiteuses = inst.components ~= nil and inst.components.finiteuses or nil
        return finiteuses ~= nil and (finiteuses.current or (finiteuses.GetUses ~= nil and finiteuses:GetUses())) or nil
    end

    return function(inst, pt, deployer)
        pt.y = 0
        local boat = SpawnAt(boatname, pt)
        if boat ~= nil and boat.components.boathealth ~= nil then
            local health = GetItemHealth(inst)
            if health ~= nil then
                boat.components.boathealth:SetCurrentHealth(health)
            end
        end
        if postfn then postfn(boat) end
        inst:Remove()
    end
end

local prefabs = {}

for name, data in pairs(require("datadefs/boatporto_defs")) do
    table.insert(prefabs, Prefab(name, function()
        local inst = CreateEntity()
        inst.entity:AddTransform()

        inst.entity:AddAnimState()
        inst.AnimState:SetBank(data.bank)
        inst.AnimState:SetBuild(data.build)
        inst.AnimState:PlayAnimation(data.anim or "idle")

        inst.entity:AddNetwork()

        inst:AddTag("boatbuilder")

        MakeInventoryPhysics(inst)

        MakeInventoryFloatable(inst, "med", 0.25, 0.83)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")

        inst:AddComponent("deployable")
        inst.components.deployable.ondeploy = OnDeploy(data.prefab, data.onplace)
        inst.components.deployable:SetDeployMode(DEPLOYMODE.WATER)
        inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

        MakeLargeBurnable(inst)
        MakeLargePropagator(inst)
        MakeHauntableLaunch(inst)

        if data.postfn then data.postfn(inst) end

        return inst

    end, assets))
    table.insert(prefabs, MakePlacer(name .. "_placer", data.placer_bank, data.placer_build, "run_loop", nil, nil, nil, nil, nil, nil, data.placerpost))
end

return unpack(prefabs)
