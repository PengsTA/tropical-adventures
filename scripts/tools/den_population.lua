local M = {}

function M.Configure(inst, childname, delay, water, prefill)
    inst:AddComponent("childspawner")
    local population = inst.components.childspawner
    population.childname = childname
    population.wateronly = water == true
    population:SetSpawnPeriod(1, 0)
    population:SetRegenPeriod(delay, 0)
    population:SetMaxChildren(1)
    if not prefill then population.childreninside = 0 end
    population:StartRegen()
    inst.OnLoad = function(den, data)
        local legacy = data ~= nil and data.childspawner == nil and data.spawner or nil
        if legacy ~= nil then
            local spawner = den.components.childspawner
            spawner.childreninside = legacy.child ~= nil and 1 or 0
            spawner.timetonextregen = legacy.startdelay or spawner.regenperiod
            den._legacy_childid = legacy.childid
            spawner:StartUpdate()
        end
    end
    inst.OnLoadPostPass = function(den, newents)
        local entry = den._legacy_childid ~= nil and newents[den._legacy_childid] or nil
        den._legacy_childid = nil
        if entry ~= nil and entry.entity:IsValid() then
            den.components.childspawner:TakeOwnership(entry.entity)
        end
    end
    return population
end

return M
