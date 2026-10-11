local M = { EXTERIOR_TAG = "exterior_prototyper" }

local function IsInterior(doer)
    return doer ~= nil and doer:IsInInterior()
end

function M.CanUse(station, doer)
    return not (station:HasTag(M.EXTERIOR_TAG) and IsInterior(doer))
end

function M.ApplyBuilder(Builder)
    local evaluate = Builder.EvaluateTechTrees
    function Builder:EvaluateTechTrees(...)
        if not IsInterior(self.inst) then
            return evaluate(self, ...)
        end
        local original = self.exclude_tags
        local excluded = {}
        for _, tag in ipairs(original) do excluded[#excluded + 1] = tag end
        excluded[#excluded + 1] = M.EXTERIOR_TAG
        self.exclude_tags = excluded
        local ok, result = pcall(evaluate, self, ...)
        self.exclude_tags = original
        if not ok then error(result, 0) end
        return result
    end

    local use = Builder.UsePrototyper
    function Builder:UsePrototyper(station, ...)
        if station ~= nil and not M.CanUse(station, self.inst) then
            return false
        end
        return use(self, station, ...)
    end
end

return M
