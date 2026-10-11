--ham room tuning-----------------
----------------------------------
local seg_time = TUNING.SEG_TIME
local day_time = TUNING.DAY_SEGS_DEFAULT * seg_time
local dusk_time = TUNING.DUSK_SEGS_DEFAULT * seg_time
local night_time = TUNING.NIGHT_SEGS_DEFAULT * seg_time
local total_day_time = TUNING.TOTAL_DAY_TIME

local wilson_attack = TUNING.SPEAR_DAMAGE
local wilson_health = TUNING.WILSON_HEALTH


local tuning_origin = require "datadefs/tuning_origin"

tableutil.deep_merge(TUNING, tuning_origin)

TUNING.BUILD_HEIGHT = 0 ---rpc用来接收建筑高度数据-------也可以修改placer
TUNING.FAN_RANGE = 30
TUNING.FOG_MOISTURE_RATE = 1000

TUNING.TROPICAL_ADVENTURE_ACTIVATED = true

TUNING.HAMROOM = {
    roomcamera = {
        pitch = 35,
        fov = 35,
        minimum_distance = 20,
        height_offset = -1,
        focus_back_offset = 3,
        profiles = {
            default = {
                distance = 21,
                focus_back_offset = 2.5,
            },
            shop = {
                distance = 23,
            },
            player_house = {
                distance = 25,
            },
            palace = {
                distance = 38,
                focus_back_offset = 4,
            },
            cave = {
                distance = 33,
                focus_back_offset = 3,
            },
        },
    },

}


TUNING.HAMROOM.roomcamera.profiles = require("tools/room_camera_profiles").CreateProfiles(TUNING.HAMROOM.roomcamera.profiles)

TUNING.tro_pairedkey = {
    qe = { 113, 101 },
    du = { 274, 273 },
    lr = { 276, 275 },
    mp = { 45, 61 },
    pp = { 281, 280 },
    he = { 278, 279 }
}

--buff----------------------------
----------------------------------
TUNING.COFFEE_SPEED_INCREASE = 5 / 6
TUNING.BUFF_COFFEE_DURATION = TUNING.TOTAL_DAY_TIME / 2
TUNING.BOUILLABAISSE_SPEED_MODIFIER = 1.5
TUNING.BUFF_BOUILLABAISSE_DURATION = TUNING.SEG_TIME

--glass---------------------------
----------------------------------
TUNING.SWP_SHARD_DMG = {
    BEAK = 51,
    SWORD = 50,
    SHADOW_MODIFIER_MINIMUM = 2,
    SHADOW_MODIFIER_MAXIMUM = 8,
    STRUCTURE_MODIFIER = 3,
    SWEEP_MODIFIER = .5,
}

--cloak----------------------------
----------------------------------
--漩涡斗篷/虚空斗篷
local vortex_armor = 450 --漩涡斗篷护甲耐久 450
local void_armor = 855 --虚空斗篷护甲耐久 855

TUNING.VORTEX_CLOAK =
{
    ARMOR = vortex_armor,                                         --护甲耐久
    ARMOR_ABSORPTION = 1,                                         --减伤比例
    SANITY_DMG_AS_SANITY = TUNING.ARMOR_SANITY_DMG_AS_SANITY * 3, --受击时伤害转化为san损失的比例(护甲san损的3倍)
    SHADOW_LEVEL = TUNING.ARMOR_SANITY_SHADOW_LEVEL,              --影甲的老麦2级暗影之力
}

TUNING.VOID_CLOAK =
{
    ARMOR = void_armor,                                           --护甲耐久
    ARMOR_ABSORPTION = TUNING.VORTEX_CLOAK.ARMOR_ABSORPTION,      --减伤比例
    PLANAR_DEF = TUNING.ARMOR_VOIDCLOTH_PLANAR_DEF,               --位面防御
    SHADOW_RESIST = TUNING.ARMOR_VOIDCLOTH_SHADOW_RESIST,         --暗影阵营伤害减免
    SHADOW_LEVEL = TUNING.ARMOR_VOIDCLOTH_SHADOW_LEVEL,           --老麦3级暗影之力
    IMMORTAL_MAXLEVEL = 5,                                        --最大不朽等级
    IMMORTAL_ARMOR_MULT = 19,                                     --不朽之力的护甲耐久倍率基数
    IMMORTAL_ARMOR_BONUS = 3,                                     --每级不朽之力的护甲耐久倍率加成
    CHAOS_DEF = 3,                                                --每级不朽之力提供的混沌防御
    IMMORTAL_PLANAR_DEF = 1,                                      --每级不朽之力提供的位面防御
    IMMORTAL_FRUIT_REPAIR = 90,                                   --单个不朽果实可修补的耐久
}

TUNING.TROREPAIR = {
    CLOAKCOMMON = {
        nightmarefuel = 45,
        horrorfuel = 90,
        ancient_remnant = 450,
    }
}

TUNING.ARMOROBSIDIAN = TUNING.DEFAULT_CHARACTER_HEALTH * 9

