local DATA_FILE = "mod_config_data/ta_interior_build_height"
local client_height = 0
local loaded, edited = false, false
local dirty = false
local save_task
local adjustable_placers = {}

local function Validate(height)
    return type(height) == "number" and height == height and height >= -1 and height <= 3
end

local function Save()
    save_task = nil
    if dirty then
        SavePersistentString(DATA_FILE, tostring(client_height), false)
        dirty = false
    end
end

local function GetClientHeight()
    if not loaded then
        loaded = true
        TheSim:GetPersistentString(DATA_FILE, function(success, value)
            local height = success and tonumber(value) or nil
            if not edited and Validate(height) then
                client_height = height
            end
        end)
    end
    return client_height
end

local function AdjustClientHeight(delta)
    local height = math.max(-1, math.min(3, GetClientHeight() + delta))
    if height ~= client_height then
        client_height = height
        edited = true
        dirty = true
        if save_task ~= nil then
            save_task:Cancel()
        end
        save_task = TheWorld:DoTaskInTime(1, Save)
    end
    return client_height
end

local function SetPlayerHeight(player, height)
    if player ~= nil and Validate(height) then
        player._ta_interior_build_height = height
        return true
    end
    return false
end

local function GetPlayerHeight(player)
    return player ~= nil and player._ta_interior_build_height or 0
end

local function SyncForBuild(player, recipe)
    if player ~= ThePlayer or recipe == nil or not adjustable_placers[recipe.placer] then
        return
    end
    local height = GetClientHeight()
    if save_task ~= nil then
        save_task:Cancel()
        save_task = nil
    end
    Save()
    if TheWorld.ismastersim then
        SetPlayerHeight(player, height)
    else
        SendModRPCToServer(MOD_RPC.ham_room.build_height, height)
    end
end

return {
    GetClientHeight = GetClientHeight,
    AdjustClientHeight = AdjustClientHeight,
    SetPlayerHeight = SetPlayerHeight,
    GetPlayerHeight = GetPlayerHeight,
    SyncForBuild = SyncForBuild,
    RegisterPlacer = function(name) adjustable_placers[name] = true end,
}
