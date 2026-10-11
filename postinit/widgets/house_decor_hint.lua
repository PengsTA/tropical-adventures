if TheNet:IsDedicated() then
    return
end

local Text = require "widgets/text"

local KEY_PAIR_LABELS = {
    qe = "Q/E",
    du = "↓/↑",
    lr = "←/→",
    mp = "-/+",
    pp = "PgDn/PgUp",
    he = "Home/End",
}

local function KeyLabel(config_name, fallback)
    local value = TA_CONFIG ~= nil and TA_CONFIG.PERSONAL ~= nil and TA_CONFIG.PERSONAL[config_name] or fallback
    if type(value) ~= "string" or KEY_PAIR_LABELS[value] == nil then
        value = fallback
    end
    return KEY_PAIR_LABELS[value]
end

local function GetPlacementAdjustments()
    local controller = ThePlayer ~= nil and ThePlayer.components ~= nil and ThePlayer.components.playercontroller or nil
    local placer = controller ~= nil and controller.placer or nil
    if placer == nil then
        return false, false
    end

    return placer:HasTag("ta_decor_rotation_adjustable"), placer:HasTag("ta_decor_height_adjustable")
end

AddClassPostConstruct("widgets/controls", function(self)
    local hint = self:AddChild(Text(BODYTEXTFONT, 60, ""))
    hint:SetColour(1, 0.93, 0.7, 1)
    hint:Hide()

    local rotation = KeyLabel("build_rotation_key", "qe")
    local height = KeyLabel("build_height_key", "du")
    local old_on_update = self.OnUpdate
    function self:OnUpdate(dt)
        if old_on_update ~= nil then
            old_on_update(self, dt)
        end
        local can_rotate, can_adjust_height = GetPlacementAdjustments()
        if not can_rotate and not can_adjust_height then
            hint:Hide()
            return
        end

        local mouse = TheInput:GetScreenPosition()
        local parts = {}
        if can_rotate then
            table.insert(parts, "旋转 " .. rotation)
        end
        if can_adjust_height then
            table.insert(parts, "高度 " .. height)
        end
        hint:SetString(table.concat(parts, "   "))
        hint:SetPosition(mouse.x + 145, mouse.y - 34, 0)
        hint:Show()
    end
end)
