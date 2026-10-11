local Widget = require("widgets/widget")
local Image = require("widgets/image")
local UIAnim = require("widgets/uianim")

local FogOver = Class(Widget, function(self, owner)
    Widget._ctor(self, "FogOver")
    self:UpdateWhilePaused(false)

    self.owner = owner

    self:SetClickable(false)

    self.bg = self:AddChild(UIAnim())
    self.bg:GetAnimState():SetBank("clouds_ol")
    self.bg:GetAnimState():SetBuild("clouds_ol")
    self.bg:GetAnimState():PlayAnimation("idle", true)
    self.bg:GetAnimState():AnimateWhilePaused(false)
    self.bg:GetAnimState():SetDeltaTimeMultiplier(0.7) -----似乎是控制播放速度，如果让速度依赖于方向就好了
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)

    self.bg2 = self:AddChild(Image("images/overlays/fog.xml", "fog_over.tex"))
    self.bg2:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetVAnchor(ANCHOR_MIDDLE)
    self.bg2:SetHAnchor(ANCHOR_MIDDLE)
    self.bg2:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.nowlevel = 0
    self.foggroggylevel = 0
    self.transitiontime = 2.0
    self.time = self.transitiontime

    self:Hide()
    self:StopUpdating()
end)

function FogOver:UpdateState(foggroggylevel)
    self.foggroggylevel = foggroggylevel or 0
    self:StartUpdating()
    if self.foggroggylevel > 0 then
        self:Show()
    end
end

function FogOver:OnUpdate(dt)
    local step = dt / self.transitiontime
    self.nowlevel = self.nowlevel < self.foggroggylevel
        and math.min(self.nowlevel + step, self.foggroggylevel)
        or math.max(self.nowlevel - step, self.foggroggylevel)

    self.bg:GetAnimState():SetMultColour(1, 1, 1, self.nowlevel / 2)
    self.bg2:SetTint(1, 1, 1, self.nowlevel)

    if self.nowlevel <= 0 then
        self:Hide()
        if self.foggroggylevel <= 0 then
            self:StopUpdating()
        end
    else
        self:Show()
    end
end

return FogOver
