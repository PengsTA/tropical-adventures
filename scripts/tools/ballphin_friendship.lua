local EaterFilters = require("tools/eater_filters")
local M = {}

local function CanEat(inst, item)
    return item:HasTag("fishmeat") or item:HasTag("hydrofarm")
end

local function UpdateFriend(inst)
    if inst.components.follower.leader ~= nil then
        inst:AddTag("ballphinfriend")
    else
        inst:RemoveTag("ballphinfriend")
    end
end

function M.Configure(inst)
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.MEAT, FOODTYPE.VEGGIE }, { FOODTYPE.MEAT, FOODTYPE.VEGGIE })
    EaterFilters.Restrict(inst.components.eater, CanEat)
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.BALLPHIN_LOYALTY_MAX_TIME or 1440
    inst:ListenForEvent("leaderchanged", UpdateFriend)
    inst:AddComponent("trader")
    inst.components.trader.deleteitemonaccept = false
    inst.components.trader:SetAcceptTest(function(animal, item)
        return not animal.components.sleeper:IsAsleep() and animal.components.eater:CanEat(item)
            and (animal.components.follower.leader == nil or animal.components.follower:GetLoyaltyPercent() < 0.9)
    end)
    inst.components.trader.onaccept = function(animal, giver, item)
        if giver ~= nil and giver.components.leader ~= nil and item:HasTag("fishmeat") then
            if animal.components.combat.target == giver then animal.components.combat:SetTarget(nil) end
            giver.components.leader:AddFollower(animal)
            animal.components.follower:AddLoyaltyTime(math.min(TUNING.BALLPHIN_LOYALTY_MAX_TIME or 1440,
                math.max(0, item.components.edible:GetHunger()) * (TUNING.BALLPHIN_LOYALTY_PER_HUNGER or 40)))
            animal.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
        end
        animal.components.eater:Eat(item, giver)
    end
    inst:AddComponent("named")
    inst.components.named.possiblenames = STRINGS.BALLPHINNAMES or { STRINGS.NAMES.BALLPHIN or "Ballphin" }
    inst.components.named:PickNewName()
    inst:AddComponent("talker")
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = function(animal, observer)
        return animal.components.follower.leader == observer and TUNING.SANITYAURA_MED or 0
    end
end

return M
