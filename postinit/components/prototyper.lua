local TROENV = env
GLOBAL.setfenv(1, GLOBAL)

local TechTree = require("techtree")
local PrototyperPolicy = require("tools/prototyper_policy")

local function IsFloodDisabled(prototyper)
    return prototyper.disabled or prototyper.inst:HasTag("flooded")
end

TROENV.AddComponentPostInit("prototyper", function(prototyper)
    local old_can_use = prototyper.CanUsePrototyper
    function prototyper:CanUsePrototyper(doer)
        return PrototyperPolicy.CanUse(self.inst, doer) and old_can_use(self, doer)
    end

    local old_get_tech_trees = prototyper.GetTechTrees
    function prototyper:GetTechTrees()
        if IsFloodDisabled(self) then
            return TechTree.Create()
        end
        return old_get_tech_trees(self)
    end

    local old_turn_on = prototyper.TurnOn
    function prototyper:TurnOn(doer)
        if not IsFloodDisabled(self) then
            old_turn_on(self, doer)
        end
    end

    local old_activate = prototyper.Activate
    function prototyper:Activate(doer, recipe)
        if not IsFloodDisabled(self) then
            old_activate(self, doer, recipe)
        end
    end
end)
