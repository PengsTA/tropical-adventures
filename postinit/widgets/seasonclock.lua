if TheNet:IsDedicated() then return end

local dirs = { "widgets/seasonclock", "widgets/cb/seasonclock" }

local state, SeasonClock, dir
for i = 1, #dirs do
    state, SeasonClock = pcall(require, dirs[i])
    if state then
        dir = dirs[i]
        print("Loaded SeasonClock from " .. dir)
        break
    end
end

if not state then return end


local COLOUR_ROG =
{
    AUTUMN = Vector3(205 / 255, 79 / 255, 57 / 255),
    WINTER = Vector3(149 / 255, 191 / 255, 242 / 255),
    SPRING = Vector3(84 / 168, 200 / 255, 84 / 255),
    SUMMER = Vector3(205 / 255, 133 / 255, 0 / 255),
}

local COLOUR_SW =
{
    AUTUMN = Vector3(255 / 255, 206 / 255, 139 / 255),
    WINTER = Vector3(200 / 255, 220 / 255, 255 / 255),
    SPRING = Vector3(0 / 255, 150 / 255, 150 / 255),
    SUMMER = Vector3(180 / 255, 80 / 255, 57 / 255),
}

local COLOUR_HAM =
{
    AUTUMN = Vector3(255 / 255, 226 / 255, 139 / 255),
    WINTER = Vector3(220 / 255, 220 / 255, 255 / 255),
    SPRING = Vector3(104 / 168, 200 / 255, 80 / 255),
    SUMMER = Vector3(60 / 168, 179 / 255, 113 / 255),
}

local COLOUR_VOLCANO =
{
    AUTUMN = Vector3(180 / 255, 80 / 255, 57 / 255),
    WINTER = Vector3(238 / 255, 121 / 255, 66 / 255),
    SPRING = Vector3(180 / 255, 80 / 255, 57 / 255),
    SUMMER = Vector3(100 / 255, 80 / 255, 57 / 255),
}


local seasonmap = {
    rog = {
        autumn = "autumn",
        winter = "winter",
        spring = "spring",
        summer = "summer",
    },
    sw = {
        autumn = "mild",
        winter = "hurricane",
        spring = "monsoon",
        summer = "dry",
    },
    ham = {
        autumn = "temperate",
        winter = "humid",
        spring = "rainy",
        summer = "lush",
    },
}

-- The bundled Shipwrecked strings use the original enum keys wet/green even
-- though the climate API exposes their player-facing Hurricane/Monsoon names.
-- Keep that translation detail at the UI boundary only.
local seasonlabelkeys = {
    hurricane = "WET",
    monsoon = "GREEN",
}

local function GetRegionalSeasonLabel(profile, fallback)
    if profile == "rainy" then
        return TUNING.LANGUAGE_CHINESE and "雨季" or "Rainy"
    end
    return STRINGS.UI.SANDBOXMENU[seasonlabelkeys[profile] or string.upper(profile)] or fallback
end

