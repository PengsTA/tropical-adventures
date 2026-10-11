local InteriorBuildHeight = require "tools/interior_build_height"
AddModRPCHandler("ham_room", "build_height", InteriorBuildHeight.SetPlayerHeight)

local roomcamera = TUNING.HAMROOM.roomcamera
local InteriorRender = require "tools/interior_render"

local function UpdateRoomFocus(camera)
    local player = ThePlayer
    local center = player ~= nil and player._inhamroomcamea ~= nil and player._inhamroomcamea:value() or nil
    if center ~= nil and center:IsValid() then
        local x, _, z = center.Transform:GetWorldPosition()
        InteriorRender.EnsureBounds(x, z)
        camera.inhamroom = true
        camera.hamroomcenter = center
        camera.hamroompos = Vector3(x, 0, z)
    else
        camera.inhamroom = false
        camera.hamroomcenter = nil
        camera.hamroompos = nil
    end
end
local CAMERA_PROFILE_NAMES = require("tools/room_camera_profiles").ProfileNames

local function GetRoomKind(center)
    local kind = center ~= nil and center._ta_camera_kind ~= nil and center._ta_camera_kind:value() or ""
    if kind ~= "" then
        return kind
    end
    local id = center ~= nil and center._ta_camera_profile ~= nil and center._ta_camera_profile:value() or 0
    return CAMERA_PROFILE_NAMES[id] or "default"
end

local function GetRoomViewKey(center)
    local width = center ~= nil and center._ta_width ~= nil and center._ta_width:value() or 0
    local depth = center ~= nil and center._ta_depth ~= nil and center._ta_depth:value() or 0
    return GetRoomKind(center) .. ":" .. width .. ":" .. depth
end

local function GetCameraProfile(center)
    local profile_id = center ~= nil and center._ta_camera_profile ~= nil
        and center._ta_camera_profile:value()
        or 0
    local profile_name = CAMERA_PROFILE_NAMES[profile_id] or "default"
    return roomcamera.profiles[GetRoomKind(center)] or roomcamera.profiles[profile_name] or roomcamera.profiles.default
end

local function GetRoomDistance(profile, distance_offset)
    return math.max(roomcamera.minimum_distance, profile.distance + distance_offset)
end

local function BindKey(key, func)
    if type(key) == "string" then
        TheInput:AddKeyDownHandler(key:lower():byte(), func)
    elseif key > 0 then
        TheInput:AddKeyDownHandler(key, func)
    end
end

local room_view_distance_offsets = {}
local function AdjustRoomDistance(delta)
    local player = ThePlayer
    local center = player ~= nil and player._inhamroomcamea ~= nil and player._inhamroomcamea:value() or nil
    if center == nil or not center:IsValid() or player.Transform == nil then
        return
    end
    local width = center._ta_width ~= nil and center._ta_width:value() or 0
    local depth = center._ta_depth ~= nil and center._ta_depth:value() or 0
    local x, _, z = center.Transform:GetWorldPosition()
    local player_x, _, player_z = player.Transform:GetWorldPosition()
    if width <= 0 or depth <= 0 or math.abs(player_x - x) > width * 0.5 or math.abs(player_z - z) > depth * 0.5 then
        return
    end
    local key = GetRoomViewKey(center)
    room_view_distance_offsets[key] = math.max(-20, math.min(50, (room_view_distance_offsets[key] or 0) + delta))
end
local room_view_keys = TUNING.tro_pairedkey[TA_CONFIG.PERSONAL.room_view_key] or TUNING.tro_pairedkey["mp"]
BindKey(room_view_keys[2], function() AdjustRoomDistance(0.5) end)
BindKey(room_view_keys[1], function() AdjustRoomDistance(-0.5) end)

