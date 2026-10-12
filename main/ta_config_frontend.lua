-- Only Aporkalypse uses the world menu as an editor for shared mod configuration.
local shared_name = "aporkalypse"

KnownModIndex._ta_world_config_editors = KnownModIndex._ta_world_config_editors or {}
if KnownModIndex._ta_world_config_editors[modname] then return end
KnownModIndex._ta_world_config_editors[modname] = true

local menus = setmetatable({}, { __mode = "k" })
local refreshing = false
local function GetSavedValue()
    local info = KnownModIndex:GetModInfo(modname)
    for _, option in ipairs(info and info.configuration_options or {}) do
        if option.name == shared_name then
            if option.saved_server ~= nil then return option.saved_server end
            if option.saved ~= nil then return option.saved end
            return option.default
        end
    end
end

local function RefreshMenus()
    if refreshing then return end
    refreshing = true
    local screen = TheFrontEnd and TheFrontEnd:GetOpenScreenOfType("ServerCreationScreen")
    if screen then
        for _, tab in pairs(screen.world_tabs or {}) do
            for _, menu in ipairs(tab.worldsettings_widgets or {}) do menus[menu] = true end
        end
    end
    for menu in pairs(menus) do
        if menu.inst:IsValid() then menu:Refresh(true) end
    end
    refreshing = false
end

local WorldSettingsMenu = require("widgets/redux/worldsettings/worldsettingsmenu")
local get_value = WorldSettingsMenu.GetValueForOption
function WorldSettingsMenu:GetValueForOption(name, ...)
    if KnownModIndex:IsModEnabled(modname) then
        menus[self] = true
        if name == shared_name and self.levelcategory == LEVELCATEGORY.SETTINGS then
            return GetSavedValue() or get_value(self, name, ...)
        end
    end
    return get_value(self, name, ...)
end

local SettingsList = require("widgets/redux/worldsettings/settingslist")
local spinner_changed = SettingsList.OnSpinnerChanged
function SettingsList:OnSpinnerChanged(option, spinner, value, ...)
    if KnownModIndex:IsModEnabled(modname) and option and option.group == "ta_climate"
        and option.name == shared_name
        and not refreshing and not self.forceupdate
        and not (self.parent_widget and self.parent_widget.refreshing) then
        local config = KnownModIndex:LoadModConfigurationOptions(modname, false)
        for _, entry in ipairs(config or {}) do
            if entry.name == shared_name then
                entry.saved, entry.saved_server = value, value
                KnownModIndex:SaveConfigurationOptions(function() end, modname, config, false)
                break
            end
        end
    end
    return spinner_changed(self, option, spinner, value, ...)
end

local save_config = KnownModIndex.SaveConfigurationOptions
function KnownModIndex:SaveConfigurationOptions(callback, owner, config, local_config, ...)
    if owner ~= modname or local_config or config == nil then
        return save_config(self, callback, owner, config, local_config, ...)
    end
    local value
    for _, entry in ipairs(config) do
        if entry.name == shared_name then value = entry.saved end
    end
    return save_config(self, function(...)
        if callback then callback(...) end
        local info = self:GetModInfo(owner)
        for _, entry in ipairs(info and info.configuration_options or {}) do
            if entry.name == shared_name and value ~= nil then
                entry.saved, entry.saved_server = value, value
            end
        end
        RefreshMenus()
    end, owner, config, local_config, ...)
end
