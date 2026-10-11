local FLOOD_EFFECT = "shock_machines_fx"
local FLOOD_SOUND = "dontstarve_DLC002/creatures/jellyfish/electric_land"

AddPrefabPostInit("sandbag", function(inst)
    local function Changed()
        -- Defer removal notifications until entity searches no longer find it.
        TheWorld:DoTaskInTime(0, function() TheWorld:PushEvent("floodcontrolchanged") end)
    end
    inst:DoTaskInTime(0, Changed)
    inst:ListenForEvent("onremove", Changed)
end)

local function AddFloodable(inst, on_start, on_stop, effect, sound)
    if not TheWorld.ismastersim or inst.components.floodable ~= nil then
        return
    end

    inst:AddComponent("floodable")
    if effect ~= false then
        inst.components.floodable.floodEffect = effect or FLOOD_EFFECT
        inst.components.floodable.floodSound = sound or FLOOD_SOUND
    end
    inst.components.floodable.onStartFlooded = on_start
    inst.components.floodable.onStopFlooded = on_stop
end

local function DisableMachine(inst)
    local machine = inst.components.machine
    if machine == nil then
        return
    end

    inst._tropical_flood_machine_enabled = machine.enabled
    machine.enabled = false
    if machine:IsOn() then
        machine:TurnOff()
    end
end

local function RestoreMachine(inst)
    local machine = inst.components.machine
    if machine ~= nil then
        machine.enabled = inst._tropical_flood_machine_enabled ~= false
    end
    inst._tropical_flood_machine_enabled = nil
end

local function DisableContainer(inst)
    local container = inst.components.container
    if container == nil then
        return
    end

    container:Close()
    inst._tropical_flood_canopen = container.canbeopened
    container.canbeopened = false
end

local function RestoreContainer(inst, is_busy)
    local container = inst.components.container
    if container ~= nil and not is_busy then
        container.canbeopened = inst._tropical_flood_canopen ~= false
    end
    inst._tropical_flood_canopen = nil
end

local function FloodCooker(inst)
    DisableContainer(inst)
    local stewer = inst.components.stewer
    if stewer ~= nil and stewer.targettime ~= nil then
        stewer.product = "wetgoop"
    end
end

local function RestoreCooker(inst)
    local stewer = inst.components.stewer
    RestoreContainer(inst, stewer ~= nil and (stewer.targettime ~= nil or stewer.done))
end

local function FloodMelter(inst)
    DisableContainer(inst)
    local melter = inst.components.melter
    if melter ~= nil and melter.cooking then
        melter.product = "wetgoop"
    end
end

local function RestoreMelter(inst)
    local melter = inst.components.melter
    RestoreContainer(inst, melter ~= nil and (melter.cooking or melter.done))
end

local function DisablePrototyper(inst)
    local prototyper = inst.components.prototyper
    if prototyper == nil then
        return
    end

    prototyper.disabled = true
    local doers = {}
    for doer in pairs(prototyper.doers) do
        doers[#doers + 1] = doer
    end
    for _, doer in ipairs(doers) do
        prototyper:TurnOff(doer)
    end
end

local function RestorePrototyper(inst)
    if inst.components.prototyper ~= nil then
        inst.components.prototyper.disabled = false
    end
end

local function ExtinguishFire(inst)
    local burnable = inst.components.burnable
    if burnable ~= nil and burnable:IsBurning() then
        burnable:Extinguish()
    end
end

AddPrefabPostInit("icemaker", function(inst)
    AddFloodable(inst,
        function(machine)
            if machine.components.fueled ~= nil then
                machine.components.fueled.accepting = false
            end
        end,
        function(machine)
            if machine.components.fueled ~= nil then
                machine.components.fueled.accepting = true
            end
        end)
end)

AddPrefabPostInit("slotmachine", function(inst)
    AddFloodable(inst,
        function(machine)
            if machine.components.trader ~= nil then
                machine.components.trader:Disable()
            end
        end,
        function(machine)
            if machine.components.trader ~= nil then
                machine.components.trader:Enable()
            end
        end)
end)

AddPrefabPostInit("smelter", function(inst)
    AddFloodable(inst, FloodMelter, RestoreMelter)
end)

for _, prefab in ipairs({ "cookpot", "portablecookpot" }) do
    AddPrefabPostInit(prefab, function(inst)
        AddFloodable(inst, FloodCooker, RestoreCooker)
    end)
end

AddPrefabPostInit("icebox", function(inst)
    AddFloodable(inst,
        function(box)
            box._tropical_flood_was_fridge = box:HasTag("fridge")
            box:RemoveTag("fridge")
        end,
        function(box)
            if box._tropical_flood_was_fridge then
                box:AddTag("fridge")
            end
            box._tropical_flood_was_fridge = nil
        end)
end)

for _, prefab in ipairs({ "basefan", "firesuppressor", "sprinkler" }) do
    AddPrefabPostInit(prefab, function(inst)
        AddFloodable(inst, DisableMachine, RestoreMachine)
    end)
end

for _, prefab in ipairs({
    "researchlab",
    "researchlab2",
    "researchlab3",
    "researchlab4",
    "seafaring_prototyper",
    "cartographydesk",
    "waterprototyper",
}) do
    AddPrefabPostInit(prefab, function(inst)
        AddFloodable(inst, DisablePrototyper, RestorePrototyper)
    end)
end

for _, prefab in ipairs({ "campfire", "coldfire", "firepit", "coldfirepit", "obsidianfirepit" }) do
    AddPrefabPostInit(prefab, function(inst)
        AddFloodable(inst, ExtinguishFire, nil, false)
    end)
end
