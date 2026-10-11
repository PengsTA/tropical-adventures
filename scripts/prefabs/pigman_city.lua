require "brains/pigguardbrain"
require "brains/werepigbrain"
require "stategraphs/SGpig_city"
require "stategraphs/SGwerepig"
local ClimateProfiles = require("tools/climateprofiles")
local CityBribes = require("tools/city_bribes")

local CityPigBrain = require "brains/citypigbrain"
local RoyalPigGuardBrain = require "brains/royalpigguardbrain"

--------------------------------------------------------------------------
-- 常量
--------------------------------------------------------------------------

local TOTAL_DAY_TIME = 480

local PIG_DAMAGE = 33
local PIG_HEALTH = 250
local PIG_ATTACK_PERIOD = 3
local PIG_LOYALTY_MAXTIME = 2.5 * TOTAL_DAY_TIME
local PIG_RUN_SPEED = 5
local PIG_WALK_SPEED = 3

local CITY_PIG_GUARD_TARGET_DIST = 20
local SPRING_COMBAT_MOD = 1.33
local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30
local CALL_GUARD_DIST = 30
local INVADER_CHECK_DIST = 25

local GUARD_BRIBE_THRESHOLD = 10
local CIVILIAN_BRIBE_THRESHOLD = 1

local builds = { "pig_build", "pigspotted_build" }

-- 卫兵标签，注册时通过 opts.tags 传入
local GUARD_TAGS = { "emote_nocurtsy", "guard", "extinguisher" }

-- 收下礼物盒后随机回赠的物品
local GIFT_TRINKETS = { "kabobs", "pumpkincookie", "taffy", "oinc", "butterflymuffin", "powcake" }

-- oinc 面额换算
local OINC_VALUE =
{
    oinc = 1,
    oinc10 = 10,
    oinc100 = 100,
}

-- 当天已经交易过（troqueihoje）仍然可以继续交易的职业
local UNLIMITED_TRADE =
{
    pigman_storeowner = true,
    pigman_banker = true,
    pigman_mayor = true,
    pigman_queen = true,
    pigman_professor = true,
    pigman_collector = true,
    pigman_mechanic = true,
    pigman_storeowner_shopkeep = true,
    pigman_banker_shopkeep = true,
    pigman_mayor_shopkeep = true,
    pigman_professor_shopkeep = true,
    pigman_collector_shopkeep = true,
    pigman_mechanic_shopkeep = true,
}

local assets =
{
    Asset("SOUND", "sound/pig.fsb"),
    Asset("ANIM", "anim/pig_usher.zip"),
    Asset("ANIM", "anim/pig_mayor.zip"),
    Asset("ANIM", "anim/pig_miner.zip"),
    Asset("ANIM", "anim/pig_queen.zip"),
    Asset("ANIM", "anim/pig_farmer.zip"),
    Asset("ANIM", "anim/pig_hunter.zip"),
    Asset("ANIM", "anim/pig_banker.zip"),
    Asset("ANIM", "anim/pig_florist.zip"),
    Asset("ANIM", "anim/pig_erudite.zip"),
    Asset("ANIM", "anim/pig_hatmaker.zip"),
    Asset("ANIM", "anim/pig_mechanic.zip"),
    Asset("ANIM", "anim/pig_professor.zip"),
    Asset("ANIM", "anim/pig_collector.zip"),
    Asset("ANIM", "anim/townspig_basic.zip"),
    Asset("ANIM", "anim/pig_beautician.zip"),
    Asset("ANIM", "anim/pig_royalguard.zip"),
    Asset("ANIM", "anim/pig_storeowner.zip"),
    Asset("ANIM", "anim/townspig_attacks.zip"),
    Asset("ANIM", "anim/townspig_actions.zip"),
    Asset("ANIM", "anim/pig_royalguard_2.zip"),
    Asset("ANIM", "anim/townspig_shop_wip.zip"),

    Asset("ANIM", "anim/pig_eskimo.zip"),
    Asset("ANIM", "anim/pig_royalguard_rich.zip"),
    Asset("ANIM", "anim/pig_royalguard_rich_2.zip"),
    Asset("ANIM", "anim/pig_royalguard_3.zip"),
    Asset("ANIM", "anim/pig_shopkeeper.zip"),
}

local prefabs =
{
    "meat",
    "poop",
    "tophat",
    "pigskin",
    "halberd",
    "strawhat",
    "monstermeat",
    "pigman_shopkeeper_desk",
}

--------------------------------------------------------------------------
-- 说话
--------------------------------------------------------------------------

