require "behaviours/wander"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
--require "behaviours/choptree"
require "behaviours/findlight"
require "behaviours/panic"
require "behaviours/chattynode"
require "behaviours/leash"

local MAX_CHASE_TIME = 40
local AntEcology = require("tools/antecology")

local function HasValidHome(inst)
    return inst.components.homeseeker and 
       inst.components.homeseeker.home and 
       not inst.components.homeseeker.home:HasTag("fire") and
       not inst.components.homeseeker.home:HasTag("burnt") and
       inst.components.homeseeker.home:IsValid()
end

local function GetHomePos(inst)
    return HasValidHome(inst) and inst.components.homeseeker:GetHomePos()
end

local function GetWanderPoint(inst)
    local home = GetHomePos(inst)
    if home then return home end
    local locations = inst.components.knownlocations
    locations:RememberLocation("patrol", inst:GetPosition(), true)
    return locations:GetLocation("patrol")
end

local AntWarriorBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AntWarriorBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst) ),
        
        ChattyNode(self.inst, "ANT_TALK_FIGHT", ChaseAndAttack(self.inst, MAX_CHASE_TIME)),
        Follow(self.inst, AntEcology.GetLeader, 2, 5, 9),
        Wander(self.inst, GetWanderPoint, 20),

    }, .1)
    
    self.bt = BT(self.inst, root)
end

return AntWarriorBrain
