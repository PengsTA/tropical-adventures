-- World settings are an editor for the same options exposed by modinfo.
local option_groups = {
    ta_worldgen = LEVELCATEGORY.WORLDGEN,
    ta_climate = LEVELCATEGORY.SETTINGS,
}
local option_categories = {}
for _, option in ipairs(modinfo.ta_world_options.worldgen_options) do
    option_categories[option.name] = LEVELCATEGORY.WORLDGEN
end
for _, option in ipairs(modinfo.ta_world_options.climate_options) do
    option_categories[option.name] = LEVELCATEGORY.SETTINGS
end

KnownModIndex._ta_world_config_editors = KnownModIndex._ta_world_config_editors or {}
if KnownModIndex._ta_world_config_editors[modname] then
    return
end
KnownModIndex._ta_world_config_editors[modname] = true

local menus = setmetatable({}, { __mode = "k" })
local refreshing = false

local function GetSavedValue(name)
    local info = KnownModIndex:GetModInfo(modname)
    for _, option in ipairs(info and info.configuration_options or {}) do
        if option.name == name then
            if option.saved_server ~= nil then
                return option.saved_server
            end
            if option.saved ~= nil then
                return option.saved
            end
            return option.default
        end
    end
end

local function RefreshMenus()
    if refreshing then return end
    refreshing = true
    -- Existing forest rows may have been built before this hook was installed.
    local screen = TheFrontEnd and TheFrontEnd:GetOpenScreenOfType("ServerCreationScreen")
    if screen then
        for _, tab in pairs(screen.world_tabs or {}) do
            for _, menu in ipairs(tab.worldsettings_widgets or {}) do
                menus[menu] = true
            end
        end
    end
    for menu in pairs(menus) do
        if menu.inst:IsValid() then
            menu:Refresh(true)
        end
    end
    refreshing = false
end

local WorldSettingsMenu = require("widgets/redux/worldsettings/worldsettingsmenu")
local get_value = WorldSettingsMenu.GetValueForOption
function WorldSettingsMenu:GetValueForOption(name, ...)
    if KnownModIndex:IsModEnabled(modname) and option_categories[name] == self.levelcategory then
        menus[self] = true
        local value = GetSavedValue(name)
        if value ~= nil then
            return value
        end
    end
    return get_value(self, name, ...)
end

local SettingsList = require("widgets/redux/worldsettings/settingslist")
local spinner_changed = SettingsList.OnSpinnerChanged
function SettingsList:OnSpinnerChanged(option, spinner, value, ...)
    if KnownModIndex:IsModEnabled(modname)
        and option and option_groups[option.group] == option_categories[option.name]
        and option_categories[option.name] ~= nil then
        -- SetSelected fires OnChanged even when a refresh changes the spinner.
        if refreshing or self.forceupdate or (self.parent_widget and self.parent_widget.refreshing) then
            return spinner_changed(self, option, spinner, value, ...)
        end
        -- Save the complete list: SaveConfigurationOptions replaces the file.
        local config = KnownModIndex:LoadModConfigurationOptions(modname, false)
        if config then
            for _, entry in ipairs(config) do
                if entry.name == option.name then
                    entry.saved = value
                    entry.saved_server = value
                    KnownModIndex:SaveConfigurationOptions(function() end, modname, config, false)
                    break
                end
            end
        end
        spinner_changed(self, option, spinner, value, ...)
        return
    end
    return spinner_changed(self, option, spinner, value, ...)
end

local save_config = KnownModIndex.SaveConfigurationOptions
function KnownModIndex:SaveConfigurationOptions(callback, owner, config, local_config, ...)
    if owner ~= modname or local_config or config == nil then
        return save_config(self, callback, owner, config, local_config, ...)
    end

    local values = {}
    for _, entry in ipairs(config) do
        if option_categories[entry.name] ~= nil then
            values[entry.name] = entry.saved
        end
    end
    return save_config(self, function(...)
        callback(...)
        -- Applying the dialog may rebuild modinfo; update the current cache.
        local info = self:GetModInfo(owner)
        for _, entry in ipairs(info and info.configuration_options or {}) do
            if values[entry.name] ~= nil then
                entry.saved = values[entry.name]
                entry.saved_server = values[entry.name]
            end
        end
        RefreshMenus()
    end, owner, config, local_config, ...)
end
