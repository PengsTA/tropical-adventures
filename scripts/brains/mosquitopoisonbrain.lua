require "behaviours/wander"
require "behaviours/leash"
require "behaviours/doaction"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/follow"

local BrainCommon = require("brains/braincommon")
local LilypadPopulation = require("tools/lilypad_population")

local function GoHomeAction(inst)
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker:GetHome() or nil
    if home ~= nil and home:IsValid() then
        return BufferedAction(inst, home, ACTIONS.GOHOME)
    end
end

local function GetLeader(inst)
    return inst.components.follower ~= nil and inst.components.follower:GetLeader() or nil
end

local function WanderTarget(inst)
    if inst.components.combat:ValidateTarget() then
        return inst.components.combat.target:GetPosition()
    end
    local leader = GetLeader(inst)
    return leader ~= nil and leader:IsValid() and leader:GetPosition()
        or inst.components.knownlocations:GetLocation("home")
end

local function GetNoLeaderHomePos(inst)
    return GetLeader(inst) == nil and inst.components.knownlocations:GetLocation("home") or nil
end

local function ShouldGoHome(inst)
    local lilypadhome = LilypadPopulation.ShouldGoHome(inst)
    if lilypadhome ~= nil then
        return lilypadhome
    end
    return TheWorld.state.iswinter or (TheWorld.state.isday and not inst.override_stay_out)
end

local function ShouldChase(inst)
    return inst.components.combat.target == nil or not inst.components.combat:InCooldown()
end

local function ShouldDodge(inst)
    return inst.components.combat.target ~= nil and inst.components.combat:InCooldown()
end

local function GetRunawayTarget(inst)
    return inst.components.combat.target
end

local WANDERTIMES = { minwalktime = .1, randwalktime = .1, minwaittime = 0, randwaittime = 0 }

local MosquitoPoisonBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function MosquitoPoisonBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        BrainCommon.ElectricFencePanicTrigger(self.inst),
        Follow(self.inst, GetLeader, 3, 8, 12),
        Leash(self.inst, GetNoLeaderHomePos, 20, 6),
        WhileNode(function() return ShouldChase(self.inst) end, "AttackMomentarily",
            ChaseAndAttack(self.inst, SpringCombatMod(10), SpringCombatMod(8))),
        WhileNode(function() return ShouldGoHome(self.inst) end, "ShouldGoHome",
            DoAction(self.inst, GoHomeAction, "go home", true)),
        WhileNode(function() return ShouldDodge(self.inst) end, "Dodge",
            RunAway(self.inst, { getfn = GetRunawayTarget }, 4, 8)),
        Wander(self.inst, WanderTarget, 6, WANDERTIMES),
    }, .25)
    self.bt = BT(self.inst, root)
end

return MosquitoPoisonBrain
