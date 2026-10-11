local function ReturnOffscreen(inst)
    local seeker = inst.components.homeseeker
    local home = seeker ~= nil and seeker:GetHome() or nil
    if home ~= nil and home:IsValid() and seeker:HasHome() then
        return ACTIONS.GOHOME.fn({ doer = inst, target = home })
    end
    return false
end

return { ReturnOffscreen = ReturnOffscreen }
