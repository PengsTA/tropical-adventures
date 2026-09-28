local buffattr = {
    speedup = {
        coffee                = { priority = 5, mult = TUNING.COFFEE_SPEED_INCREASE + 1, duration = TUNING.BUFF_COFFEE_DURATION, name = "buff_speedup_tro_4", },
        coffeebean            = { priority = 4, mult = TUNING.COFFEE_SPEED_INCREASE + 1, duration = TUNING.BUFF_COFFEE_DURATION / 8, name = "buff_speedup_tro_4", },
        tropicalbouillabaisse = { priority = 3, mult = TUNING.BOUILLABAISSE_SPEED_MODIFIER, duration = TUNING.BUFF_BOUILLABAISSE_DURATION, name = "buff_speedup_tro_3", },
        tea                   = { priority = 2, mult = TUNING.COFFEE_SPEED_INCREASE / 2 + 1, duration = TUNING.BUFF_COFFEE_DURATION / 2, name = "buff_speedup_tro_2", },
        icedtea               = { priority = 1, mult = TUNING.COFFEE_SPEED_INCREASE / 3 + 1, duration = TUNING.BUFF_COFFEE_DURATION / 3, name = "buff_speedup_tro_1", },
    }
}

local fns = {
    speedup = {},
    poisoned = {},
    antitoxin = {},
}

fns.speedup.attach = function(inst, target, followsymbol, followoffset, data)
    if data then
        inst._debuffkey_tro = data.debuffkey
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", buffattr.speedup[data.debuffkey].duration)
    end
    if target.components.locomotor then
        target.components.locomotor:SetExternalSpeedMultiplier(inst, "speedup_tro", data and data.debuffkey and
            buffattr.speedup[data.debuffkey].mult or inst._debuffkey_tro and buffattr.speedup[inst._debuffkey_tro].mult or 1) -- 进入世界时
        if target.components.medal_showbufftime then
            inst.nameoverride = buffattr.speedup[data and data.debuffkey or inst._debuffkey_tro].name -- data优先
            target.components.medal_showbufftime:SetBuffInfo()
            target.replica.medal_showbufftime:GetBuffInfo()
        end
    end
end

fns.speedup.extend = function(inst, target, followsymbol, followoffset, data)
    if not inst._debuffkey_tro then
        fns.speedup.attach(inst, target, followsymbol, followoffset, data)
    end
    if not data then return end
    if buffattr.speedup[data.debuffkey].priority > buffattr.speedup[inst._debuffkey_tro].priority then
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", buffattr.speedup[data.debuffkey].duration)
        if target.components.locomotor then
            target.components.locomotor:RemoveExternalSpeedMultiplier(inst, "speedup_tro")
            target.components.locomotor:SetExternalSpeedMultiplier(inst, "speedup_tro", buffattr.speedup[data.debuffkey].mult)
            if target.components.medal_showbufftime then
                inst.nameoverride = buffattr.speedup[data.debuffkey].name
                target.components.medal_showbufftime:SetBuffInfo()
                target.replica.medal_showbufftime:GetBuffInfo()
            end
        end
        inst._debuffkey_tro = data.debuffkey
    elseif data.debuffkey == inst._debuffkey_tro then
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", buffattr.speedup[data.debuffkey].duration)
    end
end

fns.speedup.detach = function(inst, target)
    if target.components.locomotor then
        target.components.locomotor:RemoveExternalSpeedMultiplier(inst, "speedup_tro")
    end
    inst._debuffkey_tro = nil
end

--------------------------------------------------------------------------
-- 中毒 debuff：承载全部毒逻辑（跳伤、间隔递增、掉落腐败、气泡特效、HUD 同步）。
-- 状态以 AddDebuff 的 data 传入：{ dmg, interval, duration }。
-- 存档：debuffable:OnSave 会把本实体整个序列化进宿主存档并在读档时重建；
-- "buffover" 剩余时间由 timer 组件自动恢复，数值字段由下方 OnSave/OnLoad 恢复。
local POISON_DEFAULT_DURATION = 60 * 16
local POISON_MAX_INTERVAL = 5
local POISON_MIN_INTERVAL = 1
local POISON_CURE_TAGS = { "weremoose", "weregoose", "beaver", "playerghost" }

local function SpoilLoot(inst, loot)
    if loot.components.perishable then
        loot.components.perishable:SetPercent(0.5 * loot.components.perishable:GetPercent())
    end
    return loot
end

