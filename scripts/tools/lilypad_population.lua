local M = {}

local SETTINGS = {
    frog_poison = "FROG_POISON_LILYPAD_",
    mosquito_poison = "MOSQUITO_LILYPAD_",
}

local function IsEnabled(childname)
    local prefix = SETTINGS[childname]
    return prefix ~= nil and TUNING[prefix .. "ENABLED"]
        and TUNING[prefix .. "MAX_SPAWN"] > 0
end

local function ChooseChild()
    if IsEnabled("frog_poison") then
        if not IsEnabled("mosquito_poison") or math.random() < .5 then
            return "frog_poison"
        end
    end
    return "mosquito_poison"
end

local function IsPopulationActive(inst)
    local childname = inst.components.childspawner.childname
    return IsEnabled(childname) and (childname == "frog_poison"
        and TheWorld.state.phase ~= "night"
        or childname == "mosquito_poison" and TheWorld.state.phase ~= "day")
end

local function ReturnChildren(inst)
    for child in pairs(inst.components.childspawner.childrenoutside) do
        if child:IsValid() then
            if child.components.homeseeker ~= nil then
                child.components.homeseeker:GoHome()
            end
            child:PushEvent("gohome")
        end
    end
end

local function UpdateActivity(inst)
    local population = inst.components.childspawner
    if IsEnabled(population.childname) then
        if not population.regening then
            population:StartRegen()
        end
    else
        population:StopRegen()
    end

    if IsPopulationActive(inst) then
        if not population.spawning then
            population:StartSpawning()
        else
            population:StartUpdate()
        end
    else
        population:StopSpawning()
        ReturnChildren(inst)
    end
end

local function ConfigureChild(inst, childname)
    local population = inst.components.childspawner
    local prefix = SETTINGS[childname]
    population.childname = childname
    population:SetRegenPeriod(TUNING[prefix .. "REGEN_TIME"])
    population:SetSpawnPeriod(TUNING[prefix .. "RELEASE_TIME"])
    population:SetMaxChildren(TUNING[prefix .. "MAX_SPAWN"])
end

local function OnSpawned(inst, child)
    if child.prefab == "frog_poison" then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/water/small_submerge")
        child.components.tiletracker:OnUpdate(0)
    end
end

local function OnSave(inst, data)
    data.childname = inst.components.childspawner.childname
end

local function OnPreLoad(inst, data)
    local childname = data ~= nil and data.childname or nil
    if childname == "mosquito" then
        childname = "mosquito_poison"
    end
    if SETTINGS[childname] ~= nil then
        -- Select the saved species before childspawner restores counts and timers.
        ConfigureChild(inst, childname)
    end
end

function M.Configure(inst)
    inst:AddComponent("childspawner")
    local population = inst.components.childspawner
    population.wateronly = true
    population.spawnradius = 1
    population.canspawnfn = IsPopulationActive
    population:SetSpawnedFn(OnSpawned)
    ConfigureChild(inst, ChooseChild())

    inst.IsPopulationActive = IsPopulationActive
    inst.OnSave = OnSave
    inst.OnPreLoad = OnPreLoad
    inst:WatchWorldState("phase", UpdateActivity)
    -- Component references and saved timers are restored before this runs.
    inst:DoTaskInTime(0, UpdateActivity)
end

function M.ShouldGoHome(child)
    local home = child.components.homeseeker ~= nil and child.components.homeseeker:GetHome() or nil
    if home ~= nil and home:IsValid() and home.prefab == "lilypad" then
        return not home:IsPopulationActive()
    end
    return nil
end

return M
