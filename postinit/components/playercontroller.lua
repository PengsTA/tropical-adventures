local Utils = require("tools/utils")

AddClassPostConstruct("components/playercontroller", function(PlayerController)
    local RUBBER_BAND_PING_TOLERANCE_IN_SECONDS = 0.7
    local RUBBER_BAND_DISTANCE = 4
    local OldOnRemoteStartHop = PlayerController.OnRemoteStartHop

    local function GetSailingBoat(inst)
        local sailor = inst.components ~= nil and inst.components.sailor or nil
        local boat = sailor ~= nil and sailor:GetBoat() or nil
        return boat ~= nil and boat:IsValid() and boat:HasTag("boatsw") and boat or nil
    end

    function PlayerController:OnRemoteStartHop(x, z, platform)
        local boat = GetSailingBoat(self.inst)
        if boat == nil then
            return OldOnRemoteStartHop(self, x, z, platform)
        end

        if not self.ismastersim or not self:IsEnabled() or self.handler ~= nil then
            return
        end

        local my_x, _, my_z = self.inst.Transform:GetWorldPosition()
        local target_x, target_z = x, z
        local platform_for_velocity_calculation = platform

        if platform ~= nil then
            target_x, target_z = platform.components.walkableplatform:GetEmbarkPosition(my_x, my_z)
        else
            platform_for_velocity_calculation = boat
        end

        if platform == nil and GLOBAL.TheWorld.Map:IsOceanAtPoint(target_x, 0, target_z) then
            return
        end

        local hop_dir_x, hop_dir_z = target_x - my_x, target_z - my_z
        local hop_distance_sq = hop_dir_x * hop_dir_x + hop_dir_z * hop_dir_z
        local target_velocity_rubber_band_distance = 0

        local platform_physics = platform_for_velocity_calculation ~= nil and platform_for_velocity_calculation.Physics or nil
        if platform_physics ~= nil then
            local platform_velocity_x, platform_velocity_z = platform_physics:GetVelocity()
            if (platform_velocity_x ~= 0 or platform_velocity_z ~= 0) and hop_distance_sq > 0 then
                local hop_distance = math.sqrt(hop_distance_sq)
                local velocity = math.sqrt(platform_velocity_x * platform_velocity_x + platform_velocity_z * platform_velocity_z)
                if velocity > 0 then
                    local hop_dir_dot_platform_velocity =
                        (platform_velocity_x / velocity) * (hop_dir_x / hop_distance) +
                        (platform_velocity_z / velocity) * (hop_dir_z / hop_distance)
                    if hop_dir_dot_platform_velocity > 0 then
                        target_velocity_rubber_band_distance = RUBBER_BAND_PING_TOLERANCE_IN_SECONDS * velocity * hop_dir_dot_platform_velocity
                    end
                end
            end
        end

        local locomotor = self.inst.components.locomotor
        local hop_rubber_band_distance = RUBBER_BAND_DISTANCE + target_velocity_rubber_band_distance + locomotor:GetHopDistance()
        if hop_distance_sq > hop_rubber_band_distance * hop_rubber_band_distance then
            return
        end

        self.remote_vector.y = 6
        locomotor:StartHopping(x, z, platform)
    end

    Utils.FnDecorator(PlayerController, "GetActionButtonAction", nil, function(rets, self, _force_target, ...)
        local action_distance_sq = 1023
        if #rets > 0 and rets[1].target ~= nil then
            action_distance_sq = self.inst:GetDistanceSqToInst(rets[1].target)
        end
        local shop = FindEntity(self.inst, 2, function(inst)
            return inst.prefab == "shop_buyer"
        end)
        if shop ~= nil and self.inst:GetDistanceSqToInst(shop) < action_distance_sq then
            return { BufferedAction(self.inst, shop, ACTIONS.SHOP) }
        end
        if #rets > 0 then return rets end
        local door = FindEntity(self.inst, 2, nil, { "hamletteleport" })
        if door ~= nil then
            return { BufferedAction(self.inst, door, ACTIONS.JUMPIN) }
        end
    end)
end)
