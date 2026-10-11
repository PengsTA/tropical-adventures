local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"
local TrueScrollArea = require "widgets/truescrollarea"

require("util")
local desc_about = require("datadefs/wikibook_contents").wiki_about
local desc_terms = require("datadefs/wikibook_contents").wiki_terms

-- 详细信息标签
-- ⭐️只用更换新的贴图设计就好了
local function MakeDetailsLine(details_root, x, y, scale, image_override)
    local value_title_line = details_root:AddChild(Image("images/quagmire_recipebook.xml",
        image_override or "quagmire_recipe_line.tex"))
    value_title_line:SetScale(scale, scale)
    value_title_line:SetPosition(x, y)
end

local function AdjustToUtf8Boundary(str, index)
    if index <= 0 or index > #str then
        return index
    end
    local b = string.byte(str, index)
    while index > 1 and b and b >= 128 and b < 192 do
        index = index - 1
        b = string.byte(str, index)
    end
    return index
end

local function SplitTextIntoChunks(str, max_bytes)
    max_bytes = max_bytes or 1200
    if not str or str == "" then
        return {}
    end
    if #str <= max_bytes then
        return { str }
    end

    local chunks = {}
    local current_chunk = {}
    local current_bytes = 0

    local function flush_chunk()
        if #current_chunk > 0 then
            table.insert(chunks, table.concat(current_chunk, "\n"))
            current_chunk = {}
            current_bytes = 0
        end
    end

    local function add_line(line)
        local line_bytes = #line + 1
        if line_bytes > max_bytes then
            flush_chunk()
            local pos = 1
            local total_len = #line
            while pos <= total_len do
                local target_end = math.min(pos + max_bytes - 1, total_len)
                if target_end < total_len then
                    local safe_next = AdjustToUtf8Boundary(line, target_end + 1)
                    target_end = safe_next - 1
                end
                table.insert(chunks, string.sub(line, pos, target_end))
                pos = target_end + 1
            end
        else
            if current_bytes + line_bytes > max_bytes and current_bytes > 0 then
                flush_chunk()
            end
            table.insert(current_chunk, line)
            current_bytes = current_bytes + line_bytes
        end
    end

    for line in string.gmatch(str, "([^\r\n]*)\r?\n") do
        add_line(line)
    end

    local trailing = string.match(str, "[^\r\n]+$")
    if trailing then
        add_line(trailing)
    end

    flush_chunk()
    return chunks
end

-------------------------------------------------------------------------------------------------------

local is_ch = TUNING.LANGUAGE_CHINESE
local size_multi = is_ch and 1 or 0.6

local WikiAboutPage = Class(Widget, function(self, parent_screen, category)
    Widget._ctor(self, "WikiAboutPage")

    self.parent_screen = parent_screen
    self.category = category or "about"

    self:CreateDesc()

    return self
end)

-- 整个框架，包括左右两个区域
function WikiAboutPage:CreateDesc()
    local panel_root = self

    -- 左侧的内容
    local leftroot = panel_root:AddChild(self:LeftDesc())
    leftroot:SetPosition(-407, -195)

    -- 左侧内容上下的两个line
    -- ⭐位置肯定要调整
    local boarder_scale = 0.75
    local grid_w = 390
    local grid_h = 409.5
    local grid_boarder = panel_root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_line.tex"))
    grid_boarder:SetScale(boarder_scale, boarder_scale)
    grid_boarder:SetPosition(-183, grid_h / 2 + 7)
    grid_boarder = panel_root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_line.tex"))
    grid_boarder:SetScale(boarder_scale, -boarder_scale)
    grid_boarder:SetPosition(-183, -grid_h / 2 - 7)

    -----------

    -- 右侧显示的装饰框架（包括矩形背景和左右纹理）
    -- -- 覆盖的矩形背景
    -- -- ⭐️要更换贴图
    local details_decor = panel_root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_menu_block.tex"))
    details_decor:ScaleToSize(360, 500)
    details_decor:SetPosition(225, 0)
    -- 右侧左下角的纹理
    -- ⭐️要更换贴图
    details_decor =
        panel_root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_corner_decoration.tex"))
    details_decor:ScaleToSize(100, 100)
    details_decor:SetPosition(105, -190)
    -- 右侧友下角的纹理
    -- ⭐️要更换贴图
    details_decor =
        panel_root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_corner_decoration.tex"))
    details_decor:ScaleToSize(-100, 100)
    details_decor:SetPosition(345, -190)

    local rightroot = panel_root:AddChild(self:RightDesc())
    rightroot:SetPosition(45, -205)
