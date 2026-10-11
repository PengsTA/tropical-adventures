local Traps = require("tools/cave_ruins_traps")
local dependencies = { "pig_ruins_pressure_plate", "pig_ruins_dart_statue", "pig_ruins_spear_trap" }

local function Near(inst)
    if inst.components.disarmable.armed and not inst.down then
        inst.down = true
        inst.AnimState:PlayAnimation("popdown")
        inst.AnimState:PushAnimation("down_idle", true)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/pressure_plate/hit")
        Traps.Trigger(inst)
    end
end

local function Far(inst)
    if inst.down then
        inst.down = false
        inst.AnimState:PlayAnimation("popup")
        inst.AnimState:PushAnimation("up_idle", true)
        if inst.components.disarmable.armed then
            Traps.Release(inst)
        end
    end
end

local function Disarm(inst)
    if inst._ruins_owner then inst._ruins_owner:Control(inst, "disarm") else Traps.Deactivate(inst) end
    inst.down = false
    inst.components.creatureprox:SetEnabled(false)
    inst.AnimState:PlayAnimation("disarmed")
    inst.components.workable:SetWorkLeft(0)
    inst.components.workable:SetWorkable(false)
end

local function Plate()
    local inst = Prefabs.pig_ruins_pressure_plate.fn()
    inst:SetPrefabNameOverride("pig_ruins_pressure_plate")
    inst:RemoveTag("NOCLICK")
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(2)
    inst.components.workable:SetOnFinishCallback(function(inst)
        inst.components.disarmable:disarm()
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/disarm_floor")
    end)
    inst.components.disarmable.disarmfn = Disarm
    inst.components.disarmable.rearmable = false

    local prox = inst.components.creatureprox
    prox:SetOnPlayerNear(Near)
    prox:SetOnPlayerFar(Far)
    prox:SetTestfn(Traps.IsWeight)
    prox:SetDist(Traps.NEAR_DIST, Traps.FAR_DIST)
    prox.period = .1
    prox:Schedule()

    local oldsave, oldload = inst.OnSave, inst.OnLoad
    inst.OnSave = function(inst, data)
        oldsave(inst, data)
        data.disarmed = not inst.components.disarmable.armed or nil
        data.startdown = inst:HasTag("startdown") or nil
        data.trap_range = inst.trap_range
    end
    inst.OnLoad = function(inst, data)
        oldload(inst, data)
        if data then
            if data.disarmed then
                inst.components.disarmable.armed = false
                Disarm(inst)
            end
            if data.startdown then
                inst:AddTag("startdown")
                inst.down = true
                inst.AnimState:PlayAnimation("down_idle", true)
            end
            if data.trap_range then
                inst.trap_range = data.trap_range
            end
        end
    end
    inst:DoTaskInTime(0, function(inst)
        if inst._ruins_owner then
            if inst.components.disarmable.armed then
                inst.components.creatureprox.isclose = nil
                inst.components.creatureprox:forcetest()
            end
            return
        end
        if inst.down or inst:HasTag("startdown") then
            inst.down = true
            inst.AnimState:PlayAnimation("down_idle", true)
            Traps.Deactivate(inst)
        elseif inst.components.disarmable.armed then
            Traps.Activate(inst)
        end
    end)
    inst.OnEntitySleep = function(inst)
        inst.components.creatureprox.isclose = nil
        if not inst:HasTag("startdown") then
            inst.down = false
            inst.AnimState:PlayAnimation("up_idle", true)
        end
    end
    inst.OnEntityWake = function(inst)
        inst.components.creatureprox.isclose = nil
        inst.components.creatureprox:forcetest()
    end
    inst:ListenForEvent("onremove", function(inst)
        if inst._ruins_owner then return end
        if inst.components.disarmable and inst.components.disarmable.armed then
            Traps.Activate(inst)
        end
    end)
    return inst
end

