-- ta_seaworthy_screen.lua
-- GUI selection screen for Seaworthy teleportation

local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local TEMPLATES = require "widgets/redux/templates"
local Chair = require "tools/ta_seaworthy"

local TaSeaworthyScreen = Class(Screen, function(self, owner, attach, cached_infos)
    Screen._ctor(self, "TaSeaworthyScreen")

    self.owner = owner
    self.attach = attach
    self.cached_infos = cached_infos
    self.isopen = false
    self.dest_infos = {}

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)

    self.scalingroot = self:AddChild(Widget("scalingroot"))
    self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())

    self.inst:ListenForEvent("continuefrompause", function()
        if self.isopen then
            self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
        end
    end, TheWorld)

    self.inst:ListenForEvent("refreshhudsize", function(hud, scale)
        if self.isopen then
            self.scalingroot:SetScale(scale)
        end
    end, owner.HUD.inst)

    self.root = self.scalingroot:AddChild(TEMPLATES.ScreenRoot("root"))

    self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, 0.4)
    self.black.OnMouseButton = function()
        self:OnCancel()
    end

    local panel_w, panel_h = 420, 560
    self.destspanel = self.root:AddChild(TEMPLATES.RectangleWindow(panel_w, panel_h))
    self.destspanel:SetPosition(0, 20)

    local is_sky = Chair.IsSkyChair(self.attach)
    local title_str = is_sky and "天空之椅 · 航向选择" or "海洋之椅 · 航向选择"
    self.title = self.destspanel:AddChild(Text(HEADERFONT, 28, title_str))
    self.title:SetPosition(0, panel_h / 2 - 40, 0)
    self.title:SetColour(0.9, 0.85, 0.6, 1)

    local btn_y = -panel_h / 2 + 40
    self.renamebutton = self.destspanel:AddChild(
        TEMPLATES.StandardButton(
            function() self:OnRename() end,
            "修改名称",
            { 130, 42 }
        )
    )
    self.renamebutton:SetPosition(-80, btn_y)

    self.cancelbutton = self.destspanel:AddChild(
        TEMPLATES.StandardButton(
            function() self:OnCancel() end,
            "关闭",
            { 130, 42 }
        )
    )
    self.cancelbutton:SetPosition(80, btn_y)
    self.empty_label = self.destspanel:AddChild(Text(BODYTEXTFONT, 24, "正在搜索航向或暂无可到达的目的地..."))
    self.empty_label:SetPosition(0, 20, 0)
    self.empty_label:SetColour(0.8, 0.8, 0.8, 0.6)
    self.empty_label:Hide()

    self:LoadDests()

    self:Show()
    self.isopen = true
end)

function TaSeaworthyScreen:UpdateInfos(cached_infos)
    if not self.isopen then return end
    self.cached_infos = cached_infos
    self:LoadDests()
end

function TaSeaworthyScreen:LoadDests()
    local info_pack = self.cached_infos
    self.cached_infos = nil
    self.dest_infos = {}

    if info_pack and info_pack ~= "" then
        local lines = string.split(info_pack, "\n")
        for _, line in ipairs(lines) do
            local parts = string.split(line, "\t")
            if #parts >= 6 then
                local info = {
                    id = parts[1],
                    name = parts[2] or "海洋之椅",
                    cost_sanity = tonumber(parts[3]) or 0,
                    worldid = parts[4] or "",
                    worldname = parts[5] or "",
                    is_broken = (parts[6] == "1"),
                }
                table.insert(self.dest_infos, info)
            end
        end
    end

    self:RefreshDests()
end

function TaSeaworthyScreen:RefreshDests()
    self.destwidgets = self.dest_infos

    local function ScrollWidgetsCtor(context, index)
        local widget = Widget("dest_widget_" .. index)

        widget:SetOnGainFocus(function()
            if self.dests_scroll_list then
                self.dests_scroll_list:OnWidgetFocus(widget)
            end
        end)

        widget.destitem = widget:AddChild(self:DestListItem())
        widget.focus_forward = widget.destitem

        return widget
    end

    local function ApplyDataToWidget(context, widget, data, index)
        widget.data = data
        widget.destitem:Hide()
        if not data then
            widget.focus_forward = nil
            return
        end

        widget.focus_forward = widget.destitem
        widget.destitem:Show()
        widget.destitem:SetInfo(data)
    end

    if not self.dests_scroll_list then
        self.dests_scroll_list = self.destspanel:AddChild(
            TEMPLATES.ScrollingGrid(self.destwidgets, {
                scroll_context = {},
                widget_width = 380,
                widget_height = 80,
                num_visible_rows = 4,
                num_columns = 1,
                item_ctor_fn = ScrollWidgetsCtor,
                apply_fn = ApplyDataToWidget,
                scrollbar_offset = 12,
                scrollbar_height_offset = -60,
                peek_percent = 0,
                allow_bottom_empty_row = true,
            })
        )
        self.dests_scroll_list:SetPosition(0, 5)
        self.dests_scroll_list:SetFocusChangeDir(MOVE_DOWN, self.cancelbutton)
        self.cancelbutton:SetFocusChangeDir(MOVE_UP, self.dests_scroll_list)
        self.cancelbutton:SetFocusChangeDir(MOVE_LEFT, self.renamebutton)
        self.renamebutton:SetFocusChangeDir(MOVE_UP, self.dests_scroll_list)
        self.renamebutton:SetFocusChangeDir(MOVE_RIGHT, self.cancelbutton)
        self.default_focus = self.dests_scroll_list
    else
        self.dests_scroll_list:SetItemsData(self.destwidgets)
    end

    if #self.destwidgets == 0 then
        if self.empty_label then self.empty_label:Show() end
    else
        if self.empty_label then self.empty_label:Hide() end
    end