end

function WikiAboutPage:LeftDesc()
    local name_font_size = 40
    local text_font_size = 23

    local left_widget = Widget("details_root")

    local y = 210

    -- local about_text = left_widget:AddChild(Text(HEADERFONT, name_font_size * size_multi, "", UICOLOURS.BRONZE))
    -- about_text:SetMultilineTruncatedString(desc_terms.mod_background, 100, 370)
    -- local _, textH_4 = about_text:GetRegionSize()
    -- y = y - textH_4 / 2 - 30
    -- about_text:SetPosition(0, y)

    -- about_text = left_widget:AddChild(Text(HEADERFONT, text_font_size * size_multi, "", UICOLOURS.BROWN_DARK))
    -- about_text:SetHAlign(ANCHOR_LEFT)
    -- about_text:SetVAlign(ANCHOR_TOP)
    -- about_text:SetMultilineTruncatedString(desc_about.str_back, 100, 370)
    -- local _, textH_5 = about_text:GetRegionSize()
    -- y = y - textH_4 / 2 - textH_5 / 2
    -- about_text:SetPosition(0, y)

    local textH_5, textH_4 = 0, 0

    local title_text = left_widget:AddChild(Text(HEADERFONT, name_font_size * size_multi, "", UICOLOURS.BRONZE))
    title_text:SetMultilineTruncatedString(desc_terms.mod_progress, 100, 370)
    local _, textH_0 = title_text:GetRegionSize()
    y = y - textH_5 / 2 - textH_0 / 2 - 30
    title_text:SetPosition(0, y)

    local current_bottom = y - textH_0 / 2
    local total_body_h = 0
    -- BitmapFontRenderer hard-caps strings at MAX_NUM_CHARS (4096 bytes).
    -- Split changelog into smaller chunks to prevent engine buffer overflow assertion.
    local chunks = SplitTextIntoChunks(desc_about.str_progress, 1200)
    for _, chunk in ipairs(chunks) do
        local chunk_widget = left_widget:AddChild(Text(HEADERFONT, text_font_size * size_multi, "", UICOLOURS.BROWN_DARK))
        chunk_widget:SetHAlign(ANCHOR_LEFT)
        chunk_widget:SetVAlign(ANCHOR_TOP)
        chunk_widget:SetMultilineTruncatedString(chunk, 500, 370)
        local _, chunk_h = chunk_widget:GetRegionSize()
        local chunk_y = current_bottom - chunk_h / 2
        chunk_widget:SetPosition(0, chunk_y)
        current_bottom = current_bottom - chunk_h
        total_body_h = total_body_h + chunk_h
    end

    -- 滑动区域的宽
    local width = 450
    -- 滑动区域的高
    local height = textH_0 + total_body_h + textH_4 + textH_5 + 300
    local PANEL_HEIGHT = 470
    -- 可视滑动区域的高
    local max_visible_height = PANEL_HEIGHT - 80 -- -20
    local padding = 5
    local top = max_visible_height / 2 - padding

    local scissor_data = {
        x = 0,
        y = 0,
        width = width,
        height = max_visible_height
    }
    local context = {
        widget = left_widget,
        offset = {
            x = width / 2,
            y = max_visible_height / 2
        },
        size = {
            w = width,
            height = height + padding
        }
    }
    local scrollbar = {
        scroll_per_click = 20 * 3,
        h_offset = -43
    }

    local scroll_area_left = TrueScrollArea(context, scissor_data, scrollbar)

    scroll_area_left.up_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    scroll_area_left.up_button:SetScale(0.5)

    scroll_area_left.down_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    scroll_area_left.down_button:SetScale(-0.5)

    scroll_area_left.scroll_bar_line:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_bar.tex")
    scroll_area_left.scroll_bar_line:SetScale(.8)

    scroll_area_left.position_marker:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
    scroll_area_left.position_marker:OnGainFocus()
    scroll_area_left.position_marker:SetScale(.6)

    return scroll_area_left