local function Target(base, spear)
    return function()
        local inst = Prefabs[base].fn()
        inst:SetPrefabNameOverride(base)
        if not TheWorld.ismastersim then return inst end

        local function StartPeriodic(inst)
            if not inst:IsValid() or inst._periodic_running then return end
            inst._periodic_running = true
            local function StepDown()
                if not inst:IsValid() then return end
                inst.wantstoretract = true
                inst.wantstoextend = nil
                inst:PushEvent("reset")
                local down_time = inst.down_time or (2.2 + math.random() * 1.2)
                inst._periodictask = inst:DoTaskInTime(down_time, function()
                    if not inst:IsValid() then return end
                    inst.wantstoretract = nil
                    inst.wantstoextend = true
                    inst:PushEvent("spring")
                    local up_time = inst.up_time or (1.3 + math.random() * 0.5)
                    inst._periodictask = inst:DoTaskInTime(up_time, StepDown)
                end)
            end
            local initial_delay = inst.initial_delay or (math.random() * 2.0)
            inst._periodictask = inst:DoTaskInTime(initial_delay, StepDown)
        end

        if spear then
            inst.periodic = true
            inst.StartPeriodic = StartPeriodic
            inst:DoTaskInTime(0, StartPeriodic)

            local oldsave = inst.OnSave
            inst.OnSave = function(inst, data)
                if oldsave then oldsave(inst, data) end
                data.periodic = true
                data.initial_delay = inst.initial_delay
                data.down_time = inst.down_time
                data.up_time = inst.up_time
            end
            local oldload = inst.OnLoad
            inst.OnLoad = function(inst, data)
                if oldload then oldload(inst, data) end
                inst.periodic = true
                if data then
                    if data.down_time then inst.down_time = data.down_time end
                    if data.up_time then inst.up_time = data.up_time end
                    if data.initial_delay then inst.initial_delay = data.initial_delay end
                end
                inst:DoTaskInTime(0, StartPeriodic)
            end
            return inst
        end

        inst:AddTag(Traps.TARGET_TAG)
        local function TriggerBurst(inst)
            if not inst:IsValid() then return end
            if not inst.components.disarmable or not inst.components.disarmable.armed then return end
            if inst._ruins_owner then return inst._ruins_owner:Control(nil, "press") end
            if inst._bursttask then inst._bursttask:Cancel() end
            inst.components.autodartthrower.updatefn = inst.updaterotation
            inst.components.autodartthrower:TurnOn()
            inst._bursttask = inst:DoTaskInTime(4, function(inst)
                inst._bursttask = nil
                if inst:IsValid() then inst.components.autodartthrower:TurnOff() end
            end)
        end
        inst.TriggerBurst = TriggerBurst
        inst:ListenForEvent("triggertrap", TriggerBurst)
        inst:ListenForEvent("reset", function(inst)
            if inst._bursttask then
                inst._bursttask:Cancel()
                inst._bursttask = nil
            end
            if inst.components.autodartthrower then
                inst.components.autodartthrower:TurnOff()
            end
        end)

        local oldsave = inst.OnSave
        inst.OnSave = function(inst, data)
            if oldsave then oldsave(inst, data) end
            if Traps.IsActive(inst) then
                data.active = true
            end
            if inst.startactive ~= nil then
                data.startactive = inst.startactive
            end
        end

        local oldload = inst.OnLoad
        inst.OnLoad = function(inst, data)
            if oldload then oldload(inst, data) end
            inst._ruins_silencers = nil
            if data then
                if data.startactive ~= nil then
                    inst.startactive = data.startactive
                elseif data.random_active then
                    inst.startactive = (math.random() < 0.5)
                end
            end
            if data and data.active then
                inst._active = true
                if inst.components.autodartthrower then
                    inst:DoTaskInTime(0, function(inst)
                        if not inst._ruins_owner then inst.components.autodartthrower:TurnOn() end
                    end)
                end
            elseif inst.startactive then
                inst._active = true
                if inst.components.autodartthrower then
                    inst:DoTaskInTime(0, function(inst)
                        if not inst._ruins_owner then inst.components.autodartthrower:TurnOn() end
                    end)
                end
            else
                inst._active = nil
                if inst.components.autodartthrower then
                    inst:DoTaskInTime(0, function(inst)
                        if not next(inst._ruins_sources or {}) and not inst._active then
                            inst.components.autodartthrower:TurnOff()
                        end
                    end)
                elseif not next(inst._ruins_sources or {}) and not inst._active then
                    inst:PushEvent("reset")
                end
            end
        end
        return inst
    end
end

return Prefab("ta_ruins_pressure_plate", Plate, nil, dependencies),
    Prefab("ta_ruins_dart_statue", Target("pig_ruins_dart_statue"), nil, dependencies),
    Prefab("ta_ruins_spear_trap", Target("pig_ruins_spear_trap", true), nil, dependencies)
