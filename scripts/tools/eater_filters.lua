local M = {}

-- TestFood is shared by DST preference checks, CanEat and Eat.
function M.Restrict(eater, predicate)
    local testfood = eater.TestFood
    eater.TestFood = function(self, food, values)
        return food ~= nil and predicate(self.inst, food) and testfood(self, food, values)
    end
end

return M