TUNING.ANCIENT_HULK_HEALTH = 8000 --* TUNING.tropical.bosslife
TUNING.ANCIENT_HULK_DAMAGE = 200
TUNING.ANCIENT_HULK_MINE_DAMAGE = 100
TUNING.ANCIENT_HULK_MELEE_RANGE = 5.5
TUNING.ANCIENT_HULK_ATTACK_RANGE = 5.5
TUNING.ANCIENT_HULK_SPEED = 60
TUNING.IRON_LORD_TIME = 180

--constants-----------------------
----------------------------------
---
GLOBAL.EQUIPSLOTS.BARCO = "barco"
rawset(GLOBAL, "BOATEQUIPSLOTS", rawget(GLOBAL, "BOATEQUIPSLOTS") or {
    BOAT_SAIL = "sail",
    BOAT_LAMP = "lamp",
})
rawset(GLOBAL, "BOAT_ANIM_IDS", rawget(GLOBAL, "BOAT_ANIM_IDS") or {
    row_pre = 1,
    row_loop = 2,
    row_pst = 3,
    sail_pre = 4,
    sail_loop = 5,
    sail_pst = 6,
    trawlover = 7,
    idle_loop = 8,
    hit = 9,
    run_loop = 10,
})
rawset(GLOBAL, "BOAT_ID_TO_ANIM", rawget(GLOBAL, "BOAT_ID_TO_ANIM") or {})
for animname, id in pairs(rawget(GLOBAL, "BOAT_ANIM_IDS")) do
    rawget(GLOBAL, "BOAT_ID_TO_ANIM")[id] = animname
end
rawset(GLOBAL, "LOOP_BOAT_ANIMS", rawget(GLOBAL, "LOOP_BOAT_ANIMS") or {
    row_loop = true,
    sail_loop = true,
    idle_loop = true,
    run_loop = true,
})
GLOBAL.FUELTYPE.TAR = "TAR"
GLOBAL.FUELTYPE.REPARODEBARCO = "REPARODEBARCO"
GLOBAL.FUELTYPE.LIVINGARTIFACT = "LIVINGARTIFACT"
GLOBAL.FUELTYPE.ANCIENT_REMNANT = "ANCIENT_REMNANT"
GLOBAL.FUELTYPE.BLOOD = "BLOOD" --新增一个燃料值：血，可以用蚊子血嚢给蝙蝠帽回耐久
GLOBAL.MATERIALS.SANDBAG = "sandbag"

GLOBAL.TOOLACTIONS["HACK"] = true
GLOBAL.TOOLACTIONS["SHEAR"] = true
GLOBAL.TOOLACTIONS["PAN"] = true
GLOBAL.TOOLACTIONS["INVESTIGATEGLASS"] = true
GLOBAL.FUELTYPE.CORK = "CORK"

GLOBAL.MATERIALS.LIMESTONE = "limestone"
GLOBAL.MATERIALS.ENFORCEDLIMESTONE = "enforcedlimestone"

GLOBAL.ANTCHEST_PRESERVATION = {
    honey = true,
    royal_jelly = true,
    nectar_pod = true,
    pollen_item = true,
}

GLOBAL.SWP_WAVEBREAK_EFFICIENCY = { -- 破浪效率：var * 100%
    BUMPER = {
        kelp = .6,                  -- prefab = "boat_bumper_" .. k
        shell = .8,
        yotd = .8,
        crabking = 1,
    },
    BOAT = {
        boat = .3, -- prefab = k
        boat_pirate = .3,
        boat_ancient = .4,
        boatmetal = .9,
    }
}

local tuning = {
    LOTUS_REGROW_TIME = total_day_time * 5,

    MOSQUITO_LILYPAD_MAX_SPAWN = 1,
    MOSQUITO_LILYPAD_REGEN_TIME = day_time / 2,
    MOSQUITO_LILYPAD_RELEASE_TIME = 20,
    MOSQUITO_LILYPAD_ENABLED = true,

    FROG_POISON_LILYPAD_MAX_SPAWN = 1,
    FROG_POISON_LILYPAD_REGEN_TIME = day_time / 2,
    FROG_POISON_LILYPAD_RELEASE_TIME = 20,
    FROG_POISON_LILYPAD_ENABLED = true,

}

for k, v in pairs(tuning) do
    TUNING[k] = v
end

---一些没卵用的东西
TUNING.TFWP_SPEAR_GUNG =
{
    USES = 200,
    DAMAGE = 40,
    SPELL_DAMAGE = 75,
    RECHARGE = 15,
    DECAY_PER_CAST = 200 * 0.05,
}

TUNING.TFWP_LAVA_HAMMER =
{
    USES = 250,
    DAMAGE = 35,
    SPELL_DAMAGE = 50,
    RECHARGE = 15,
    DECAY_PER_CAST = 250 * 0.05,
}

TUNING.TFWP_SPEAR_LANCE =
{
    USES = 150,
    DAMAGE = 45,
    SPELL_DAMAGE = 150,
    RECHARGE = 15,
    DECAY_PER_CAST = 100 * 0.05,
}

