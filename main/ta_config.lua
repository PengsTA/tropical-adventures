modimport("modinfo")

local resolver = require("tools/ta_config_resolver")(ta_world_options)
local generating = rawget(_G, "WorldSim") ~= nil
local server = not generating and TheNet:GetIsServer()
local config = { WORLDGEN = {}, CLIMATE = {}, GLOBAL = {}, PERSONAL = {}, DEVELOP = {} }
GLOBAL.TA_CONFIG = config

local function ReadOptions(target, options, local_config)
    for _, option in ipairs(options) do
        local value = GetModConfigData(option.name, local_config)
        if value == nil then value = option.default end
        if value == "disabled" then value = false end
        target[option.name] = value
    end
end

ReadOptions(config.GLOBAL, global_options)
ReadOptions(config.PERSONAL, client_options, true)
ReadOptions(config.DEVELOP, developer_options)
config.DEPENDENCY = { ndnr = KnownModIndex:IsModEnabled("workshop-2823458540") }

local aporkalypse = GetModConfigData("aporkalypse")
config.CLIMATE.aporkalypse = aporkalypse == nil and true
    or (aporkalypse ~= "disabled" and aporkalypse ~= false)

local raw_overrides = {}
local function ApplyWorldOptions(overrides)
    local resolved = resolver:Resolve(overrides)
    for name, value in pairs(resolved.WORLDGEN) do config.WORLDGEN[name] = value end
    for name, value in pairs(resolved.CLIMATE) do config.CLIMATE[name] = value end
    local worldgen, climate = config.WORLDGEN, config.CLIMATE
    worldgen.sw_start = worldgen.shipwrecked and worldgen.multiplayerportal == "shipwrecked"
        and not config.DEVELOP.test_map
    worldgen.ham_start = worldgen.hamlet and worldgen.multiplayerportal == "hamlet"
        and not config.DEVELOP.test_map
    worldgen.world_size_multi = config.DEVELOP.test_map and 0.05 or worldgen.world_size_multi
    worldgen.together_not_mainland = worldgen.sw_start or worldgen.ham_start
    worldgen.together = not (not worldgen.rog and worldgen.together_not_mainland)
    climate.sealnado = worldgen.shipwrecked and climate.sealnado or false
    for _, name in ipairs({ "fog", "hayfever", "brambles", "roc" }) do
        climate[name] = worldgen.hamlet and climate[name] or false
    end
    climate.bosslife = 1
    for _, group in ipairs({ "WORLDGEN", "CLIMATE", "GLOBAL", "PERSONAL", "DEVELOP", "DEPENDENCY" }) do
        for name, value in pairs(config[group]) do TUNING[name] = value end
    end
end

function config.SetAporkalypseEnabled(enabled)
    config.CLIMATE.aporkalypse = enabled == true
    TUNING.aporkalypse = enabled == true
end

if generating then
    local parameters = rawget(_G, "GEN_PARAMETERS")
    local data = type(parameters) == "table" and parameters or require("json").decode(parameters)
    local level = assert(data.level_data, "TA world generation requires level_data")
    level.overrides = resolver:WithDefaults(level.overrides)
    raw_overrides = level.overrides
    -- worldgen_main decodes GEN_PARAMETERS again after loading modworldgenmain.
    GLOBAL.GEN_PARAMETERS = type(parameters) == "table" and data or require("json").encode(data)
else
    if server and ShardGameIndex ~= nil then
        local options = ShardGameIndex:GetGenOptions()
        raw_overrides = options and options.overrides or {}
    end
    local overrides = require("worldsettings_overrides")
    for name in pairs(resolver.options) do
        overrides.Pre[name] = function(value)
            local validated = resolver:Validate(name, value)
            raw_overrides[name] = validated == nil and resolver.options[name].default or validated
            ApplyWorldOptions(raw_overrides)
        end
    end

    function config.RefreshFromTopology(world)
        if world == nil or world.topology == nil or world.topology.overrides == nil or world.net == nil then return false end
        raw_overrides = world.topology.overrides
        ApplyWorldOptions(raw_overrides)
        local network = world.net
        if network._ta_aporkalypse_enabled ~= nil then
            config.SetAporkalypseEnabled(network._ta_aporkalypse_enabled:value())
        end
        world._ta_config_ready = true
        world:PushEvent("taconfigready")
        if network._aporkalypse_phase ~= nil then
            world:PushEvent("aporkalypsephasechanged",
                ({ "fiesta", "calm", "near", "aporkalypse" })[network._aporkalypse_phase:value()])
        end
        if network.components.weatherham ~= nil then network.components.weatherham:Refresh() end
        return true
    end

    AddSimPostInit(function()
        if not TA_CONFIG.RefreshFromTopology(TheWorld) and TheWorld ~= nil then
            local task
            task = TheWorld:DoPeriodicTask(0.1, function()
                if TA_CONFIG.RefreshFromTopology(TheWorld) then task:Cancel() end
            end)
        end
    end)
end

ApplyWorldOptions(raw_overrides)
TUNING.TROPICAL_ADVENTURE_VERSION = version
