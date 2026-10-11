local Widget = require("widgets/widget")
local UIAnim = require("widgets/uianim")

local VolcanoSmokeOver = Class(Widget, function(self)
    Widget._ctor(self, "VolcanoSmokeOver")
    self:SetClickable(false)
    self.rate = 0

    self.clouds = self:AddChild(UIAnim())
    self.clouds:SetHAnchor(ANCHOR_MIDDLE)
    self.clouds:SetVAnchor(ANCHOR_MIDDLE)
    self.clouds:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)
    self.clouds:GetAnimState():SetBank("clouds_ol")
    self.clouds:GetAnimState():SetBuild("clouds_ol")
    self.clouds:GetAnimState():PlayAnimation("idle", true)
    self.clouds:GetAnimState():AnimateWhilePaused(false)
    self:Hide()
end)

function VolcanoSmokeOver:SetRate(rate)
    self.rate = math.max(0, math.min(1, rate or 0))
    if self.rate <= 0 then
        self:Hide()
        return
    end

    local alpha = math.sin(PI * self.rate)
    self.clouds:GetAnimState():SetMultColour(.5, .5, .5, alpha)
    self:Show()
end

return VolcanoSmokeOver
