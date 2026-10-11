require "stategraphs/SGbermudatriangle"
local BermudaTravel = require("tools/bermuda_travel")

local assets =
{
    Asset("ANIM", "anim/bermudatriangle.zip"),
    Asset("ANIM", "anim/teleporter_worm.zip"),
    Asset("ANIM", "anim/teleporter_worm_build.zip"),
    Asset("SOUND", "sound/common.fsb"),
}
local prefabs = { "electrichitsparks" }

local function GetStatus(inst)
    return inst.sg.currentstate.name ~= "idle" and "OPEN" or nil
end

local function OnDoneTeleporting(inst, obj)
    if inst.closetask ~= nil then
        inst.closetask:Cancel()
    end
    inst.closetask = inst:DoTaskInTime(1.5, function()
        if not (BermudaTravel.IsCharging(inst) or inst.components.teleporter:IsBusy() or
                inst.components.playerprox:IsPlayerClose()) then
            inst.sg:GoToState("closing")
        end
    end)

    if obj ~= nil and obj:HasTag("player") then
        obj:DoTaskInTime(1, obj.PushEvent, "bermudatriangleexit") -- for wisecracker
    end
end

local function OnActivate(inst, doer, target)
    if doer:HasTag("player") then
        BermudaTravel.UpdatePlayer(inst, doer)

        local other = inst.components.teleporter.targetTeleporter
        if other ~= nil then
            DeleteCloseEntsWithTag({ "WORM_DANGER" }, other, 15)
        end

    elseif inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/bermudatriangle_spark", "wormhole_swallow")
    end
end

local function OnActivateByOther(inst, source, doer)
    if not inst.sg:HasStateTag("open") then
        inst.sg:GoToState("opening")
    end
end

local function onnear(inst)
    if inst.components.teleporter:IsActive() and not inst.sg:HasStateTag("open") then
        inst.sg:GoToState("opening")
    end
end

local function onfar(inst)
    if not BermudaTravel.IsCharging(inst) and not inst.components.teleporter:IsBusy() and inst.sg:HasStateTag("open") then
        inst.sg:GoToState("closing")
    end
end

local function onaccept(inst, giver, item)
    inst.components.inventory:DropItem(item)
    inst.components.teleporter:Activate(item)
end

local function StartTravelSound(inst, doer)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/bermudatriangle_spark", "wormhole_swallow")
    doer:PushEvent("wormholetravel", WORMHOLETYPE.OCEANWHIRLPORTAL) --Event for playing local travel sound
end

local function OnSave(inst, data)
    if inst.disable_sanity_drain then
        data.disable_sanity_drain = true
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.disable_sanity_drain then
        inst.disable_sanity_drain = true
    end
end

local CHECK_FOR_BOATS_PERIOD = 0.5
local TRAVEL_TAGS = { "boat", "boatsw", "sailable", "player" }
local TRAVEL_EXCLUDE = { "FX", "NOCLICK", "DECOR", "INLIMBO" }

local function CheckForBoatsTick(inst)
    BermudaTravel.RefreshArrivals(inst)
    if not inst.components.teleporter:IsActive() then return end
    local x, y, z = inst.Transform:GetWorldPosition()
    for _, entity in ipairs(TheSim:FindEntities(x, y, z, BermudaTravel.RANGE, nil, TRAVEL_EXCLUDE, TRAVEL_TAGS)) do
        if not (entity.sg ~= nil and entity.sg:HasStateTag("busy")) then
            BermudaTravel.Request(inst, entity)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("bermudatriangle.tex")

    inst.AnimState:SetBank("bermudatriangle")
    inst.AnimState:SetBuild("bermudatriangle")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    inst.Transform:SetScale(1.3, 1.3, 1.3)

    --trader, alltrader (from trader component) added to pristine state for optimization
    inst:AddTag("bermudatriangle")
    inst:AddTag("trader")
    inst:AddTag("alltrader")
    inst:AddTag("ignorewalkableplatforms")

    inst:AddTag("antlion_sinkhole_blocker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:SetStateGraph("SGbermudatriangle")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    inst.components.inspectable:RecordViews()

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(4, 5)
    inst.components.playerprox.onnear = onnear
    inst.components.playerprox.onfar = onfar

    inst.TeleportTraveler = BermudaTravel.Request
    inst.TeleportSoloBoat = BermudaTravel.Request
    inst.CheckForBoatsTick = CheckForBoatsTick

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate = OnActivate
    inst.components.teleporter.onActivateByOther = OnActivateByOther
    inst.components.teleporter.offset = 0
    inst.components.teleporter.overrideteleportarrivestate = "idle"
    inst.components.teleporter.travelcameratime = 0.5
    inst.components.teleporter.travelarrivetime = 0.6

    inst:ListenForEvent("starttravelsound", StartTravelSound) -- triggered by player stategraph
    inst:ListenForEvent("doneteleporting", OnDoneTeleporting)
    inst:ListenForEvent("onremove", BermudaTravel.CancelAll)
    inst:AddComponent("entitytracker")
    inst._check_for_boats_task = inst:DoPeriodicTask(CHECK_FOR_BOATS_PERIOD, CheckForBoatsTick,
        CHECK_FOR_BOATS_PERIOD * math.random())

    inst:AddComponent("inventory")

    inst:AddComponent("trader")
    inst.components.trader.acceptnontradable = true
    inst.components.trader.onaccept = onaccept
    inst.components.trader.deleteitemonaccept = false

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("bermudatriangle", fn, assets, prefabs)