local function FollowBurnSymbol(fx, target)
    local burnable = target.components.burnable
    if burnable and #burnable.fxdata > 0 then
        local symbol = burnable.fxdata[1].follow
        if symbol then
            fx.Follower:FollowSymbol(target.GUID, symbol, 0, 0, 0)
        end
    end
end

-- 保留旧 poisonable:IncreaseIntensity 的行为（progress = 起始时长/剩余时长，仅作用于 interval > 1 的毒）
local function IncreaseIntensity(inst)
    if inst.interval > POISON_MIN_INTERVAL then
        local left = inst.components.timer:GetTimeLeft("buffover")
        if left ~= nil and left > 0 then
            inst.interval = math.max(inst.startDuration / left * POISON_MAX_INTERVAL, POISON_MIN_INTERVAL)
        end
    end
end

local function PoisonDisplay(inst, target)
    inst.nameoverride = "buff_poisoned_tro"
    if target.player_classified ~= nil then
        target.player_classified.poisonstate:set(1)
    end
    if target.components.medal_showbufftime ~= nil then
        target.components.medal_showbufftime:SetBuffInfo()
        if target.replica ~= nil and target.replica.medal_showbufftime ~= nil then
            target.replica.medal_showbufftime:GetBuffInfo()
        end
    end
end

local function PoisonTick(inst)
    local target = inst.components.debuff.target
    if target == nil or not target:IsValid() then return end
    local health = target.components.health
    if health == nil or health:IsDead() then return end

    if target:HasOneOfTags(POISON_CURE_TAGS) then
        inst.components.debuff:Stop()
        return
    end

    inst.lastDamageTime = inst.lastDamageTime - FRAMES
    if inst.lastDamageTime <= 0 then
        health:DoDelta(inst.dmg, nil, "poison")
        IncreaseIntensity(inst)
        inst.lastDamageTime = inst.interval
        if target.player_classified ~= nil then
            target.player_classified.poisonover:set_local(true)
            target.player_classified.poisonover:set(true)
        end
    end

    if inst.poisonfx == nil and inst.dmg < 0 then
        inst.poisonfx = SpawnPrefab("poisonbubble_level1_loop")
        target:AddChild(inst.poisonfx)
        FollowBurnSymbol(inst.poisonfx, target)
    end
end

fns.poisoned.attach = function(inst, target, followsymbol, followoffset, data)
    if data ~= nil then
        inst.dmg = data.dmg or -1
        inst.interval = data.interval or POISON_MAX_INTERVAL
        inst.startDuration = data.duration or POISON_DEFAULT_DURATION
        inst.lastDamageTime = 0
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", inst.startDuration)
    end
    -- data == nil 为读档重挂：状态字段已由 OnLoad 恢复
    if target.components.lootdropper ~= nil then
        target.components.lootdropper:SetLootPostInit("poisoned", SpoilLoot)
    end
    PoisonDisplay(inst, target)
    if inst.ticktask == nil then
        inst.ticktask = inst:DoPeriodicTask(FRAMES, PoisonTick)
    end
end

fns.poisoned.extend = function(inst, target, followsymbol, followoffset, data)
    if data ~= nil then
        inst.dmg = data.dmg or inst.dmg
        inst.interval = data.interval or inst.interval
        inst.startDuration = data.duration or inst.startDuration -- 重置间隔递增基准（同旧 SetPoison 语义）
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", inst.startDuration)
    end
    if target.components.lootdropper ~= nil then
        target.components.lootdropper:SetLootPostInit("poisoned", SpoilLoot)
    end
    PoisonDisplay(inst, target)
    if inst.ticktask == nil then
        inst.ticktask = inst:DoPeriodicTask(FRAMES, PoisonTick)
    end
end

fns.poisoned.detach = function(inst, target)
    if inst.ticktask ~= nil then
        inst.ticktask:Cancel()
        inst.ticktask = nil
    end
    if inst.poisonfx ~= nil then
        inst.poisonfx:Remove()
        inst.poisonfx = nil
    end
    if target.components.lootdropper ~= nil then
        target.components.lootdropper:RemoveLootPostInit("poisoned")
    end
    if target.player_classified ~= nil then
        target.player_classified.poisonstate:set(0)
    end
end

local function PoisonedSetup(inst)
    -- 默认值兜底：读档重挂时 attach(data==nil) 之前先保证字段有合法初值
    inst.dmg = -1
    inst.interval = POISON_MAX_INTERVAL
    inst.startDuration = POISON_DEFAULT_DURATION
    inst.lastDamageTime = 0
    inst.OnSave = function(inst, data)
        data.dmg = inst.dmg
        data.interval = inst.interval
        data.startDuration = inst.startDuration
        data.lastDamageTime = inst.lastDamageTime
    end
    inst.OnLoad = function(inst, data)
        if data == nil then return end
        inst.dmg = data.dmg or inst.dmg
        inst.interval = data.interval or inst.interval
        inst.startDuration = data.startDuration or inst.startDuration
        inst.lastDamageTime = data.lastDamageTime or inst.lastDamageTime
    end
