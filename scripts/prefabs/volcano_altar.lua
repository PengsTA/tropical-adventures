local MAX_OFFERINGS = TUNING.VOLCANO_ALTAR_MAXAPPEASEMENTS or 5
local ClimateProfiles = require("tools/climateprofiles")
local GetOfferValue = require("tools/volcano_offerings").GetValue
local APPEASED_ANIMATION_TIME = 2
local WRATH_ANIMATION_TIME = 1

local STATE_CLOSED = 0
local STATE_OPEN = 1
local STATE_APPEASED = 2
local STATE_WRATH = 3

local assets = {
    Asset("ANIM", "anim/altar_meter.zip"),
    Asset("ANIM", "anim/volcano_altar_fx.zip"),
    Asset("ANIM", "anim/volcano_altar.zip"),
}

local function SetAnimation(animstate, state)
    if state == STATE_OPEN then
        animstate:PlayAnimation("open")
        animstate:PushAnimation("idle_open", true)
    elseif state == STATE_APPEASED then
        animstate:PlayAnimation("appeased_pre")
        animstate:PushAnimation("appeased")
        animstate:PushAnimation("appeased_pst", false)
    elseif state == STATE_WRATH then
        animstate:PlayAnimation("unappeased")
    else
        animstate:PlayAnimation("idle_close", true)
    end
end

local function UpdateVisualState(inst)
    local state = inst._altarstate:value()
    SetAnimation(inst.AnimState, state)
    if inst._tower ~= nil then
        SetAnimation(inst._tower.AnimState, state)
    end
    inst.Light:Enable(state ~= STATE_CLOSED)
end

local function UpdateMeterVisual(inst)
    if inst._meter ~= nil then
        inst._meter.AnimState:SetPercent("meter", inst._meterpercent:value() / 100)
    end
end

local function CreateTower(inst)
    if TheNet:IsDedicated() then
        return
    end

    local tower = CreateEntity()
    tower.entity:AddTransform()
    tower.entity:AddAnimState()
    tower.AnimState:SetBank("volcano_altar")
    tower.AnimState:SetBuild("volcano_altar")
    tower.AnimState:PlayAnimation("idle_close", true)
    tower.AnimState:SetFinalOffset(0)
    tower.entity:SetParent(inst.entity)
    inst._tower = tower
end

local function CreateMeter(inst)
    if TheNet:IsDedicated() then
        return
    end

    local meter = CreateEntity()
    meter.entity:AddTransform()
    meter.entity:AddAnimState()
    meter.AnimState:SetBank("volcano_altar")
    meter.AnimState:SetBuild("volcano_altar")
    meter.AnimState:PlayAnimation("meter")
    meter.AnimState:SetFinalOffset(1)
    meter.entity:SetParent(inst.entity)
    inst._meter = meter
    UpdateMeterVisual(inst)
end

local function GetVolcanoManager()
    return TheWorld ~= nil and TheWorld.components.volcanomanager or nil
end

local function CanOffer(inst, item)
    local manager = GetVolcanoManager()
    return manager ~= nil
        and ClimateProfiles.IsShipwreckedDry(TheWorld.state)
        and manager:IsActive()
        and manager:GetTimeUntilEruption() ~= nil
        and not manager:IsFireRaining()
        and inst._offeringcount:value() < MAX_OFFERINGS
        and (item == nil or GetOfferValue(item) ~= nil)
end

local function SetAltarState(inst, state)
    if inst._altarstate:value() ~= state then
        inst._altarstate:set(state)
    end
    UpdateVisualState(inst)
end

local function UpdateMeter(inst)
    local manager = GetVolcanoManager()
    local percent = 0
    if manager ~= nil and manager:IsFireRaining() then
        percent = 1
    elseif manager ~= nil and manager:IsActive() then
        local remaining = manager:GetTimeUntilEruption()
        local duration = manager:GetEruptionCycleDuration()
        if remaining ~= nil and duration ~= nil and duration > 0 then
            percent = math.max(0, math.min(1, 1 - remaining / duration))
        end
    end

    local value = math.floor(percent * 100 + .5)
    if inst._meterpercent:value() ~= value then
        inst._meterpercent:set(value)
    end
    UpdateMeterVisual(inst)
end

local function CancelStateReset(inst)
    if inst._stateresettask ~= nil then
        inst._stateresettask:Cancel()
        inst._stateresettask = nil
    end
end

