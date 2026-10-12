-- World options retain their UI values in overrides; TUNING uses false for disabled.
return function(definitions)
    local options, groups = {}, {}
    for group, entries in pairs(definitions) do
        for _, option in ipairs(entries) do
            if option.name ~= "aporkalypse" then
                options[option.name] = option
                groups[option.name] = group == "worldgen_options" and "WORLDGEN" or "CLIMATE"
            end
        end
    end

    local resolver = { options = options, groups = groups }

    function resolver:Validate(name, value)
        local option = options[name]
        if option == nil then return nil end
        if value == false then value = "disabled" end
        if value == true then value = "enabled" end
        for _, choice in ipairs(option.options) do
            if choice.data == value then return value end
        end
    end

    function resolver:WithDefaults(overrides)
        overrides = overrides or {}
        for name, option in pairs(options) do
            local value = self:Validate(name, overrides[name])
            overrides[name] = value == nil and option.default or value
        end
        return overrides
    end

    function resolver:Resolve(overrides)
        local result = { WORLDGEN = {}, CLIMATE = {} }
        for name, option in pairs(options) do
            local value = self:Validate(name, overrides and overrides[name])
            if value == nil then value = option.default end
            if value == "disabled" then value = false end
            result[groups[name]][name] = value
        end
        return result
    end

    return resolver
end
