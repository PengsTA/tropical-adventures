require("derives")

local assets =
{
    Asset("ANIM", "anim/poison_antidote.zip"),
    Asset("ANIM", "anim/poison_salve.zip"),
    Asset("ANIM", "anim/venom_gland.zip"),
    Asset("ANIM", "anim/snakeoil.zip"),
}

local MAX_VENOM_GLAND_DAMAGE = 80
local MIN_VENOM_GLAND_LEFTOVER = 5

local function oneat(inst, eater)
    return TroRemovePoison(eater, TUNING.TOTAL_DAY_TIME / 2)
end

local function oneat_anti(inst, eater)
    if not oneat(inst, eater) or not eater:HasTag("player") then return end
    eater.AnimState:PlayAnimation("research")
end

local function oneat_gland(inst, eater)
    if not oneat(inst, eater) then return end
    local health = eater.components.health
    if not health then return end
    health:DoDelta(health.currenthealth - MIN_VENOM_GLAND_LEFTOVER < MAX_VENOM_GLAND_DAMAGE and
                   MIN_VENOM_GLAND_LEFTOVER - health.currenthealth or -MAX_VENOM_GLAND_DAMAGE, nil, "venomgland")
end

local function oneat_oil(inst, eater)
    eater.SoundEmitter:PlaySound("dontstarve_DLC002/common/HUD_antivenom_use")
    eater.AnimState:PlayAnimation("research")
    inst.removebyused = true
end

local function syrumpost(inst)
    inst.AnimState:SetBank("poison_antidote")
    inst.AnimState:SetBuild("poison_antidote")
    inst:AddTag("aquatic")
    inst:AddTag("preparedfood")
    inst:AddTag("healerbuffs")

    if not TheWorld.ismastersim then return inst end

    local healer = inst.components.healer or inst:AddComponent("healer")
    healer:SetHealthAmount(0)
    healer:SetOnHealFn(oneat_anti)

    return inst
end

local function balmpost(inst)
    inst.AnimState:SetBank("poison_salve")
    inst.AnimState:SetBuild("poison_salve")
    inst:AddTag("aquatic")
    inst:AddTag("preparedfood")
    inst:AddTag("healerbuffs")

    if not TheWorld.ismastersim then return inst end

    local healer = inst.components.healer or inst:AddComponent("healer")
    healer:SetHealthAmount(0)
    healer:SetOnHealFn(oneat_anti)

    return inst
end

local function glandpost(inst)
    inst.AnimState:SetBank("venom_gland")
    inst.AnimState:SetBuild("venom_gland")

    if not TheWorld.ismastersim then return inst end

    local healer = inst.components.healer or inst:AddComponent("healer")
    healer:SetHealthAmount(0)
    healer:SetOnHealFn(oneat_gland)

    return inst
end

local function oilpost(inst)
    inst.AnimState:SetBank("snakeoil")
    inst.AnimState:SetBuild("snakeoil")
    inst:AddTag("healerbuffs")

    if not TheWorld.ismastersim then return inst end

    inst:RemoveComponent("stackable")

    local healer = inst.components.healer or inst:AddComponent("healer")
    healer:SetHealthAmount(0)
    healer:SetOnHealFn(oneat_oil)

    local fuel = inst.components.fuel or inst:AddComponent("fuel")
    fuel.fuelvalue = 0

    local Remove = inst.Remove
    inst.Remove = function(inst)
        local remove = not inst.removebyused
        inst.removebyused = nil
        return remove and Remove(inst)
    end

    return inst
end

return Derive("bandage", "antivenom", syrumpost, assets),
    Derive("bandage", "poisonbalm", balmpost, assets),
    Derive("spidergland", "venomgland", glandpost, assets),
    Derive("spidergland", "snakeoil", oilpost, assets)