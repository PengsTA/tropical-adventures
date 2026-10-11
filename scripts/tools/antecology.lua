local AntEcology = {}

function AntEcology.IsNursery(inst)
    return inst.ant_caste == "nursery" or inst.worker_prefab == "antman2"
end

function AntEcology.GetHomePosition(inst)
    local home = inst.components.homeseeker and inst.components.homeseeker.home
    if home and home:IsValid() and not home:HasTag("fire") and not home:HasTag("burnt") then
        return home:GetPosition()
    end
    local locations = inst.components.knownlocations
    locations:RememberLocation("ant_workplace", inst:GetPosition(), true)
    return locations:GetLocation("ant_workplace")
end

function AntEcology.InWorkArea(inst, target, radius)
    return not AntEcology.IsNursery(inst)
        or (target:GetPosition() - AntEcology.GetHomePosition(inst)):LengthSq() <= radius * radius
end

function AntEcology.GetLeader(inst)
    return not AntEcology.IsNursery(inst) and inst.components.follower.leader or nil
end

function AntEcology.ConfigureFriendship(inst)
    if AntEcology.IsNursery(inst) then
        -- Nursery friendship never teleports residents to a distant feeder.
        inst.components.follower:DisableLeashing()
        inst.components.follower.canaccepttarget = false
        inst.components.follower:SetCanBeRollCalledFn(function() return false end)
    end
end

function AntEcology.SetNurseryDiet(inst)
    inst.eattype = 2
    inst.components.eater:SetDiet({ FOODTYPE.SEEDS, FOODTYPE.VEGGIE, FOODTYPE.GENERIC })
end

function AntEcology.SetupNurseryDiet(inst)
    local eater = inst.components.eater
    local testfood = eater.TestFood
    eater.TestFood = function(self, food, values)
        -- Honey uses GENERIC in DST; other generic foods are not nursery food.
        if food and food.components.edible and food.components.edible.foodtype == FOODTYPE.GENERIC
            and food.prefab ~= "honey" then return false end
        return testfood(self, food, values)
    end
    AntEcology.SetNurseryDiet(inst)
end

function AntEcology.CanTranslate(player)
    if player == nil then return false end
    local inventory = player.replica and player.replica.inventory or player.components.inventory
    if inventory then
        for _, slot in pairs(EQUIPSLOTS) do
            local item = inventory:GetEquippedItem(slot)
            if item and item:HasTag("ant_translator") then return true end
        end
    end
    return player:HasTag("antlingual")
end

function AntEcology.IsDisguised(target)
    return target ~= nil and (AntEcology.CanTranslate(target) or target:HasTag("ant_disguise")
        or (target:HasTag("has_antmask") and target:HasTag("has_antsuit")))
end

function AntEcology.IsIntruder(inst, target, sightdistance)
    return target ~= nil and not target:HasTag("ant") and not target:HasTag("antqueen")
        and not target:HasTag("playerghost") and not target:HasTag("notarget")
        and not AntEcology.IsDisguised(target)
        and not (inst.components.follower and inst.components.follower.leader == target)
        and AntEcology.InWorkArea(inst, target, 10)
        and target.components.health ~= nil and not target.components.health:IsDead()
        and inst.components.combat:CanTarget(target)
        and (target:HasTag("monster") or (target:HasTag("player")
            and inst:GetDistanceSqToInst(target) < sightdistance * sightdistance))
end

function AntEcology.KeepTarget(inst, target)
    return target ~= nil and inst.components.combat:CanTarget(target)
        and AntEcology.InWorkArea(inst, target, 10)
        and (inst._ant_attacker == target or not AntEcology.IsDisguised(target))
        and not (target.sg and target.sg:HasStateTag("transform"))
end

function AntEcology.SetupAggro(inst)
    inst:ListenForEvent("droppedtarget", function(ant, data)
        if data and data.target == ant._ant_attacker then ant._ant_attacker = nil end
    end)
end

function AntEcology.DefendColony(inst, attacker)
    inst._ant_attacker = attacker
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, 30, function(ant)
        if ant:HasTag("ant") then
            ant._ant_attacker = attacker
            return true
        end
        return false
    end, 5)
end

function AntEcology.SetupSpeech(inst)
    local talker = inst.components.talker
    talker.fontsize = 35
    talker.font = TALKINGFONT
    talker.offset = Vector3(0, -400, 0)
    talker:MakeChatter()
    -- Resolve for the local listener, after the original line is replicated.
    talker.mod_str_fn = function(message)
        if AntEcology.CanTranslate(ThePlayer) then return message end
        local lines = STRINGS.ANT_TALK_UNTRANSLATED
        return lines[math.random(#lines)]
    end
    talker.ontalkfn = function(ant)
        ant.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/abandon")
    end
end

function AntEcology.NameWorker(inst)
    local name = AntEcology.IsNursery(inst) and STRINGS.NAMES.ANT_NURSERY_WORKER or STRINGS.NAMES.ANT_FORAGER
    inst.components.named.possiblenames = { name .. " #" .. math.random(1, 1000000) }
    inst.components.named:PickNewName()
end

function AntEcology.ReplaceAnt(inst, prefab)
    local replacement = SpawnPrefab(prefab)
    if replacement == nil then return end
    replacement.Transform:SetPosition(inst.Transform:GetWorldPosition())
    replacement.components.health:SetPercent(inst.components.health:GetPercent())
    if prefab == "antman_warrior" and inst.worker_prefab == nil then
        replacement.worker_prefab = inst.prefab
        replacement.worker_eattype = inst.eattype
    end
    AntEcology.ConfigureFriendship(replacement)
    if inst.components.knownlocations and replacement.components.knownlocations then
        local workplace = inst.components.knownlocations:GetLocation("ant_workplace")
        if workplace then replacement.components.knownlocations:RememberLocation("ant_workplace", workplace) end
    end
    local home = inst.components.homeseeker and inst.components.homeseeker.home
    local spawner = home and home:IsValid() and home.components.childspawner
    if spawner and spawner.childrenoutside[inst] then
        inst:PushEvent("detachchild")
        spawner:TakeOwnership(replacement)
    end
    local follower = inst.components.follower
    if follower and follower.leader and replacement.components.follower then
        follower.leader.components.leader:AddFollower(replacement)
        if follower.targettime then
            replacement.components.follower:AddLoyaltyTime(math.max(0, follower.targettime - GetTime()))
        end
    end
    if inst.components.inventory and replacement.components.inventory then
        inst.components.inventory:TransferInventory(replacement)
    end
    replacement.components.combat:SetTarget(inst.components.combat.target)
    replacement._ant_attacker = inst._ant_attacker
    inst:Remove()
    return replacement
end

function AntEcology.TransformWorker(inst)
    if not inst:IsValid() or inst.components.health:IsDead() or not TheWorld.state.isaporkalypse then return end
    AntEcology.ReplaceAnt(inst, "antman_warrior")
end

function AntEcology.WatchWorker(inst)
    inst:WatchWorldState("isaporkalypse", function(ant, active)
        if active then AntEcology.TransformWorker(ant) end
    end)
    inst:DoTaskInTime(0, AntEcology.TransformWorker)
end

function AntEcology.RestoreWorker(inst)
    if inst.worker_prefab == nil then return end
    local eattype = inst.worker_eattype
    local worker = AntEcology.ReplaceAnt(inst, inst.worker_prefab)
    if worker and eattype then worker:SetEatType(eattype) end
    return worker
end

return AntEcology
