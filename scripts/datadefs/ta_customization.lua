-- Use a TA-specific module name because frontend reloads retain require's cache.
return function(options)
    local customization = deepcopy(options)
    for _, group in pairs(customization) do
        for _, option in ipairs(group) do
            option.desc = option.options
            option.value = option.default
            for _, choice in ipairs(option.desc or {}) do
                choice.text = choice.description
            end
        end
    end
    return customization
end
