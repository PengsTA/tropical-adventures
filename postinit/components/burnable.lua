local TROENV = env
GLOBAL.setfenv(1, GLOBAL)

TROENV.AddComponentPostInit("burnable", function(burnable)
    local old_ignite = burnable.Ignite
    function burnable:Ignite(...)
        if self.inst:GetIsFlooded() then
            return false
        end
        return old_ignite(self, ...)
    end
end)
