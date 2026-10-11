---------------------------------------------------------------------tira a neve----------------------------------------------------------------------------------------
if --[[GetModConfigData("disable_snow_effects") ==]] false then
    AddComponentPostInit("weather",
        function(self, inst)
            inst:ListenForEvent(
                "weathertick",
                function(inst, data)
                    if data and data.snowlevel
                    then
                        local newlevel = data.snowlevel <= 0 and data.snowlevel or 0
                        GLOBAL.TheWorld.Map:SetOverlayLerp(newlevel)
                    end
                end,
                GLOBAL.TheWorld
            )
        end
    )
end



local _level = 0
local _texture = "levels/textures/snow.tex"
AddClassPostConstruct("components/weather", function(cmp)
    local mapfuncs = GLOBAL.getmetatable(TheWorld.Map).__index
    local _SetOverlayLerp = mapfuncs.SetOverlayLerp
    local _SetOverlayTexture = mapfuncs.SetOverlayTexture

    -- print("tropical_world_snow")
    mapfuncs.SetOverlayTexture = function(map, texture, ...)
        _texture = texture
        _SetOverlayTexture(map, texture, ...)
    end

    mapfuncs.SetOverlayLerp = function(map, level, ...)
        if _texture == "levels/textures/snow.tex" then
            local diff = level - _level
            local maxStep = 0.05 -- Set your desired max step here

            if not ThePlayer or not ThePlayer:AwareInTropicalRegion() then
                -- print("tropical_world_snow11111")
                -- Clamp the change to a maximum step size
                if diff > maxStep then
                    diff = maxStep
                elseif diff < -maxStep then
                    diff = -maxStep
                end

                _level = _level + diff
            else
                -- print("tropical_world_snow22222")
                _level = math.max(_level - maxStep, 0)
            end

            return _SetOverlayLerp(map, _level, ...)
        else
            return _SetOverlayLerp(map, level, ...)
        end
    end
end)