TUNING.TFWP_SUMMON_BOOK =
{
    USES = 60,
    DAMAGE = 20,
    RECHARGE = 60,
    DECAY_PER_CAST = 60 * 0.1,
}

TUNING.TFWP_CONTROL_BOOK =
{
    USES = 60,
    DAMAGE = 20,
    RECHARGE = 45,
    DECAY_PER_CAST = 60 * 0.1,
}

TUNING.TFWP_HEALING_STAFF =
{
    USES = 80,
    DAMAGE = 20,
    RECHARGE = 30,
    HEALTH_PER_SECOND = 3,
    SANITY_PER_SECOND = 1,
    DECAY_PER_CAST = 80 * 0.1,
}

TUNING.TFWP_INFERNAL_STAFF =
{
    USES = 80,
    DAMAGE = 25,
    RECHARGE = 20,
    SPELL_DAMAGE = 300,
    DECAY_PER_CAST = 80 * 0.05,
}

TUNING.TFWP_DRAGON_DART =
{
    USES = 30,
    DAMAGE = 20,
    RECHARGE = 5,
    SPELL_DAMAGE = 60,
    DECAY_PER_CAST = 1,
}

TUNING.TFWP_LAVA_DART =
{
    USES = 40,
    DAMAGE = 15,
    RECHARGE = 15,
    SPELL_DAMAGE = 15,
    DECAY_PER_CAST = 2,
}

TUNING.TFWP_HEAVY_SWORD =
{
    USES = 300,
    DAMAGE = 37,
    SPELL_DAMAGE = 90,
}

--Elemetal
TUNING.TFWP_ELEMENTAL =
{
    HEALTH = 50,
    DAMAGE = 5,
    RANGE = 15,
    ATTACK_PERIOD = 0.7,
}



TUNING.OBSIDIAN_TOOL_MAXHEAT = 60


TUNING.SHARK_HAT_PERISHTIME = TUNING.EYEBRELLA_PERISHTIME

TUNING.SPOILED_FISH_LARGE_NUTRIENTS = { 24, 0, 0 }
TUNING.MYSTERYMEAT_NUTRIENTS = { 24, 24, 24 }

TUNING.JELLYFISH_WEIGHTS = {
    min = 61.55,
    max = 90.11,
}
TUNING.RAINBOWJELLYFISH_WEIGHTS = {
    min = 69.36,
    max = 118.21,
}

TUNING.BATHAT_PERISHTIME = TUNING.TOTAL_DAY_TIME * 2
TUNING.SCAN_DISTANCE = 30
TUNING.GOGGLES_PERISHTIME = TUNING.TOTAL_DAY_TIME * 10
TUNING.GOGGLES_HEAT_PERISHTIME = TUNING.TOTAL_DAY_TIME * 2
TUNING.GOGGLES_ARMOR_ARMOR = wilson_health * 4 * 0.7
TUNING.GOGGLES_ARMOR_ABSORPTION = 0.85
TUNING.GOGGLES_SHOOT_USES = 10
TUNING.NEARSIGHTED_BLUR_START_RADIUS = 0.0
TUNING.NEARSIGHTED_BLUR_STRENGTH = 3.0
TUNING.GOGGLES_HEAT =
{
    HOT =
    {
        BLOOM        = true,
        DESATURATION = 1.0,
        MULT_COLOUR  = { 0.0, 1.0, 0.5, 1.0 },
        ADD_COLOUR   = { 1.0, 0.1, 0.3, 1.0 },
    },
    COLD =
    {
        BLOOM        = false,
        DESATURATION = 0.7,
        MULT_COLOUR  = { 0.0, 0.0, 0.3, 1.0 },
        ADD_COLOUR   = { 0.1, 0.1, 0.5, 1.0 },
    },
    GROUND =
    {
        MULT_COLOUR = { 0.0, 0.1, 0.3, 1.0 },
        ADD_COLOUR  = { 0.1, 0.1, 0.5, 1.0 }
    },
    WAVES =
    {
        MULT_COLOUR = { 0.0, 0.0, 0.3, 1.0 },
        ADD_COLOUR  = { 0.1, 0.1, 0.6, 1.0 },
    },
    BLUR =
    {
        ENABLED = true,
        START_RADIUS = -5.0,
        STRENGTH = 0.16,
    }
}

TUNING.TELEBRELLA_USES = 10
TUNING.NEARSIGHTED_ACTION_RANGE = 4

TUNING.INVSLOT45 = false
for k, v in ipairs(_G.ModManager:GetEnabledServerModNames()) do
    if v == "workshop-786556008" or v == "workshop-2166704267" or v == "workshop-2801880191" or
        v == "workshop-2568821043" or v == "workshop-2886543901" then
        TUNING.INVSLOT45 = true
        break
    end
end

GLOBAL.BOATHUDPOSPRESET = Vector3(440, 80 + (GetModConfigData("boatlefthud") or 0), 0)