AddClassPostConstruct("cameras/followcamera", function(self)
    local Old_Apply = self.Apply
    function self:Apply()
        UpdateRoomFocus(self)
        if self.inhamroom == true and self.hamroompos ~= nil then
            if not self.originalheading then
                self.originalheading = self.headingtarget
            end

            self.headingtarget = 0

            local profile = GetCameraProfile(self.hamroomcenter)
            local pitch = roomcamera.pitch * DEGREES
            local heading = 0
            local fov = roomcamera.fov
            local distance = GetRoomDistance(profile, room_view_distance_offsets[GetRoomViewKey(self.hamroomcenter)] or 0)

            local currentpos = Vector3(self.hamroompos:Get())
            currentpos.x = currentpos.x - (profile.focus_back_offset or roomcamera.focus_back_offset)
            currentpos.y = currentpos.y + (roomcamera.height_offset or 0)
            local currentscreenxoffset = 0
            local cos_pitch = math.cos(pitch)
            local cos_heading = math.cos(heading)
            local sin_heading = math.sin(heading)
            local dx = -cos_pitch * cos_heading
            local dy = -math.sin(pitch)
            local dz = -cos_pitch * sin_heading
            local xoffs, zoffs = 0, 0
            if self.shake ~= nil then
                local shakeOffset = self.shake:Update(FRAMES)
                if shakeOffset ~= nil then
                    local rightOffset = self:GetRightVec() * shakeOffset.x
                    currentpos.x = currentpos.x + rightOffset.x
                    currentpos.y = currentpos.y + rightOffset.y + shakeOffset.y
                    currentpos.z = currentpos.z + rightOffset.z
                else
                    self.shake = nil
                end
            end
            if currentscreenxoffset ~= 0 then
                local hoffs = 2 * currentscreenxoffset / RESOLUTION_Y
                local magic_number = 1.03
                local screen_heights = math.tan(fov * .5 * DEGREES) * distance * magic_number
                xoffs = -hoffs * sin_heading * screen_heights
                zoffs = hoffs * cos_heading * screen_heights
            end

            TheSim:SetCameraPos(
                currentpos.x - dx * distance + xoffs,
                currentpos.y - dy * distance,
                currentpos.z - dz * distance + zoffs
            )
            TheSim:SetCameraDir(dx, dy, dz)

            local right = (heading + 90) * DEGREES
            local rx = math.cos(right)
            local ry = 0
            local rz = math.sin(right)

            local ux = dy * rz - dz * ry
            local uy = dz * rx - dx * rz
            local uz = dx * ry - dy * rx

            TheSim:SetCameraUp(ux, uy, uz)
            TheSim:SetCameraFOV(fov)
            local listendist = -.1 * distance
            TheSim:SetListener(
                dx * listendist + currentpos.x,
                dy * listendist + currentpos.y,
                dz * listendist + currentpos.z,
                dx, dy, dz,
                ux, uy, uz
            )
        else
            if self.originalheading then
                self.headingtarget = self.originalheading
                self.originalheading = nil
            end

            Old_Apply(self)
        end
    end
end)


local function OnFocalFocusDirty(inst)
    if ThePlayer ~= nil and inst == ThePlayer then
        UpdateRoomFocus(TheCamera)
        if inst.components.playervision then
            inst.components.playervision:UpdateCCTable()
        end
    end
end

--Load
local function OnFocusCamera(inst)
    if inst.spawnanddelete_hamroom then
        return
    end
    local manager = TheWorld.components.interior_manager
    local x, _, z = inst.Transform:GetWorldPosition()
    local room = manager ~= nil and manager:GetRoomAtPoint(x, z) or nil
    local ent = room ~= nil and manager.room_centers[room.id] or nil
    if ent then
        if inst._inhamroomcamea:value() ~= ent then
            inst._inhamroomcamea:set(ent)
        end
    elseif inst._inhamroomcamea:value() ~= nil then
        inst._inhamroomcamea:set(nil)
    end
end

AddPlayerPostInit(function(inst)
    inst._inhamroomcamea = net_entity(inst.GUID, "_inhamroomcamea", "inhamroomcameadirty")

    if TheWorld.ismastersim then
        inst:DoPeriodicTask(0.2, OnFocusCamera, 0.2)
    end

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("inhamroomcameadirty", OnFocalFocusDirty)
    end
end)