AddClassPostConstruct(dir, function(self)
    local COLOURS = Upvaluehelper.GetUpvalue(self.OnSeasonLengthsChanged, "COLOURS")

    function self:ChangeRegion()
        if ThePlayer and TheWorld then
            if ThePlayer:AwareInShipwreckedVolcanoRegion() then
                tableutil.deep_merge(COLOURS, COLOUR_VOLCANO, true)
            elseif ThePlayer:AwareInShipwreckedRegion() then
                tableutil.deep_merge(COLOURS, COLOUR_SW, true)
            elseif ThePlayer:AwareInHamletRegion() then
                tableutil.deep_merge(COLOURS, COLOUR_HAM, true)
            else
                tableutil.deep_merge(COLOURS, COLOUR_ROG, true)
                -- STRINGS.UI.SERVERLISTINGSCREEN.SEASONS = seasonmap.rog  ----这样的话没法转换成中文
            end
            self:OnCyclesChanged()
            self:OnSeasonLengthsChanged()

            ---需要给大陆加forest标签并调整regionaware----这个再说
            -- if TheWorld.state.isnight then
            --     self._phase = "dusk"
            --     self:OnPhaseChanged("night")
            -- elseif TheWorld.state.isdusk then
            --     self._phase = "day"
            --     self:OnPhaseChanged("dusk")
            -- else
            --     self._phase = "night"
            --     self:OnPhaseChanged("day")
            -- end
        end
    end

    self.inst:DoTaskInTime(0, function() self:ChangeRegion() end)

    -- ThePlayer:ListenForEvent("changearea", function(inst, data)
    ThePlayer:ListenForEvent("regionchange_client", function(inst, data)
        self:ChangeRegion()
    end)

    TheWorld:ListenForEvent("aporkalypsephasechanged", function(_, phase)
        self:ChangeRegion()
    end)

    local GetSeasonString = self.GetSeasonString
    function self:GetSeasonString()
        local str = GetSeasonString(self)
        if ThePlayer and TheWorld then
            local season = TheWorld.state.season
            if ThePlayer:AwareInShipwreckedRegion() then
                str = GetRegionalSeasonLabel(seasonmap.sw[season], str)
            elseif ThePlayer:AwareInHamletRegion() then
                str = GetRegionalSeasonLabel(seasonmap.ham[season], str)
            end
        end
        if TheWorld.state.isaporkalypse then
            str = string.format("%s\n(%s)", str, STRINGS.UI.SANDBOXMENU.APORKALYPSE or "Aporkalypse")
        end
        return str
    end
end)

----适配紧凑型/最简易季节时钟
local function HookSeasonBadge(self)
    if self.season then
        local season_trans = {"autumn", "winter", "spring", "summer"} ----季节列表
        local season_lookup = {}
        for i,v in ipairs(season_trans) do season_lookup[v] = i end
        local COMPACTSEASONS ----紧凑型季节时钟
        local MICROSEASONS ----最简易季节时钟

        local old_Scale = self.season.bg:GetScale()
        local old_Position = self.season.num:GetPosition()
        local ChangedScale = false

        local function UpdateText(focused)
            local str = self.season.num:GetString()
            if focused and not MICROSEASONS then ----离下一季还有几天
                str = str:gsub("(%d+)(.*)\n(.*)", function(days, to, season)
                    if season then
                        local world_season = TheWorld.state.season
                        local season_i = season_lookup[world_season]
                        local season_length = 0

                        if season_i == nil then ----当前季节不在我们的季节列表中
                            return days .. to .. "\n" .. season
                        end

                        repeat
                            season_i = season_i%#season_trans + 1
                            local lengthstr = season_trans[season_i] .. "length"
                            season_length = TheWorld.state[lengthstr]
                        until season_length and season_length > 0

                        if ThePlayer and TheWorld then
                            if ThePlayer:AwareInShipwreckedRegion() then
                                season = GetRegionalSeasonLabel(seasonmap.sw[season_trans[season_i]], season)
                            elseif ThePlayer:AwareInHamletRegion() then
                                season = GetRegionalSeasonLabel(seasonmap.ham[season_trans[season_i]], season)
                            end
                        end
                    end
                    return days .. to .. "\n" .. season
                end)
            else
                if MICROSEASONS then
                    if focused then
                        if ThePlayer and TheWorld then
                            local season = TheWorld.state.season
                            if ThePlayer:AwareInShipwreckedRegion() then
                                str = GetRegionalSeasonLabel(seasonmap.sw[season], str)
                            elseif ThePlayer:AwareInHamletRegion() then
                                str = GetRegionalSeasonLabel(seasonmap.ham[season], str)
                            end
                        end
                        if TheWorld.state.isaporkalypse then
                            str = string.format("%s\n(%s)", str, STRINGS.UI.SANDBOXMENU.APORKALYPSE or "Aporkalypse")
                        end
                        if string.find(str, "\n") then ----有换行说明大灾变了
                            self.season.bg:SetScale(0.65, .645, 1) ----调整背景大小以塞得下字符串
                            self.season.num:SetPosition(0, -40.5) ----原来的字有点偏
                            ChangedScale = true
                        end
                    elseif ChangedScale then
                        self.season.bg:SetScale(old_Scale.x, old_Scale.y, old_Scale.z)
                        self.season.num:SetPosition(old_Position.x, old_Position.y, old_Position.z)
                        ChangedScale = false
                    end
                elseif COMPACTSEASONS then
                    str = str:gsub("(.*)\n(.*)", function(progress, season)
                        if season then
                            if ThePlayer and TheWorld then
                                local world_season = TheWorld.state.season
                                if ThePlayer:AwareInShipwreckedRegion() then
                                    season = GetRegionalSeasonLabel(seasonmap.sw[world_season], season)
                                elseif ThePlayer:AwareInHamletRegion() then
                                    season = GetRegionalSeasonLabel(seasonmap.ham[world_season], season)
                                end
                            end
                            if TheWorld.state.isaporkalypse then
                                season = string.format("%s\n(%s)", season, STRINGS.UI.SANDBOXMENU.APORKALYPSE or "Aporkalypse")

                                self.season.bg:SetScale(0.65, 1, 1) ----调整背景大小以塞得下字符串
                                self.season.num:SetPosition(0, -40.5) ----原来的字有点偏
                                ChangedScale = true
                            elseif ChangedScale then
                                self.season.bg:SetScale(old_Scale.x, old_Scale.y, old_Scale.z)
                                self.season.num:SetPosition(old_Position.x, old_Position.y, old_Position.z)
                                ChangedScale = false
                            end
                        end
                        return progress .. "\n" .. season
                    end)
                end
            end
            self.season.num:SetString(str)
        end
        local old_UpdateText = self.season.UpdateText
        COMPACTSEASONS = Upvaluehelper.GetUpvalue(old_UpdateText, "COMPACTSEASONS")
        MICROSEASONS = Upvaluehelper.GetUpvalue(old_UpdateText, "MICROSEASONS")

        local new_UpdateText = function(focused, ...)
            old_UpdateText(focused, ...)
            UpdateText(focused)
        end
        self.season.UpdateText = new_UpdateText
        Upvaluehelper.SetUpvalue(self.season.OnGainFocus, new_UpdateText, "UpdateText") ----或者修改self.season.OnLoseFocus，它们用的是同一个上值

        ----切换地区时更新字符串
        ThePlayer:ListenForEvent("regionchange_client", function(inst, data)
            new_UpdateText(false)
        end)

        TheWorld:ListenForEvent("aporkalypsephasechanged", function(_, phase)
            new_UpdateText(false)
        end)
    end
end

----只有一个会通过self.season的判断
AddClassPostConstruct("widgets/statusdisplays", HookSeasonBadge) ----紧凑型时钟
AddClassPostConstruct("widgets/controls", HookSeasonBadge) ----最简易时钟
