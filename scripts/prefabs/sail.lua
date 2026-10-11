local assets =
{
    Asset("ANIM", "anim/swap_sail.zip"),
    Asset("ANIM", "anim/swap_sail_cloth.zip"),
    Asset("ANIM", "anim/swap_sail_malbatro.zip"),
    Asset("ANIM", "anim/swap_sail_feathers.zip"),
    Asset("ANIM", "anim/swap_sail_snakeskin.zip"),
    Asset("ANIM", "anim/swap_propeller.zip"),
    Asset("ANIM", "anim/swap_sail_pirate.zip"),
}

local BoatEquip = require("tools/boat_equipment_helper")

local total_day_time = 480

local SAIL_SPEED_MULT = 0.2
local SAIL_ACCEL_MULT = 0
local SAIL_PERISH_TIME = total_day_time * 2

local CLOTH_SAIL_SPEED_MULT = 0.3
local CLOTH_SAIL_ACCEL_MULT = 0.5
local CLOTH_SAIL_PERISH_TIME = total_day_time * 3

local SNAKESKIN_SAIL_SPEED_MULT = 0.25
local SNAKESKIN_SAIL_ACCEL_MULT = 0.25
local SNAKESKIN_SAIL_PERISH_TIME = total_day_time * 4

local FEATHER_SAIL_SPEED_MULT = 0.4
local FEATHER_SAIL_ACCEL_MULT = 1
local FEATHER_SAIL_PERISH_TIME = total_day_time * 2

local IRON_WIND_SPEED_MULT = 0.5
local IRON_WIND_ACCEL_MULT = 2
local IRON_WIND_PERISH_TIME = total_day_time * 4

local WOODLEGS_SAIL_ACCEL_MULT = -0.5

local function DetachFromBoat(inst)
    local boat = BoatEquip.GetItemBoat(inst)
    if boat ~= nil then
        boat.AnimState:ClearOverrideSymbol(inst.symboltooverride, inst.build, inst.symbol)
    end
    BoatEquip.ClearItemBoatState(inst)
    if inst.components.fueled then
        inst.components.fueled:StopConsuming()
    end
end

local function OnSailDepleted(inst)
    if inst.components.inventoryitem and inst.components.inventoryitem.owner then
        inst.components.inventoryitem.owner.AnimState:ClearOverrideSymbol(inst.symboltooverride)
    end
    inst:Remove()
end

local SAIL_DEFS = {
    sail = {
        build = "swap_sail",
        speed_mult = SAIL_SPEED_MULT,
        accel_mult = SAIL_ACCEL_MULT,
        perish_time = SAIL_PERISH_TIME,
        loopsound = "common/sail_LP_leaf",
        flapsound = "common/sail_flap_leaf",
        sail_sound = "dontstarve_DLC002/common/sail_LP_leaf",
    },
    clothsail = {
        build = "swap_sail_cloth",
        speed_mult = CLOTH_SAIL_SPEED_MULT,
        accel_mult = CLOTH_SAIL_ACCEL_MULT,
        perish_time = CLOTH_SAIL_PERISH_TIME,
        loopsound = "common/sail_LP_cloth",
        flapsound = "common/sail_flap_cloth",
        sail_sound = "dontstarve_DLC002/common/sail_LP_cloth",
    },
    snakeskinsail = {
        build = "swap_sail_snakeskin",
        speed_mult = SNAKESKIN_SAIL_SPEED_MULT,
        accel_mult = SNAKESKIN_SAIL_ACCEL_MULT,
        perish_time = SNAKESKIN_SAIL_PERISH_TIME,
        loopsound = "common/sail_LP_snakeskin",
        flapsound = "common/sail_flap_snakeskin",
        sail_sound = "dontstarve_DLC002/common/sail_LP_snakeskin",
    },
    feathersail = {
        build = "swap_sail_feathers",
        speed_mult = FEATHER_SAIL_SPEED_MULT,
        accel_mult = FEATHER_SAIL_ACCEL_MULT,
        perish_time = FEATHER_SAIL_PERISH_TIME,
        loopsound = "common/sail_LP_feather",
        flapsound = "common/sail_flap_feather",
        sail_sound = "dontstarve_DLC002/common/sail_LP_feather",
    },
    ironwind = {
        bank = "propeller",
        build = "swap_propeller",
        symbol = "swap_propeller",
        speed_mult = IRON_WIND_SPEED_MULT,
        accel_mult = IRON_WIND_ACCEL_MULT,
        perish_time = IRON_WIND_PERISH_TIME,
        loopsound = "common/boatpropellor_lp",
        sail_sound = "dontstarve_DLC002/common/boatpropellor_lp",
        fueltype = "REPARODEBARCO",
        accepting_fuel = true,
        showPropFX = true,
        has_interactions = true,
    },
    woodlegssail = {
        build = "swap_sail_pirate",
        anim = "anim",
        speed_mult = 0,
        accel_mult = WOODLEGS_SAIL_ACCEL_MULT,
        loopsound = "common/sail_LP_sealegs",
        flapsound = "common/sail_flap_sealegs",
        sail_sound = "dontstarve_DLC002/common/sail_LP_sealegs",
        remove_on_unequip = true,
        no_fuel = true,
    },
    malbatrossail = {
        build = "swap_sail_malbatro",
        speed_mult = CLOTH_SAIL_SPEED_MULT,
        accel_mult = CLOTH_SAIL_ACCEL_MULT,
        perish_time = CLOTH_SAIL_PERISH_TIME,
        loopsound = "common/sail_LP_cloth",
        flapsound = "common/sail_flap_cloth",
        sail_sound = "dontstarve_DLC002/common/sail_LP_cloth",
    },
}

local function ConfigureFuel(inst, def)
    if def.no_fuel then
        return
    end

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = def.fueltype or "USAGE"
    inst.components.fueled:SetDepletedFn(OnSailDepleted)

    if def.perish_time then
        inst.components.fueled:InitializeFuelLevel(def.perish_time)
    end

    if def.accepting_fuel then
        inst.components.fueled.accepting = true
    end
end

local function MakeSailFn(name, def)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.boat_consumes_while_sailing = not def.no_fuel

        MakeInventoryPhysics(inst)

        inst.build = def.build
        inst.symbol = def.symbol or "swap_sail"
        inst.symboltooverride = def.symbol or "swap_sail"
        inst.showPropFX = def.showPropFX

        inst.AnimState:SetBank(def.bank or "sail")
        inst.AnimState:SetBuild(inst.build)
        inst.AnimState:PlayAnimation(def.anim or "idle")

        inst.sail_speed_mult = def.speed_mult
        inst.sail_accel_mult = def.accel_mult
        inst.loopsound = def.loopsound
        inst.flapsound = def.flapsound
        inst.sail_sound = def.sail_sound

        if def.remove_on_unequip then
            inst.RemoveOnUnequip = true
        end

        inst:AddTag("sail")
        MakeInventoryFloatable(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst:AddComponent("equippable")
        inst.components.equippable.boatequipslot = BOATEQUIPSLOTS.BOAT_SAIL
        inst.components.equippable.restrictedtag = "ta_boat_equipment"

        if def.has_interactions then
            inst:AddComponent("interactions")
        end

        ConfigureFuel(inst, def)

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
        inst:ListenForEvent("onpickup", DetachFromBoat)

        return inst
    end
end

local prefabs = {}

for name, def in pairs(SAIL_DEFS) do
    table.insert(prefabs, Prefab("common/inventory/" .. name, MakeSailFn(name, def), assets))
end

return unpack(prefabs)