local function RefreshAltar(inst)
    local manager = GetVolcanoManager()
    if manager == nil or not ClimateProfiles.IsShipwreckedDry(TheWorld.state) then
        if inst._offeringcount:value() ~= 0 then
            inst._offeringcount:set(0)
        end
    end

    local open = CanOffer(inst)
    if inst.components.trader ~= nil then
        if open then
            inst.components.trader:Enable()
        else
            inst.components.trader:Disable()
        end
    end
    SetAltarState(inst, open and STATE_OPEN or STATE_CLOSED)
    UpdateMeter(inst)
end

local function QueueStateReset(inst, state, duration)
    CancelStateReset(inst)
    SetAltarState(inst, state)
    inst._stateresettask = inst:DoTaskInTime(duration, function()
        inst._stateresettask = nil
        RefreshAltar(inst)
    end)
end

local function OnAccept(inst, giver, item)
    local manager = GetVolcanoManager()
    local value = GetOfferValue(item)
    if manager == nil or value == nil or not manager:Appease(value) then
        return
    end

    if value > 0 then
        inst._offeringcount:set(inst._offeringcount:value() + 1)
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/volcano_alter/splash")
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/volcano_alter/appeased")
        QueueStateReset(inst, STATE_APPEASED, APPEASED_ANIMATION_TIME)
    else
        if giver ~= nil and giver.components.health ~= nil then
            giver.components.health:DoFireDamage(TUNING.VOLCANO_ALTAR_DAMAGE, inst, true)
        end
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/volcano_alter/unappeased")
        if manager:IsFireRaining() then
            RefreshAltar(inst)
        else
            QueueStateReset(inst, STATE_WRATH, WRATH_ANIMATION_TIME)
        end
    end

    inst:PushEvent("volcanoaltaroffering", { giver = giver, value = value })
end

local function GetStatus(inst)
    return CanOffer(inst) and "OPEN" or nil
end

local function OnSave(inst, data)
    data.offeringcount = inst._offeringcount:value()
end

local function OnLoad(inst, data)
    if data ~= nil and data.offeringcount ~= nil then
        inst._offeringcount:set(math.min(data.offeringcount, MAX_OFFERINGS))
    end
    inst:DoTaskInTime(0, RefreshAltar)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    MakeObstaclePhysics(inst, 2, 1.2)

    inst.AnimState:SetBank("volcano_altar_fx")
    inst.AnimState:SetBuild("volcano_altar_fx")
    inst.AnimState:SetFinalOffset(2)

    inst.Light:SetIntensity(.75)
    inst.Light:SetColour(197 / 255, 197 / 255, 50 / 255)
    inst.Light:SetFalloff(.5)
    inst.Light:SetRadius(2)
    inst.Light:Enable(false)

    inst._altarstate = net_tinybyte(inst.GUID, "volcanoaltar.state", "volcanoaltarstatedirty")
    inst._offeringcount = net_tinybyte(inst.GUID, "volcanoaltar.offeringcount")
    inst._meterpercent = net_byte(inst.GUID, "volcanoaltar.meterpercent", "volcanoaltarmeterdirty")
    inst._meterpercent:set_local(0)

    inst:AddTag("altar")
    inst:AddTag("structure")
    inst:AddTag("stone")
    inst:AddTag("trader")
    inst:AddTag("alltrader")

    inst:ListenForEvent("volcanoaltarstatedirty", UpdateVisualState)
    inst:ListenForEvent("volcanoaltarmeterdirty", UpdateMeterVisual)
    CreateTower(inst)
    CreateMeter(inst)
    inst:DoTaskInTime(0, UpdateVisualState)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("trader")
    inst.components.trader.acceptnontradable = true
    inst.components.trader:SetAcceptTest(CanOffer)
    inst.components.trader.onaccept = OnAccept
    inst.components.trader:Disable()

    local function RefreshFromWorld()
        RefreshAltar(inst)
    end
    inst:ListenForEvent("volcanoactivechanged", RefreshFromWorld, TheWorld)
    inst:ListenForEvent("volcanoeruptionbegin", RefreshFromWorld, TheWorld)
    inst:ListenForEvent("volcanoeruptionend", RefreshFromWorld, TheWorld)
    inst:ListenForEvent("volcanoeruptionrescheduled", RefreshFromWorld, TheWorld)
    inst:WatchWorldState("season", RefreshFromWorld)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst._metertask = inst:DoPeriodicTask(5, function()
        UpdateMeter(inst)
    end)
    inst:DoTaskInTime(0, RefreshAltar)

    return inst
end

return Prefab("volcano_altar", fn, assets)