end

function WikiAboutPage:RightDesc()
    local name_font_size = 40
    local text_font_size = 23

    local right_widget = Widget("details_root")

    -- 右侧矩形背景中的具体内容
    local top = 250
    local y = top - 11
    y = y - name_font_size / 2
    local thks_grid = right_widget:AddChild(Text(HEADERFONT, name_font_size * size_multi, desc_terms.mod_about,
        UICOLOURS.BROWN_DARK))
    thks_grid:SetPosition(0, y)

    y = y - name_font_size / 2 - 4

    -- 显示名称下的纹理
    MakeDetailsLine(right_widget, 0, y - 10, -.55, "quagmire_recipe_line_break.tex")
    y = y - 10

    local about_text = right_widget:AddChild(Text(HEADERFONT, text_font_size * size_multi, "", UICOLOURS.BROWN_DARK))
    about_text:SetHAlign(ANCHOR_LEFT)
    about_text:SetVAlign(ANCHOR_TOP)
    about_text:SetMultilineTruncatedString(desc_about.str_preview, 200, 300)
    local _, textH_X = about_text:GetRegionSize()
    y = y - textH_X / 2 - 30
    about_text:SetPosition(0, y)

    local textH_3 = 0
    -- about_text = right_widget:AddChild(Text(HEADERFONT, name_font_size * size_multi, desc_terms.mod_sponser,
    --     UICOLOURS.BROWN_DARK))
    -- y = y - textH_3
    -- about_text:SetPosition(0, y)

    local textH_4 = 150
    about_text = right_widget:AddChild(Image("images/code.xml", "code.tex"))
    y = y - textH_4
    about_text:SetPosition(0, y)
    about_text:SetScale(0.25)

    local textH_5 = 0
    -- about_text = right_widget:AddChild(Text(HEADERFONT, name_font_size * size_multi, desc_terms.mod_sponser_list,
    --     UICOLOURS.BROWN_DARK))
    -- y = y - textH_5
    -- about_text:SetPosition(0, y)

    -- local about_text = right_widget:AddChild(Text(HEADERFONT, text_font_size * size_multi, "", UICOLOURS.BROWN_DARK))
    -- about_text:SetHAlign(ANCHOR_LEFT)
    -- about_text:SetVAlign(ANCHOR_TOP)
    -- about_text:SetMultilineTruncatedString(desc_about.str_donation, 200, 300)
    -- local _, textH_X = about_text:GetRegionSize()
    -- y = y - textH_X / 2 - 30
    -- about_text:SetPosition(0, y)




    local width = 360
    local height = textH_4 + textH_3 + textH_5 + 300
    local PANEL_HEIGHT = 530
    local max_visible_height = PANEL_HEIGHT - 80 -- -20
    local padding = 5
    local top = max_visible_height / 2 - padding

    local scissor_data = {
        x = 0,
        y = 0,
        width = width,
        height = max_visible_height
    }
    local context = {
        widget = right_widget,
        offset = {
            x = width / 2,
            y = max_visible_height / 2 - 20
        },
        size = {
            w = width,
            height = height + padding
        }
    }
    local scrollbar = {
        scroll_per_click = 20 * 3,
        h_offset = -43
    }

    local scroll_area_right = TrueScrollArea(context, scissor_data, scrollbar)

    scroll_area_right.up_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    scroll_area_right.up_button:SetScale(0.5)

    scroll_area_right.down_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    scroll_area_right.down_button:SetScale(-0.5)

    scroll_area_right.scroll_bar_line:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_bar.tex")
    scroll_area_right.scroll_bar_line:SetScale(.9)

    scroll_area_right.position_marker:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
    scroll_area_right.position_marker:OnGainFocus()
    scroll_area_right.position_marker:SetScale(.6)

    return scroll_area_right
end

return WikiAboutPage