end
fns.poisoned.setup = PoisonedSetup

--------------------------------------------------------------------------
-- 解毒免疫 debuff：timer 到期自然解除，免疫期间毒素命中按剩余时长吸收（见 TroApplyPoison）
local function AntitoxinDisplay(inst, target)
    inst.nameoverride = "buff_antitoxin_tro"
    if target.player_classified ~= nil then
        target.player_classified.poisonstate:set(2)
    end
    if target.components.medal_showbufftime ~= nil then
        target.components.medal_showbufftime:SetBuffInfo()
        if target.replica ~= nil and target.replica.medal_showbufftime ~= nil then
            target.replica.medal_showbufftime:GetBuffInfo()
        end
    end
end

fns.antitoxin.attach = function(inst, target, followsymbol, followoffset, data)
    if data ~= nil and data.duration ~= nil then
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", data.duration)
    end
    AntitoxinDisplay(inst, target)
end

fns.antitoxin.extend = function(inst, target, followsymbol, followoffset, data)
    if data ~= nil and data.duration ~= nil then
        local left = inst.components.timer:GetTimeLeft("buffover") or 0
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", math.max(left, data.duration))
    end
    AntitoxinDisplay(inst, target)
end

fns.antitoxin.detach = function(inst, target)
    if target.player_classified ~= nil then
        target.player_classified.poisonstate:set(0)
    end
end

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function onsave(inst, data)
    if inst._debuffkey_tro then
        data._debuffkey_tro = inst._debuffkey_tro
    end
end

local function onload(inst, data)
    if data._debuffkey_tro then
        inst._debuffkey_tro = data._debuffkey_tro
    end
end

local function MakeBuff(name, duration, priority, prefabs)
    local ATTACH_BUFF_DATA = {
        -- buff = "ANNOUNCE_ATTACH_BUFF_"..string.upper(name),
        priority = priority
    }
    local DETACH_BUFF_DATA = {
        -- buff = "ANNOUNCE_DETACH_BUFF_"..string.upper(name),
        priority = priority
    }

    local function OnAttached(inst, target, ...)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)

        target:PushEvent("foodbuffattached", ATTACH_BUFF_DATA)
        if fns[name].attach ~= nil then
            fns[name].attach(inst, target, ...)
        end
    end

    local function OnExtended(inst, target, ...)
        if duration and duration > 0 then
            inst.components.timer:StopTimer("buffover")
            inst.components.timer:StartTimer("buffover", duration)
        end

        target:PushEvent("foodbuffattached", ATTACH_BUFF_DATA)
        if fns[name].extend ~= nil then
            fns[name].extend(inst, target, ...)
        end
    end

    local function OnDetached(inst, target, ...)
        if fns[name].detach ~= nil then
            fns[name].detach(inst, target)
        end

        target:PushEvent("foodbuffdetached", DETACH_BUFF_DATA)
        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        if not TheWorld.ismastersim then
            --Not meant for client!
            inst:DoTaskInTime(0, inst.Remove)
            return inst
        end

        inst.entity:AddTransform()

        --[[Non-networked entity]]
        --inst.entity:SetCanSleep(false)
        inst.entity:Hide()
        inst.persists = false

        inst:AddTag("CLASSIFIED")

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("buffover", duration)
        inst:ListenForEvent("timerdone", OnTimerDone)

        if TUNING.FUNCTIONAL_MEDAL_IS_OPEN then
        end

        if duration == 0 then
            inst.OnSave = onsave
            inst.OnLoad = onload
        end

        if fns[name].setup ~= nil then
            fns[name].setup(inst)
        end

        return inst
    end

    return Prefab("buff_" .. name .. "_tro", fn, nil, prefabs)
end

local function MakeDynBuff(name, priority)
    return MakeBuff(name, 0, priority)
end

-- Make dynamic buffs
return MakeDynBuff("speedup", 2),
    MakeDynBuff("poisoned", 1),
    MakeDynBuff("antitoxin", 1)

-- Runar: These are here to make this file findable.
-- buff_speedup_tro
-- buff_speedup_tro_1
-- buff_speedup_tro_2
-- buff_speedup_tro_3
-- buff_speedup_tro_4
-- buff_poisoned_tro
-- buff_antitoxin_tro
