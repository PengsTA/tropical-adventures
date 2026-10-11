local RegionalClimate = require("components/regionalclimate")
local RegionDefs = require("tools/regiondefs")

AddPrefabPostInit("forest", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    --青蛙雨
    local frograin = Upvaluehelper.GetWorldHandle(inst, "israining", "components/frograin") --下雨
    if frograin then
        -- print("找到青蛙雨了")
        local GetSpawnPoint = Upvaluehelper.GetUpvalue(frograin, "GetSpawnPoint")
        if GetSpawnPoint ~= nil then
            local old = GetSpawnPoint
            local function newGetSpawnPoint(pt)
                if not RegionalClimate.IsVanillaClimateAllowedAtPoint(pt:Get()) then
                    -- print("成功")
                    return nil
                end
                return old(pt)
            end
            Upvaluehelper.SetUpvalue(frograin, newGetSpawnPoint, "GetSpawnPoint")
        end
    end


    local wildfires = Upvaluehelper.GetEventHandle(TheWorld, "ms_lightwildfireforplayer", "components/wildfires") --野火
    if wildfires then
        local LightFireForPlayer = Upvaluehelper.GetUpvalue(wildfires, "LightFireForPlayer")
        if LightFireForPlayer ~= nil then
            local old = LightFireForPlayer
            local function NewLightFireForPlayer(player, rescheduleFn)
                if player ~= nil then
                    local x, y, z = player.Transform:GetWorldPosition()
                    if not RegionalClimate.IsVanillaClimateAllowedAtPoint(x, y, z) then
                        return
                    end
                end
                old(player, rescheduleFn)
            end
            Upvaluehelper.SetUpvalue(wildfires, NewLightFireForPlayer, "LightFireForPlayer")
        end
    end
end)

--脚印
AddPrefabPostInit("dirtpile", function(inst)
    if TheWorld.ismastersim then
        inst:DoTaskInTime(0, function(...)
            local x, y, z = inst.Transform:GetWorldPosition()
            if not TheWorld.Map:IsSubregionAtPoint(x, y, z, RegionDefs.SUBREGION.dst_mainland) then
                inst:Remove()
            end
        end)
    end
end)



--陷坑
AddComponentPostInit("sinkholespawner", function(self, inst)
    local function IsVanillaSinkholePoint(x, z)
        return RegionalClimate.IsVanillaClimateAllowedAtPoint(x, 0, z)
    end

    -- Filter the component target as soon as it is resolved. This prevents
    -- warning waves and remote notifications from being assigned to tropical
    -- players, instead of merely deleting the spawned prefab afterwards.
    local old_UpdateTarget = self.UpdateTarget
    self.UpdateTarget = function(self, targetinfo, ...)
        old_UpdateTarget(self, targetinfo, ...)
        if targetinfo.pos ~= nil and not IsVanillaSinkholePoint(targetinfo.pos.x, targetinfo.pos.z) then
            targetinfo.client = nil
            targetinfo.attacks = 0
            targetinfo.warnings = nil
            targetinfo.next_warning = nil
            targetinfo.next_attack = 0
        end
    end

    local old_DoTargetWarning = self.DoTargetWarning
    self.DoTargetWarning = function(self, targetinfo, ...)
        if targetinfo.pos ~= nil and not IsVanillaSinkholePoint(targetinfo.pos.x, targetinfo.pos.z) then
            targetinfo.attacks = 0
            targetinfo.warnings = nil
            targetinfo.next_warning = nil
            targetinfo.next_attack = 0
            return
        end
        return old_DoTargetWarning(self, targetinfo, ...)
    end

    local old_DoTargetAttack = self.DoTargetAttack
    self.DoTargetAttack = function(self, targetinfo, ...)
        if targetinfo.pos ~= nil and not IsVanillaSinkholePoint(targetinfo.pos.x, targetinfo.pos.z) then
            targetinfo.attacks = 0
            targetinfo.next_attack = nil
            return
        end
        return old_DoTargetAttack(self, targetinfo, ...)
    end

    -- The vanilla spawner randomizes a center and then fans out to the final
    -- sinkhole position. Validate every final candidate; checking only the
    -- original player position lets a border-adjacent DST attack land outside
    -- the DST region.
    local SINKHOLE_BLOCKER_TAGS = { "antlion_sinkhole_blocker" }
    self.SpawnSinkhole = function(self, spawnpt)
        if spawnpt == nil or not IsVanillaSinkholePoint(spawnpt.x, spawnpt.z) then
            return false
        end

        local x = GetRandomWithVariance(spawnpt.x, TUNING.ANTLION_SINKHOLE.RADIUS)
        local z = GetRandomWithVariance(spawnpt.z, TUNING.ANTLION_SINKHOLE.RADIUS)

        local function IsValidSinkholePosition(offset)
            local x1, z1 = x + offset.x, z + offset.z
            if not IsVanillaSinkholePoint(x1, z1) then
                return false
            end

            local tile = TheWorld.Map:GetTileAtPoint(x1, 0, z1)
            if TileGroupManager:IsTemporaryTile(tile) and tile ~= WORLD_TILES.FARMING_SOIL then
                return false
            end
            if #TheSim:FindEntities(x1, 0, z1, TUNING.ANTLION_SINKHOLE.RADIUS * 1.9, SINKHOLE_BLOCKER_TAGS) > 0 then
                return false
            end
            for dx = -1, 1 do
                for dz = -1, 1 do
                    if not TheWorld.Map:IsPassableAtPoint(
                        x1 + dx * TUNING.ANTLION_SINKHOLE.RADIUS,
                        0,
                        z1 + dz * TUNING.ANTLION_SINKHOLE.RADIUS,
                        false,
                        true
                    ) then
                        return false
                    end
                end
            end
            return true
        end

        local offset = Vector3(0, 0, 0)
        offset =
            IsValidSinkholePosition(offset) and offset or
            FindValidPositionByFan(math.random() * TWOPI, TUNING.ANTLION_SINKHOLE.RADIUS * 1.8 + math.random(), 9, IsValidSinkholePosition) or
            FindValidPositionByFan(math.random() * TWOPI, TUNING.ANTLION_SINKHOLE.RADIUS * 2.9 + math.random(), 17, IsValidSinkholePosition) or
            FindValidPositionByFan(math.random() * TWOPI, TUNING.ANTLION_SINKHOLE.RADIUS * 3.9 + math.random(), 17, IsValidSinkholePosition)

        if offset ~= nil then
            local sinkhole = SpawnPrefab("antlion_sinkhole")
            sinkhole.Transform:SetPosition(x + offset.x, 0, z + offset.z)
            sinkhole:PushEvent("startcollapse")
            return true
        end
        return false
    end
end) --farming_manager
