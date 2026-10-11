local Widget = require "widgets/widget"
local Image = require "widgets/image"
local easing = require "easing"

local PollenOver = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "PollenOver")
    self:UpdateWhilePaused(false)
    self:SetClickable(false)

    self.bg = self:AddChild(Image("images/overlays/hayfever.xml", "pollen_over.tex"))

    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.bg2 = self:AddChild(Image("images/overlays/hayfever.xml", "pollen_over2.tex"))
    self.bg2:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetVAnchor(ANCHOR_MIDDLE)
    self.bg2:SetHAnchor(ANCHOR_MIDDLE)
    self.bg2:SetScaleMode(SCALEMODE_FILLSCREEN)

    self:Hide()

    self.level = 0

    self.sneezethreshhold = 2

    self.mainline = 1
    self.startline = 30

    self.lastsneezetime = 9999
    self.sneezedeadline = nil

    self.sneezecountdown = 1

    self.level2 = 0
    self.stoptask = nil

    self:StopUpdating()
end)

function PollenOver:UpdateState(sneezetime)
    self.lastsneezetime = sneezetime or 9999
    self.sneezedeadline = self.lastsneezetime < 999 and GetTime() + self.lastsneezetime or nil
    if self.lastsneezetime < 0 then self.lastsneezetime = 9999 end
    if self.stoptask ~= nil then
        self.stoptask:Cancel()
        self.stoptask = nil
    end
    if self.lastsneezetime < 999 then
        self:StartUpdating()
        self:Show()
    end
end

function PollenOver:OnUpdate(dt)
    if self.sneezedeadline ~= nil then
        self.lastsneezetime = math.max(0, self.sneezedeadline - GetTime())
    end

    local leveltarget = self.level

    -- PLAYER IS CLOSE TO SNEEZING
    if self.lastsneezetime and self.lastsneezetime <= self.sneezethreshhold then
        if not self.sneezecountdown then -- self.lastsneezetime == self.sneezethreshhold then
            self.sneezecountdown = self.sneezethreshhold
        end

        self.level2 = (1 - 0.025) * (1 - (self.lastsneezetime / self.sneezethreshhold))

        -- PLAYER's HUD IS GETTING ITCHY
    elseif self.lastsneezetime and self.lastsneezetime < self.startline then
        self.level2 = 0
        self.sneezecountdown = nil
        -- FADE FROM 0 to FULL for half the time then sit at full.
        if self.lastsneezetime > self.startline / 2 then
            leveltarget = 1 - ((self.lastsneezetime - self.startline / 2) / (self.startline / 2)) - 0.025
        else
            leveltarget = 1 - 0.025
        end
    else
        self.level2 = 0
        leveltarget = 0
    end

    if leveltarget < self.level then
        self.level = math.max(leveltarget, self.level - 0.01)
    else
        self.level = leveltarget
    end

    -- if not TheFocalPoint:AwareInHamletArea() then
    --     self.level = 0
    -- end

    -- add some noise
    local circle = (self.lastsneezetime % 5) / 5 * TWOPI
    local breath = math.min(1, (math.cos(circle) + 1.8))

    if (self.level > 0 or self.level2 > 0) then
        if self.stoptask ~= nil then
            self.stoptask:Cancel()
            self.stoptask = nil
        end
        self:Show()
        self.bg:SetTint(1, 1, 1, self.level * breath)
        self.bg2:SetTint(1, 1, 1, self.level2 * breath)
    else
        self:Hide()
        if self.sneezedeadline == nil and self.stoptask == nil then
            self.stoptask = self.owner:DoTaskInTime(2, function()
                self.stoptask = nil
                self:StopUpdating()
            end)
        end
    end

    -- print("pollen is updating")
    -- print(self.level)
    -- print(self.level2)
end

return PollenOver
