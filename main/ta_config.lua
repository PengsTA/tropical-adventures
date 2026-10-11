modimport("modinfo")
GLOBAL.TA_CONFIG = {}

local worldgen_options = ta_world_options.worldgen_options
local climate_options = ta_world_options.climate_options

local function AddConfigAndTuning(config)
    local addconfig = function(tbl, options, local_config)
        for i, v in ipairs(options) do
            local value = GetModConfigData(v.name, local_config)
            if value == nil then
                value = v.default
            end
            tbl[v.name] = value
            if tbl[v.name] == "disabled" then
                tbl[v.name] = false
            end
        end

        return tbl
    end

    config.WORLDGEN = addconfig({}, worldgen_options)
    config.CLIMATE = addconfig({}, climate_options)

    config.GLOBAL = addconfig({}, global_options)
    config.PERSONAL = addconfig({}, client_options, true)
    config.DEVELOP = addconfig({}, developer_options)
    config.DEPENDENCY = { ndnr = KnownModIndex:IsModEnabled("workshop-2823458540"), }

    config.WORLDGEN.sw_start = config.WORLDGEN.shipwrecked and (config.WORLDGEN.multiplayerportal == "shipwrecked") and
        not config.DEVELOP.test_map
    config.WORLDGEN.ham_start = config.WORLDGEN.hamlet and (config.WORLDGEN.multiplayerportal == "hamlet") and
        not config.DEVELOP.test_map
    config.WORLDGEN.world_size_multi = config.DEVELOP.test_map and 0.05 or config.WORLDGEN.world_size_multi
    config.WORLDGEN.together_not_mainland = (config.WORLDGEN.sw_start or config.WORLDGEN.ham_start)
    config.WORLDGEN.together = not ((not config.WORLDGEN.rog) and config.WORLDGEN.together_not_mainland)

    config.CLIMATE.sealnado = config.WORLDGEN.shipwrecked and config.CLIMATE.sealnado or false
    config.CLIMATE.fog = config.WORLDGEN.hamlet and config.CLIMATE.fog or false
    config.CLIMATE.hayfever = config.WORLDGEN.hamlet and config.CLIMATE.hayfever or false
    config.CLIMATE.brambles = config.WORLDGEN.hamlet and config.CLIMATE.brambles or false
    config.CLIMATE.aporkalypse = (config.WORLDGEN.hamlet or config.WORLDGEN.ruins) and
        config.CLIMATE.aporkalypse or false
    config.CLIMATE.roc = config.WORLDGEN.hamlet and config.CLIMATE.roc or false
    config.CLIMATE.bosslife = 1

    for _, module in pairs(config) do
        for k, v in pairs(module) do
            TUNING[k] = v
        end
    end
end

AddConfigAndTuning(TA_CONFIG)
TUNING.TROPICAL_ADVENTURE_VERSION = version