end

function TaSeaworthyScreen:DestListItem()
    local dest = Widget("ta_seaworthy_destination")
    local item_w, item_h = 370, 76

    dest.backing = dest:AddChild(TEMPLATES.ListItemBackground(item_w, item_h, function()
        dest:OnSelected()
    end))
    dest.backing.move_on_click = true
    dest.focus_forward = dest.backing

    dest.name = dest:AddChild(Text(BODYTEXTFONT, 24))
    dest.name:SetVAlign(ANCHOR_MIDDLE)
    dest.name:SetHAlign(ANCHOR_LEFT)
    dest.name:SetPosition(-15, 16, 0)
    dest.name:SetRegionSize(240, 28)

    dest.status = dest:AddChild(Text(UIFONT, 18))
    dest.status:SetVAlign(ANCHOR_MIDDLE)
    dest.status:SetHAlign(ANCHOR_RIGHT)
    dest.status:SetPosition(120, 16, 0)
    dest.status:SetRegionSize(100, 26)

    dest.world = dest:AddChild(Text(UIFONT, 16))
    dest.world:SetVAlign(ANCHOR_MIDDLE)
    dest.world:SetHAlign(ANCHOR_LEFT)
    dest.world:SetPosition(-15, -16, 0)
    dest.world:SetRegionSize(150, 22)
    dest.world:SetColour(0.6, 0.7, 0.9, 1)

    dest.cost = dest:AddChild(Text(UIFONT, 16))
    dest.cost:SetVAlign(ANCHOR_MIDDLE)
    dest.cost:SetHAlign(ANCHOR_RIGHT)
    dest.cost:SetPosition(100, -16, 0)
    dest.cost:SetRegionSize(180, 22)

    dest.SetInfo = function(_, info)
        dest.info = info
        dest.name:SetString(info.name or "海洋之椅")

        dest.world:SetString(info.worldname or "未知世界")

        if info.cost_sanity == -1 then
            dest.name:SetColour(0.8, 0.9, 1, 1)
            dest.status:SetString("[当前位置]")
            dest.status:SetColour(0.5, 0.7, 1, 1)
            dest.cost:SetString("")
        else
            if info.is_broken then
                dest.status:SetString("[破损锚点]")
                dest.status:SetColour(0.95, 0.6, 0.2, 1)
            else
                dest.status:SetString("[正常]")
                dest.status:SetColour(0.3, 0.9, 0.4, 1)
            end

            dest.name:SetColour(1, 1, 1, 1)
            dest.cost:SetString(string.format("理智: -%d", math.ceil(info.cost_sanity)))
            dest.cost:SetColour(0.9, 0.8, 0.5, 1)
        end
    end

    dest.OnSelected = function(_)
        if not dest.info then return end
        if dest.info.cost_sanity == -1 then
            return
        end

        SendModRPCToServer(GetModRPC("TA_SeaWorthy", "Travel"), self.attach, dest.info.id, dest.info.worldid)
        self:Close()
    end

    return dest
end

function TaSeaworthyScreen:OnRename()
    local attach = self.attach
    self:Close()
    if attach and attach:IsValid() then
        SendModRPCToServer(GetModRPC("TA_SeaWorthy", "Rename"), attach)
    end
end

function TaSeaworthyScreen:OnCancel()
    self:Close()
end

function TaSeaworthyScreen:Close()
    if not self.isopen then return end
    self.isopen = false

    TheFrontEnd:PopScreen(self)
    if self.owner and self.owner.HUD and self.owner.HUD.ta_seaworthy_screen == self then
        self.owner.HUD.ta_seaworthy_screen = nil
    end

    if self.attach and self.attach:IsValid() then
        SendModRPCToServer(GetModRPC("TA_SeaWorthy", "CloseScreen"), self.attach)
    end
end

function TaSeaworthyScreen:OnControl(control, down)
    if TaSeaworthyScreen._base.OnControl(self, control, down) then
        return true
    end

    if not down and (control == CONTROL_CANCEL or control == CONTROL_PAUSE) then
        self:OnCancel()
        return true
    end

    return false
end

return TaSeaworthyScreen
