local OceanFishAnimation = {}

local FLOP_ANIMATIONS = { flop_pre = true, flop_loop = true, flop_pst = true }
local installed = setmetatable({}, { __mode = "k" })

function OceanFishAnimation.InstallInventoryRemap(animation_type, fish_definitions)
    local builds = installed[animation_type]
    if builds == nil then
        builds = {}
        installed[animation_type] = builds

        -- The native inventory prefab plays flop_pst before it has a prefab name.
        -- Match the single-player build so its first frame is also compatible.
        local play = animation_type.PlayAnimation
        function animation_type:PlayAnimation(animation, loop, ...)
            if FLOP_ANIMATIONS[animation] and builds[self:GetBuild()] then
                return play(self, "idle", true, ...)
            end
            return play(self, animation, loop, ...)
        end

        local push = animation_type.PushAnimation
        function animation_type:PushAnimation(animation, loop, ...)
            if FLOP_ANIMATIONS[animation] and builds[self:GetBuild()] then
                return push(self, "idle", true, ...)
            end
            return push(self, animation, loop, ...)
        end
    end

    for _, data in pairs(fish_definitions) do
        if data.istropicalfish and data.oceanbuild ~= nil and data.build ~= nil then
            builds[data.build] = true
        end
    end
end

return OceanFishAnimation
