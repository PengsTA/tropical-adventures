local Image = require "widgets/image"
local ANCHOR_MIDDLE = 0
local SCALEMODE_FILLSCREEN = 1
local REGIONS = table.invert({ "default", "shipwrecked", "hamlet" })

local BLENDMODE = {
    Disabled = 0,
    AlphaBlended = 1,
    Additive = 2,
    Premultiplied = 3,
    InverseAlpha = 4,
    AlphaAdditive = 5,
    VFXTest = 6,
}

local function GetCurrentRegion(player)
    if player:AwareInShipwreckedRegion() then
        return REGIONS.shipwrecked
    elseif player:AwareInHamletRegion() then
        return REGIONS.hamlet
    end
    return REGIONS.default
end


local MAP_CONFIG = {
    -- [REGIONS.default] = {
    --     bg_xml = "images/hud.xml",
    --     bg_tex = "map.tex"
    -- },
    [REGIONS.shipwrecked] = {
        bg_xml = "images/mapstyle/hud_shipwrecked.xml",
        bg_tex = "map_shipwrecked.tex"
    },
    [REGIONS.hamlet] = {
        bg_xml = "images/mapstyle/hud_hamlet.xml",
        bg_tex = "map_hamlet.tex"
    }, --[[
    [REGIONS.pigcity] = {
        bg_xml = "images/mapstyle/hud_pigcity.xml",
        bg_tex = "images/mapstyle/map_pigcity.tex"
    },]]
}


AddClassPostConstruct("screens/mapscreen", function(self)
    local _OnBecomeInactive = self.OnBecomeInactive
    function self:OnBecomeInactive()
        _OnBecomeInactive(self)
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/map_close")
    end

    local _OnBecomeActive = self.OnBecomeActive
    function self:OnBecomeActive()
        _OnBecomeActive(self)
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/map_open")
    end
end)

AddClassPostConstruct("widgets/mapwidget", function(self)
    local player = ThePlayer
    local region = GetCurrentRegion(player)
    local config = MAP_CONFIG[region]
    if config then
        if self.bg then
            self.bg:Kill()
        end
        self.bg = self:AddChild(Image(config.bg_xml, config.bg_tex))
        self.bg:SetVRegPoint(ANCHOR_MIDDLE)
        self.bg:SetHRegPoint(ANCHOR_MIDDLE)
        self.bg:SetVAnchor(ANCHOR_MIDDLE)
        self.bg:SetHAnchor(ANCHOR_MIDDLE)
        self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)
        self.bg.inst.ImageWidget:SetBlendMode(BLENDMODE.Premultiplied)

        self.minimap = TheWorld.minimap.MiniMap
        self.img = self:AddChild(Image())
        self.img:SetHAnchor(ANCHOR_MIDDLE)
        self.img:SetVAnchor(ANCHOR_MIDDLE)
        self.img.inst.ImageWidget:SetBlendMode(BLENDMODE.Additive)

        self.lastpos = nil
        self.minimap:ResetOffset()
        self:StartUpdating()
    end
end)