local function GetSpeechLine(inst, speech)
    local line = speech.DEFAULT

    if inst.talkertype and speech[inst.talkertype] then
        line = speech[inst.talkertype]
    end

    if type(line) == "table" then
        line = line[math.random(#line)]
    end

    return line
end

local function SayLine(inst, line, mood)
    inst.components.talker:Say(line, 1.5, nil, true, mood)
end

local TALK_SOUNDS =
{
    guard =
    {
        talk = "dontstarve_DLC003/creatures/city_pig/conversational_talk_gaurd",
        alarmed = "dontstarve_DLC003/creatures/city_pig/guard_alert",
    },
    female =
    {
        talk = "dontstarve_DLC003/creatures/city_pig/conversational_talk_female",
        alarmed = "dontstarve_DLC003/creatures/city_pig/scream_female",
    },
    default =
    {
        talk = "dontstarve_DLC003/creatures/city_pig/conversational_talk",
        alarmed = "dontstarve_DLC003/creatures/city_pig/scream",
    },
}

local function GetTalkSounds(inst)
    if inst:HasTag("guard") then
        return TALK_SOUNDS.guard
    elseif inst.female then
        return TALK_SOUNDS.female
    end
    return TALK_SOUNDS.default
end

local function OnTalk(inst, script, mood)
    local sounds = GetTalkSounds(inst)
    if mood == "alarmed" then
        inst.SoundEmitter:PlaySound(sounds.alarmed)
    else
        inst.SoundEmitter:PlaySound(sounds.talk, "talk")
    end
end

local function OnTalkFinish(inst)
    inst.SoundEmitter:KillSound("talk")
end

--------------------------------------------------------------------------
-- 店主与柜台
--------------------------------------------------------------------------

local function ShopkeeperCanTalk(inst)
    return inst:IsValid()
        and not inst:IsAsleep()
        and not inst:IsInLimbo()
        and not inst.components.combat.target
end

local function ShopkeeperSpeech(inst, speech)
    if ShopkeeperCanTalk(inst) then
        SayLine(inst, speech)
    end
end

local function SpawnDesk(inst)
    local pos = inst.desklocation or Vector3(inst.Transform:GetWorldPosition())
    inst.desk = SpawnPrefab("pigman_shopkeeper_desk")
    inst.desk.Transform:SetPosition(pos.x, pos.y, pos.z)
    inst:AddComponent("homeseeker")
    inst.components.homeseeker:SetHome(inst.desk)
end

local function RemoveDesk(inst)
    inst.desklocation = Vector3(inst.Transform:GetWorldPosition())
    if inst.desk then
        inst.desk:Remove()
        inst.desk = nil
    end
end

-- SGpig_city 通过 inst.separatedesk(inst, true/false) 在柜台状态间切换
local function SetAtDesk(inst, atdesk)
    if atdesk then
        inst:RemoveTag("atdesk")
        inst.AnimState:Hide("desk")
        SpawnDesk(inst)
        ChangeToCharacterPhysics(inst)
        inst.Physics:SetMass(50)
    else
        ChangeToObstaclePhysics(inst)
        if inst.desk then
            local x, y, z = inst.desk.Transform:GetWorldPosition()
            inst.Transform:SetPosition(x, y, z)
        end
        RemoveDesk(inst)
        inst:AddTag("atdesk")
        inst.AnimState:Show("desk")
    end
end

local function CloseShop(inst)
    if ShopkeeperCanTalk(inst) then
        inst.sg:GoToState("idle")
        ShopkeeperSpeech(inst, STRINGS.CITY_PIG_SHOPKEEPER_CLOSING[math.random(#STRINGS.CITY_PIG_SHOPKEEPER_CLOSING)])
    end
end

-- 临时卫兵：附近没有玩家时撤退，否则十分钟后再检查
local function OnLeaveTimerDone(inst, data)
    if data.name ~= "vaiembora" then
        return
    end

    if GetClosestInstWithTag("player", inst, INVADER_CHECK_DIST) then
        inst.components.timer:StartTimer("vaiembora", 10)
    else
        inst:Remove()
    end
end

--------------------------------------------------------------------------
-- 交易
--------------------------------------------------------------------------

local function GetEconPrefab(inst)
    return inst.econprefab or inst.prefab
end

-- 跟随者吃饱肉后不再收肉；刚吃过蔬菜或已持有同种蔬菜时不再收素
local function IsHeldBackFood(inst, item)
    local edible = item.components.edible
    if not edible then
        return false
    end

    if (edible.foodtype == "MEAT" or edible.foodtype == "HORRIBLE")
        and inst.components.follower.leader
        and inst.components.follower:GetLoyaltyPercent() > 0.9 then
        return true
    end

    if edible.foodtype == "VEGGIE" or edible.foodtype == "RAW" then
        local last_eat_time = inst.components.eater:TimeSinceLastEating()
        if last_eat_time and last_eat_time < TUNING.PIG_MIN_POOP_PERIOD then
            return true
        end

        if inst.components.inventory:Has(item.prefab, 1) then
            return true
        end
    end

    return false
end

-- 是否是经济系统要收的货物，或特定礼物道具
local function WantsTradeItem(inst, econ, item)
    local wantitem = false

    for _, wanted in ipairs(econ:GetTradeItems(GetEconPrefab(inst))) do
        if wanted == item.prefab then
            wantitem = true
            break
        end
    end

    if (item.prefab == "trinket_giftshop_1" or item.prefab == "trinket_giftshop_3")
        and inst:HasTag("city1") and not inst:HasTag("recieved_trinket") then
        wantitem = true
    end

    -- 无价的遗物二号/五号对非女王一律不收
    if (item.prefab == "relic_4" or item.prefab == "relic_5") and not inst:HasTag("pigqueen") then
        wantitem = false
    end

    return wantitem
end

-- 拒收非目标货物时的台词；收藏家对普通遗物照单全收
local function RefuseUnwantedItem(inst, econ, item)
    if item:HasTag("relic") then
        if item.prefab == "relic_4" or item.prefab == "relic_5" then
            inst.sayline(inst, GetSpeechLine(inst, STRINGS.CITY_PIG_TALK_REFUSE_PRICELESS_GIFT))
        elseif inst.prefab == "pigman_collector_shopkeep" or inst.prefab == "pigman_collector" then
            return true
        else
            inst.sayline(inst, GetSpeechLine(inst, STRINGS.CITY_PIG_TALK_RELIC_GIFT))
        end
    elseif item.prefab == "trinket_giftshop_1"
        or (item.prefab == "trinket_giftshop_3" and inst:HasTag("city1")) then
        inst.sayline(inst, GetSpeechLine(inst, STRINGS.CITY_PIG_TALK_REFUSE_TRINKET_GIFT))
    else
        -- 随机报一个想收的货物和它的价码
        local itemname = GetRandomItem(econ:GetTradeItems(GetEconPrefab(inst)))
        local costprefab, cost = econ:MakeTrade(GetEconPrefab(inst), nil, nil, itemname)

        inst.sayline(inst, subfmt(GetSpeechLine(inst, STRINGS.CITY_PIG_TALK_REFUSE_GIFT),
            {
                item = STRINGS.NAMES[itemname:upper()] or itemname,
                costprefab = costprefab and STRINGS.NAMES[costprefab:upper()],
                cost = cost or 1,
            }))
    end

    return false
end

local function ShouldAcceptItem(inst, item)
    if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
        return false
    end

    if item.components.unwrappable then
        return true
    end

    if item.components.edible and IsHeldBackFood(inst, item) then
        return false
    end

    if OINC_VALUE[item.prefab] then
        return true
    end

    if not inst:HasTag("guard") or inst.prefab == "pig_eskimo" then
        local econ = TheWorld.components.economy

        if WantsTradeItem(inst, econ, item) then
            if item.prefab == "trinket_giftshop_1" or item.prefab == "trinket_giftshop_3" then
                return true
            end

            if inst:HasTag("troqueihoje") and not UNLIMITED_TRADE[inst.prefab] then
                inst.sayline(inst, GetSpeechLine(inst, STRINGS.CITY_PIG_TALK_REFUSE_GIFT_DELAY_TOMORROW))
                return false
            end

            return true
        end

        return RefuseUnwantedItem(inst, econ, item)
    end

    if inst:HasTag("guard") and item:HasTag("securitycontract") then
        return true
    end

    return false
end

-- 拆开礼物盒，得到实际参与交易的物品；返回 items(物品->是否收下) 与 rewards(回报->数量)
local function CollectGivenItems(item)
    local items = {}
    local rewards = {}

    if item.components.unwrappable == nil then
        items[item] = true
    else
        if item.prefab == "bundle" then
            rewards["waxpaper"] = 1
        end
        for _, v in ipairs(item.components.unwrappable.itemdata) do
            local tradeitem = SpawnPrefab(v.prefab, v.skinname, v.skin_id)
            tradeitem:SetPersistData(v.data)
            items[tradeitem] = true
        end
    end

    return items, rewards
end

local function AcceptGuardContract(inst, doer, items)
    for item in pairs(items) do
        if item:HasTag("securitycontract") then
            inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
            doer.components.leader:AddFollower(inst)
            inst.components.follower:AddLoyaltyTime(TUNING.PIG_LOYALTY_MAXTIME)
            items[item] = false
            break
        end
    end
end

local function AcceptQueenGift(inst, items)
    local behappy = false
    for item in pairs(items) do
        if item.prefab == "pigcrownhat" or item.prefab == "pig_scepter" then
            inst.components.inventory:Equip(SpawnPrefab(item.prefab))
            behappy = true
        elseif item.prefab == "relic_4" or item.prefab == "relic_5" then
            behappy = true
        end
    end
    if behappy then
        inst:PushEvent("behappy")
    end
end

local function TradeGivenItems(inst, items, rewards)
    local city = inst:HasTag("city2") and 2 or 1
    local economy = TheWorld.components.economy
    local econprefab = GetEconPrefab(inst)
    local tradeitems = economy:GetTradeItems(econprefab)
    local desc = economy:GetTradeItemDesc(econprefab)

    for item in pairs(items) do
        if not inst:HasTag("pigqueen")
            and (item.prefab == "trinket_giftshop_1"
                or (item.prefab == "trinket_giftshop_3" and inst:HasTag("city1"))) then
            inst:AddTag("recieved_trinket")
            inst:sayline(GetSpeechLine(inst, STRINGS.CITY_PIG_TALK_GIVE_TRINKET_REWARD))
            local reward = GIFT_TRINKETS[math.random(#GIFT_TRINKETS)]
            rewards[reward] = (rewards[reward] or 0) + 1
            items[item] = false
        else
            for _, tradeitem in ipairs(tradeitems or {}) do
                if tradeitem == item.prefab then
                    local reward, quanty = economy:MakeTrade(econprefab, city, inst, item.prefab)
                    if reward then
                        inst:AddTag("troqueihoje")
                        inst:sayline(string.format(GetSpeechLine(inst, STRINGS.CITY_PIG_TALK_GIVE_REWARD),
                            tostring(1), desc))
                        if item.components.stackable then
                            quanty = quanty * item.components.stackable.stacksize
                        end
                        rewards[reward] = (rewards[reward] or 0) + quanty
                        items[item] = false
                    end
                    break
                end
            end
        end
    end
end

-- 零钱合并成大额 oinc
local function ConsolidateOinc(rewards)
    rewards["oinc100"] = (rewards["oinc100"] or 0)
        + math.floor((rewards["oinc10"] or 0) / 10)
        + math.floor((rewards["oinc"] or 0) / 100)
    rewards["oinc10"] = (rewards["oinc10"] or 0) % 10
        + math.floor((rewards["oinc"] or 0) % 100 / 10)
    rewards["oinc"] = (rewards["oinc"] or 0) % 10
end

local function ReturnUnacceptedItems(inst, doer, items)
    for item, accepted in pairs(items) do
        if accepted then
            doer.components.inventory:GiveItem(item, nil,
                Vector3(TheSim:GetScreenPos(inst.Transform:GetWorldPosition())))
        else
            item:Remove()
        end
    end
end

local function GiveRewards(inst, doer, rewards)
    for prefab, amount in pairs(rewards) do
        while amount > 0 do
            local p = SpawnPrefab(prefab)
            if p.components.stackable then
                local sz = math.clamp(amount, 1, p.components.stackable.maxsize)
                p.components.stackable:SetStackSize(sz)
                amount = amount - sz
            else
                amount = amount - 1
            end
            doer.components.inventory:GiveItem(p, nil,
                Vector3(TheSim:GetScreenPos(inst.Transform:GetWorldPosition())))
        end
    end
end

local function OnAccept(inst, doer, item)
    local accepted, forgiven = CityBribes.Accept(inst, doer, item, OINC_VALUE[item.prefab],
        inst:HasTag("guard") and GUARD_BRIBE_THRESHOLD or CIVILIAN_BRIBE_THRESHOLD)
    if accepted then
        item:Remove()
        inst.sayline(inst, GetSpeechLine(inst, forgiven and STRINGS.CITY_PIG_TALK_FORGIVE_PLAYER
            or STRINGS.CITY_PIG_TALK_NOT_ENOUGH))
        return
    end

    local items, rewards = CollectGivenItems(item)

    if inst:HasTag("guard") then
        AcceptGuardContract(inst, doer, items)
    elseif inst:HasTag("pigqueen") then
        AcceptQueenGift(inst, items)
    end

    if not inst:HasTag("guard") then
        TradeGivenItems(inst, items, rewards)
    end

    ReturnUnacceptedItems(inst, doer, items)
    ConsolidateOinc(rewards)
    GiveRewards(inst, doer, rewards)
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("refuse")
    if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

--------------------------------------------------------------------------
-- 进食
--------------------------------------------------------------------------

local function OnEat(inst, food)
    if food.components.edible
        and food.components.edible.foodtype == "MEAT"
        and inst.components.werebeast
        and not inst.components.werebeast:IsInWereState()
        and food.components.edible:GetHealth() < 0 then
        inst.components.werebeast:TriggerDelta(1)
    end

    if food.components.edible and food.components.edible.foodtype == "VEGGIE" then
        local poop = SpawnPrefab("poop")
        poop:AddTag("podepegar")
        poop.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

--------------------------------------------------------------------------
-- 战斗与卫兵
--------------------------------------------------------------------------

local function SpringMod(amt)
    if ClimateProfiles.IsHamletRainy(TheWorld.state) then
        return amt * SPRING_COMBAT_MOD
    end
    return amt
end

local function CalcSanityAura(inst, observer)
    if inst.components.werebeast
        and inst.components.werebeast:IsInWereState() then
        return -TUNING.SANITYAURA_LARGE
    end

    if inst.components.follower and inst.components.follower.leader == observer then
        return TUNING.SANITYAURA_SMALL
    end

    return 0
end

local function OnAttackedByDecidRoot(inst, attacker)
    local x, y, z = inst.Transform:GetWorldPosition()
    local radius = SpringMod(SHARE_TARGET_DIST) / 2
    local ents = TheSim:FindEntities(x, y, z, radius)

    local num_helpers = 0
    for _, v in pairs(ents) do
        if v ~= inst
            and v.components.combat
            and not (v.components.health and v.components.health:IsDead())
            and v:HasTag("pig")
            and not v:HasTag("werepig")
            and not v:HasTag("guard")
            and v:PushEvent("suggest_tree_target", { tree = attacker }) then
            num_helpers = num_helpers + 1
            if num_helpers >= MAX_TARGET_SHARES then
                break
            end
        end
    end
end

local function CallGuards(inst, attacker)
    local x, y, z = inst.Transform:GetWorldPosition()

    -- 已经有足够的卫兵在场就不再叫人
    local guards = TheSim:FindEntities(x, y, z, CALL_GUARD_DIST, { "guard" }, { "mermguard" })
    if #guards > 1 then
        return
    end

    local entrances = TheSim:FindEntities(x, y, z, CALL_GUARD_DIST, { "guard_entrance" })
    if #entrances == 0 then
        return
    end

    local guardprefab = "pigman_royalguard"
    local cityID = 1
    if inst:HasTag("city2") then
        guardprefab = "pigman_royalguard_2"
        cityID = 2
    end

    local spawnpt = Vector3(entrances[math.random(#entrances)].Transform:GetWorldPosition())
    local guard = SpawnPrefab(guardprefab)
    guard.components.citypossession:SetCity(cityID)
    guard.Transform:SetPosition(spawnpt.x, spawnpt.y, spawnpt.z)
    guard:PushEvent("attacked", { attacker = attacker, damage = 0, weapon = nil })

    guard:AddComponent("timer")
    guard:ListenForEvent("timerdone", OnLeaveTimerDone)
    guard.components.timer:StartTimer("vaiembora", 240)

    if attacker then
        attacker:AddTag("wanted_by_guards")
    end
end

local function ScheduleGuardCall(inst, attacker)
    inst.task_guard1 = inst:DoTaskInTime(math.random(1) + 1, function()
        CallGuards(inst, attacker)
    end)
    inst.task_guard2 = inst:DoTaskInTime(math.random(1) + 1.5, function()
        CallGuards(inst, attacker)
    end)
end

local function ShareAttackedTargetAsGuard(inst, attacker)
    if attacker:HasTag("player") then
        inst:AddTag("angry_at_player")
    end
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST,
        function(dude)
            return dude:HasTag("pig") and (dude:HasTag("guard") or not attacker:HasTag("pig"))
        end,
        MAX_TARGET_SHARES)
end

-- 平民不把猪卫兵的攻击当作敌意
local function ShareAttackedTargetAsCivilian(inst, attacker)
    if attacker:HasTag("pig") and attacker:HasTag("guard") then
        return
    end
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST,
        function(dude) return dude:HasTag("pig") end, MAX_TARGET_SHARES)
end

local function OnAttacked(inst, data)
    local attacker = data.attacker
    inst:ClearBufferedAction()
    if not attacker then
        return
    end

    if attacker.prefab == "deciduous_root" then
        if attacker.owner then
            OnAttackedByDecidRoot(inst, attacker.owner)
        end
    else
        inst.components.combat:SetTarget(attacker)

        if inst:HasTag("guard") then
            ShareAttackedTargetAsGuard(inst, attacker)
        else
            ShareAttackedTargetAsCivilian(inst, attacker)
        end
    end

    if inst:HasTag("shopkeep") or inst:HasTag("pigqueen") then
        ScheduleGuardCall(inst, attacker)
    end
end

--------------------------------------------------------------------------
-- 行为参数
--------------------------------------------------------------------------

local function NormalRetargetFn(inst)
    return FindEntity(inst, CITY_PIG_GUARD_TARGET_DIST, function(guy)
        if guy.LightWatcher and not guy.LightWatcher:IsInLight() then
            return false
        end

        if guy:HasTag("player") and inst:HasTag("angry_at_player")
            and guy.components.health and not guy.components.health:IsDead()
            and inst.components.combat:CanTarget(guy) then
            inst.sayline(inst, GetSpeechLine(inst, STRINGS.CITY_PIG_GUARD_TALK_ANGRY_PLAYER))
        end

        return (guy:HasTag("monster") or guy:HasTag("merm") or (guy:HasTag("player") and inst:HasTag("angry_at_player")))
            and guy.components.health and not guy.components.health:IsDead()
            and inst.components.combat:CanTarget(guy)
            and not (inst.components.follower.leader ~= nil and guy:HasTag("abigail"))
    end)
end

-- 放弃已死亡、在黑暗中或正在变身的目标
local function NormalKeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
        and (not target.LightWatcher or target.LightWatcher:IsInLight())
        and not (target.sg and target.sg:HasStateTag("transform"))
end

local function NormalShouldSleep(inst)
    if inst.components.follower and inst.components.follower.leader then
        local fire = FindEntity(inst, 6, function(ent)
            return ent.components.burnable
                and ent.components.burnable:IsBurning()
        end, { "campfire" })
        return DefaultSleepTest(inst) and fire and (not inst.LightWatcher or inst.LightWatcher:IsInLight())
    end
    return DefaultSleepTest(inst)
end

--------------------------------------------------------------------------
-- 收钱消气
--------------------------------------------------------------------------

local function SetNormalPig(inst)
    inst:RemoveTag("werepig")
    inst:RemoveTag("guard")

    inst.components.sleeper:SetResistance(2)

    inst.components.combat:SetDefaultDamage(PIG_DAMAGE)
    inst.components.combat:SetAttackPeriod(PIG_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(NormalKeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)
    inst.components.combat:SetTarget(nil)
    inst.components.locomotor.runspeed = PIG_RUN_SPEED
    inst.components.locomotor.walkspeed = PIG_WALK_SPEED

    inst.components.sleeper:SetSleepTest(NormalShouldSleep)
    inst.components.sleeper:SetWakeTest(DefaultWakeTest)

    inst.components.lootdropper:SetLoot({})
    inst.components.lootdropper:AddRandomLoot("meat", 3)
    inst.components.lootdropper:AddRandomLoot("pigskin", 1)
    inst.components.lootdropper.numrandomloot = 1

    if inst:HasTag("shopkeep") then
        inst.components.health:SetMaxHealth(20000)
    else
        inst.components.health:SetMaxHealth(PIG_HEALTH)
    end

    inst:ListenForEvent("suggest_tree_target", function(inst, data)
        if data and data.tree and inst:GetBufferedAction() ~= ACTIONS.CHOP then
            inst.tree_target = data.tree
        end
    end)

    inst.components.trader:Enable()
    inst.components.talker:StopIgnoringAll()

    inst:SetBrain(CityPigBrain)
    inst:SetStateGraph("SGpig_city")

    inst:WatchWorldState("isday", function(inst)
        if inst:HasTag("shopkeep") then
            local bancada = GetClosestInstWithTag("moveporco", inst, 25)
            if bancada then
                local x, y, z = bancada.Transform:GetWorldPosition()
                inst.Transform:SetPosition(x, y, z)
            end
        end
    end)
end

--------------------------------------------------------------------------
-- 存档
--------------------------------------------------------------------------

local function SavePig(inst, data)
    data.build = inst.build
    data.children = {}

    if inst.desk then
        table.insert(data.children, inst.desk.GUID)
        data.desk = inst.desk.GUID
    end

    data.daily_gift = inst.daily_gift
    data.atdesk = inst:HasTag("atdesk") or nil
    data.guards_called = inst:HasTag("guards_called") or nil
    data.doSpawnGuardTask = (inst.task_guard1 or inst.task_guard2) or nil
    data.angryatplayer = inst:HasTag("angry_at_player") or nil
    data.recieved_trinket = inst:HasTag("recieved_trinket") or nil
    data.paytax = inst:HasTag("paytax") or nil

    if #data.children > 0 then
        return data.children
    end
end

local function LoadPig(inst, data)
    if not data then
        return
    end

    inst.build = data.build or builds[1]

    if data.atdesk then
        inst.sg:GoToState("desk_pre")
    end
    if data.guards_called then
        inst:AddTag("guards_called")
    end
    -- data.equipped（旧版真实装备标记）已废弃，忽略
    if data.daily_gift then
        inst.daily_gift = data.daily_gift
    end
    if data.angryatplayer then
        inst:AddTag("angry_at_player")
    end
    if data.recieved_trinket then
        inst:AddTag("recieved_trinket")
    end
    if data.paytax then
        inst:AddTag("paytax")
    end
end

local function LoadPigPostPass(inst, ents, data)
    if not data or not data.children then
        return
    end

    for guid, _ in pairs(data.children) do
        local item = ents[guid]
        if item and data.desk == guid then
            inst.desk = item.entity
            inst:AddComponent("homeseeker")
            inst.components.homeseeker:SetHome(inst.desk)
        end
    end
end

--------------------------------------------------------------------------
-- 变体装配（主客机共用部分在 BuildPig，主机的差异部分在这里追加）
--------------------------------------------------------------------------

-- 卫兵的虚拟装备：不生成真实物品，仅用 overridesymbol 显示外观，
-- 攻击力取对应武器的初始攻击力；按 prefab 覆盖
local GUARD_DEFAULT_LOADOUT =
{
    weapon_swap = "swap_halberd", -- halberd 的 swap build
    weapon_damage = TUNING.HALBERD_DAMAGE,
}
local GUARD_LOADOUTS =
{
    pig_eskimo =
    {
        weapon_swap = "swap_spear", -- spear 的 swap build
        weapon_damage = TUNING.SPEAR_DAMAGE,
    },
}

local function GetGuardLoadout(inst)
    return GUARD_LOADOUTS[inst.prefab] or GUARD_DEFAULT_LOADOUT
end

-- 用 overridesymbol 显示虚拟的武器与木甲，攻击力与原真实装备一致
local function ApplyGuardLoadout(inst)
    local loadout = GetGuardLoadout(inst)

    inst.AnimState:OverrideSymbol("swap_object", loadout.weapon_swap, loadout.weapon_swap)
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
    inst.AnimState:OverrideSymbol("swap_body", "armor_wood", "swap_body")

    inst.components.combat:SetDefaultDamage(loadout.weapon_damage)

    -- 死亡动画只渲染 ARM_normal 层，死亡时还原手臂并清掉虚拟武器
    inst:ListenForEvent("death", function(inst)
        inst.AnimState:Show("ARM_normal")
        inst.AnimState:Hide("ARM_carry")
        inst.AnimState:ClearOverrideSymbol("swap_object")
    end)
end

local function SetupGuard(inst)
    -- SetNormalPig 会摘掉 guard 标签，这里补回（其余卫兵标签在注册处的 opts.tags 里，客机也生效）
    inst:AddTag("guard")

    inst:RemoveComponent("sleeper")
    inst.components.burnable:SetBurnTime(2)

    ApplyGuardLoadout(inst)

    inst:WatchWorldState("isnight", function()
        local lines = STRINGS.CITY_PIG_GUARD_LIGHT_TORCH.DEFAULT
        inst.sayline(inst, lines[math.random(#lines)])
    end)

    inst:SetBrain(RoyalPigGuardBrain)
end

local function SetupShopkeeper(inst)
    inst:DoTaskInTime(0, function()
        inst.desklocation = Vector3(inst.Transform:GetWorldPosition())
    end)

    TheWorld:ListenForEvent("enterroom", function()
        ShopkeeperSpeech(inst, GetSpeechLine(inst, STRINGS.CITY_PIG_SHOPKEEPER_GREETING))
    end)

    inst:WatchWorldState("isnight", function()
        CloseShop(inst)
    end)

    inst.special_action = function()
        inst.sg:GoToState("desk_pre")
    end
end

local function SetupQueen(inst)
    inst.components.trader.deleteitemonaccept = false
    inst.components.named.possiblenames = STRINGS.QUEENPIGNAMES
    inst.components.named:PickNewName()
end

local function SetupMechanic(inst)
    -- 延迟一帧装备锤子，让存档加载的装备先生效
    inst:DoTaskInTime(0, function()
        if not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
            inst.components.inventory:Equip(SpawnPrefab("hammer"))
        end
    end)
end

--------------------------------------------------------------------------
-- 实体构建
--------------------------------------------------------------------------

local function AddTags(inst, tags)
    for _, tag in ipairs(tags or {}) do
        inst:AddTag(tag)
    end
end

local function SetupTalker(inst, name)
    inst:AddComponent("talker")
    inst.components.talker.ontalk = OnTalk
    inst.components.talker.donetalkingfn = OnTalkFinish
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -600, 0)
    inst.talkertype = name
    inst.sayline = SayLine
end

local function CollectNames(inst, sex)
    -- 女王只从女王的名称列表取名，其余职业是 UNISEX 加上性别列表
    local names = {}

    if sex == "QUEEN" then
        inst.female = true
        for _, name in ipairs(STRINGS.CITYPIGNAMES["QUEEN"]) do
            table.insert(names, name)
        end
    else
        for _, name in ipairs(STRINGS.CITYPIGNAMES["UNISEX"]) do
            table.insert(names, name)
        end

        if sex then
            inst.female = sex ~= "MALE"
            for _, name in ipairs(STRINGS.CITYPIGNAMES[sex]) do
                table.insert(names, name)
            end
        end
    end

    return names
end

local function GetStatus(inst)
    if inst:HasTag("guard") then
        return "GUARD"
    elseif inst.components.follower.leader ~= nil then
        return "FOLLOWER"
    end
end

-- special_action 由 main/actions.lua 以 act.doer.special_action(act) 调用，
-- 首参是 act 而非实体，因此必须用闭包捕获 inst
local function MakeSpecialAction(inst)
    return function()
        if inst.daily_gifting then
            inst.sg:GoToState("daily_gift")
        elseif inst.poop_tip then
            inst.sg:GoToState("poop_tip")
        elseif inst:HasTag("paytax") then
            inst.sg:GoToState("pay_tax")
        end
    end
end

local function ThrowCrackers(inst)
    local cracker = SpawnPrefab("firecrackers")
    inst.components.inventory:GiveItem(cracker)

    local pos = Vector3(inst.Transform:GetWorldPosition())
    local start_angle = inst.Transform:GetRotation()
    local radius = 5
    local attempts = 12

    local test_fn = function(offset)
        local ents = TheSim:FindEntities(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z, 2, nil, { "INLIMBO" })
        return #ents == 0
    end

    local pt, new_angle = FindValidPositionByFan(start_angle, radius, attempts, test_fn)
    if new_angle then
        inst.Transform:SetRotation(new_angle / DEGREES)
    end

    local rot = inst.Transform:GetRotation() * DEGREES
    local tossdir = Vector3(math.cos(rot), 0, -math.sin(rot))

    inst.components.inventory:DropItem(cracker, nil, nil, nil, nil, tossdir)
    cracker.components.burnable:Ignite()
end

-- opts 字段：
--   build          必填，动画 build 名
--   tags           额外标签列表
--   sex            "MALE"/"FEMALE"/"QUEEN"
--   econprefab     经济系统使用的 prefab 名（默认用自身 prefab）
--   physics_radius 物理碰撞半径（默认 0.5）
--   fixer          添加 fixer 组件
--   shopkeeper     店主变体：影响公共组件（不添加 embarker、不禁用死亡掉落）
--   postinitfn     主机端公共构建完成后的变体装配函数（SetupGuard/SetupShopkeeper/SetupQueen/SetupMechanic）
local function BuildPig(name, opts)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.entity:AddLightWatcher()
    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    SetupTalker(inst, name)

    MakeCharacterPhysics(inst, 50, opts.physics_radius or 0.5)

    inst:AddTag("character")
    inst:AddTag("pig")
    inst:AddTag("civilized")
    inst:AddTag("scarytoprey")
    inst:AddTag("city_pig")
    AddTags(inst, opts.tags)

    if opts.shopkeeper then
        inst.AnimState:AddOverrideBuild("townspig_shop_wip")
        inst:AddTag("shopkeep")
        inst.separatedesk = SetAtDesk
        inst.shopkeeper_speech = ShopkeeperSpeech
    end

    inst.AnimState:SetBank("townspig")
    inst.AnimState:SetBuild(opts.build)
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:Hide("hat")
    inst.AnimState:Hide("desk")
    inst.AnimState:Hide("ARM_carry")
    inst.daily_gift = 0

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor") -- locomotor 必须在 stategraph 之前构建
    inst.components.locomotor.runspeed = PIG_RUN_SPEED
    inst.components.locomotor.walkspeed = PIG_WALK_SPEED

    if not opts.shopkeeper then
        inst.components.locomotor:SetAllowPlatformHopping(true)
        inst:AddComponent("embarker")
    end

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetCanEatRaw()
    inst.components.eater.strongstomach = true -- 可以吃怪物肉
    inst.components.eater:SetOnEatFn(OnEat)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "pig_torso"

    MakeMediumBurnableCharacter(inst, "pig_torso")

    inst:AddComponent("named")
    inst.components.named.possiblenames = CollectNames(inst, opts.sex)
    inst.components.named:PickNewName()

    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = PIG_LOYALTY_MAXTIME

    inst:AddComponent("health")
    inst:AddComponent("sleeper")
    inst:AddComponent("inventory")
    if not opts.shopkeeper then
        inst.components.inventory:DisableDropOnDeath()
    end
    inst:AddComponent("lootdropper")
    inst:AddComponent("knownlocations")
    inst:AddComponent("citypossession")

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnAccept
    inst.components.trader.onrefuse = OnRefuseItem

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    MakeMediumFreezableCharacter(inst, "pig_torso")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    if opts.econprefab then
        inst.econprefab = opts.econprefab
        inst.components.inspectable.nameoverride = opts.econprefab
    end

    inst.special_action = MakeSpecialAction(inst)

    inst.OnSave = SavePig
    inst.OnLoad = LoadPig
    inst.OnLoadPostPass = LoadPigPostPass

    inst:ListenForEvent("attacked", OnAttacked)
    inst.throwcrackers = ThrowCrackers

    SetNormalPig(inst)

    if opts.fixer then
        inst:AddComponent("fixer")
    end

    inst:WatchWorldState("isday", function(inst)
        if inst:HasTag("troqueihoje") then
            inst:RemoveTag("troqueihoje")
        end
    end)

    if opts.postinitfn then
        opts.postinitfn(inst)
    end

    return inst
end

--------------------------------------------------------------------------
-- Prefab 注册
--------------------------------------------------------------------------

local function makepigman(name, opts)
    return Prefab("common/objects/" .. name, function()
        return BuildPig(name, opts)
    end, assets, prefabs)
end

return
    makepigman("pigman_beautician", { build = "pig_beautician", sex = "FEMALE" }),
    makepigman("pigman_florist", { build = "pig_florist", sex = "FEMALE" }),
    makepigman("pigman_erudite", { build = "pig_erudite", tags = { "emote_nohat" }, sex = "FEMALE" }),
    makepigman("pigman_hatmaker", { build = "pig_hatmaker", sex = "FEMALE" }),
    makepigman("pigman_storeowner", { build = "pig_storeowner", tags = { "emote_nohat" }, sex = "FEMALE" }),
    makepigman("pigman_banker", { build = "pig_banker", tags = { "emote_nohat" }, sex = "MALE" }),
    makepigman("pigman_collector", { build = "pig_collector", sex = "MALE" }),
    makepigman("pigman_hunter", { build = "pig_hunter", sex = "MALE" }),
    makepigman("pigman_mayor", { build = "pig_mayor", sex = "MALE" }),
    makepigman("pigman_mechanic", { build = "pig_mechanic", fixer = true, postinitfn = SetupMechanic, sex = "MALE" }),
    makepigman("pigman_professor", { build = "pig_professor", tags = { "emote_nohat" }, sex = "MALE" }),
    makepigman("pigman_usher", { build = "pig_usher", tags = { "emote_nohat" }, sex = "MALE" }),
    makepigman("pigman_royalguard", { build = "pig_royalguard", tags = GUARD_TAGS, postinitfn = SetupGuard, sex = "MALE" }),
    makepigman("pigman_royalguard_2", { build = "pig_royalguard_2", tags = GUARD_TAGS, postinitfn = SetupGuard, sex = "MALE" }),
    makepigman("pigman_farmer", { build = "pig_farmer", sex = "MALE" }),
    makepigman("pigman_miner", { build = "pig_miner", sex = "MALE" }),
    makepigman("pigman_queen",
        { build = "pig_queen", tags = { "pigqueen", "emote_nohat" }, sex = "QUEEN", postinitfn = SetupQueen,
            physics_radius = 0.75 }),
    makepigman("pigman_beautician_shopkeep",
        { build = "pig_beautician", shopkeeper = true, postinitfn = SetupShopkeeper, sex = "FEMALE",
            econprefab = "pigman_beautician" }),
    makepigman("pigman_florist_shopkeep",
        { build = "pig_florist", shopkeeper = true, postinitfn = SetupShopkeeper, sex = "FEMALE",
            econprefab = "pigman_florist" }),
    makepigman("pigman_erudite_shopkeep",
        { build = "pig_erudite", shopkeeper = true, postinitfn = SetupShopkeeper, tags = { "emote_nohat" },
            sex = "FEMALE", econprefab = "pigman_erudite" }),
    makepigman("pigman_hatmaker_shopkeep",
        { build = "pig_hatmaker", shopkeeper = true, postinitfn = SetupShopkeeper, sex = "FEMALE",
            econprefab = "pigman_hatmaker" }),
    makepigman("pigman_storeowner_shopkeep",
        { build = "pig_storeowner", shopkeeper = true, postinitfn = SetupShopkeeper, tags = { "emote_nohat" },
            sex = "FEMALE", econprefab = "pigman_storeowner" }),
    makepigman("pigman_banker_shopkeep",
        { build = "pig_banker", shopkeeper = true, postinitfn = SetupShopkeeper, tags = { "emote_nohat" },
            sex = "MALE", econprefab = "pigman_banker" }),
    makepigman("pigman_shopkeep",
        { build = "pig_banker", shopkeeper = true, postinitfn = SetupShopkeeper, sex = "MALE",
            econprefab = "pigman_banker" }), -- 默认店主
    makepigman("pigman_hunter_shopkeep",
        { build = "pig_hunter", shopkeeper = true, postinitfn = SetupShopkeeper, sex = "MALE",
            econprefab = "pigman_hunter" }),
    makepigman("pigman_mayor_shopkeep",
        { build = "pig_mayor", shopkeeper = true, postinitfn = SetupShopkeeper, sex = "MALE",
            econprefab = "pigman_mayor" }),
    makepigman("pigman_farmer_shopkeep",
        { build = "pig_farmer", shopkeeper = true, postinitfn = SetupShopkeeper, sex = "MALE",
            econprefab = "pigman_farmer" }),
    makepigman("pigman_miner_shopkeep",
        { build = "pig_miner", shopkeeper = true, postinitfn = SetupShopkeeper, sex = "MALE",
            econprefab = "pigman_miner" }),
    makepigman("pigman_collector_shopkeep",
        { build = "pig_collector", shopkeeper = true, postinitfn = SetupShopkeeper, sex = "MALE",
            econprefab = "pigman_collector" }),
    makepigman("pigman_professor_shopkeep",
        { build = "pig_professor", shopkeeper = true, postinitfn = SetupShopkeeper, tags = { "emote_nohat" },
            sex = "MALE", econprefab = "pigman_professor" }),
    makepigman("pigman_mechanic_shopkeep",
        { build = "pig_mechanic", shopkeeper = true, postinitfn = SetupShopkeeper, sex = "MALE",
            econprefab = "pigman_mechanic" }),
    makepigman("pigman_eskimo_shopkeep",
        { build = "pig_eskimo", shopkeeper = true, postinitfn = SetupShopkeeper, sex = "MALE",
            econprefab = "pig_eskimo" }),
    makepigman("pig_shopkeeper", { build = "pig_shopkeeper", sex = "MALE" }),
    makepigman("pig_royalguard_rich",
        { build = "pig_royalguard_rich", tags = GUARD_TAGS, postinitfn = SetupGuard, sex = "MALE" }),
    makepigman("pig_royalguard_rich_2",
        { build = "pig_royalguard_rich_2", tags = GUARD_TAGS, postinitfn = SetupGuard, sex = "MALE" }),
    makepigman("pigman_royalguard_3",
        { build = "pig_royalguard_3", tags = GUARD_TAGS, postinitfn = SetupGuard, sex = "MALE" }),
    makepigman("pig_eskimo", { build = "pig_eskimo", tags = GUARD_TAGS, postinitfn = SetupGuard, sex = "MALE" })
