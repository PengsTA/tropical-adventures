local interior = resolvefilepath("images/colour_cubes/pigshop_interior_cc.tex")
local INTERIOR_COLOURCUBES = {
    day = interior,
    dusk = interior,
    night = interior,
    full_moon = interior,
}
local INTERIOR_SOURCE = "tropical.inhamroom"

AddComponentPostInit("playervision", function(self)
    local updating = false
    local ininterior = false
    local UpdateCCTable = self.UpdateCCTable

    function self:RefreshInteriorVision()
        if not updating then
            -- Use replicated region state, not the arrival order of position packets.
            local inside = self.inst:HasTag("region_interior")
            if inside ~= ininterior then
                ininterior = inside
                updating = true
                if inside then
                    self:PushForcedNightVision(INTERIOR_SOURCE, 1, INTERIOR_COLOURCUBES, true)
                else
                    self:PopForcedNightVision(INTERIOR_SOURCE)
                end
                updating = false
            end
        end
    end

    function self:UpdateCCTable(...)
        self:RefreshInteriorVision()
        return UpdateCCTable(self, ...)
    end

    local function Refresh()
        self:UpdateCCTable()
    end
    self.inst:ListenForEvent("regionchange_client", Refresh)
    self.inst:ListenForEvent("regionchange", Refresh)
    self.inst:ListenForEvent("playeractivated", Refresh)
    self.inst:DoTaskInTime(0, Refresh)
end)
