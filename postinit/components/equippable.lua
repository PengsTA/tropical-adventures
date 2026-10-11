local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Equippable = require("components/equippable")

-- Boat lamps use PorkLand's equip-toggle contract. Keep it deliberately
-- small: this mod only needs the state, callbacks, and replicated tag.
if Equippable.ToggleOn == nil then
    function Equippable:ToggleOn()
        self.toggled = true
        self.inst:AddTag("toggled")
        if self.toggledonfn ~= nil then
            self.toggledonfn(self.inst)
        end
    end

    function Equippable:ToggleOff()
        self.toggled = false
        self.inst:RemoveTag("toggled")
        if self.toggledofffn ~= nil then
            self.toggledofffn(self.inst)
        end
    end

    function Equippable:IsToggledOn()
        return self.toggled == true
    end
end

AddComponentPostInit("equippable", function(self)
    if self.toggled == nil then
        self.toggled = false
    end
end)
