AddComponentPostInit("hounded", function(cmp)
    local _spawndata = Upvaluehelper.GetUpvalue(cmp.SetSpawnData, "_spawndata")
    local _SummonSpawn, up_i, prv_fn = Upvaluehelper.GetUpvalue(cmp.SummonSpawn, "SummonSpawn")
    if not _SummonSpawn then
        _SummonSpawn, up_i, prv_fn = Upvaluehelper.GetUpvalue(cmp.ForceReleaseSpawn, "ReleaseSpawn", "SummonSpawn") -- 兼容其它修改了hounded组件的SummonSpawn函数的模组...
    end
    if not (_spawndata and _SummonSpawn) then return end
    -- local _GetSpawnPrefab = Upvaluehelper.GetUpvalue(_SummonSpawn, "GetSpawnPrefab")
    local _GetSpawnPoint = Upvaluehelper.GetUpvalue(_SummonSpawn, "GetSpawnPoint")
    -- local _GetSpecialSpawnChance = Upvaluehelper.GetUpvalue(_GetSpawnPrefab, "GetSpecialSpawnChance")
    local _SPAWN_DIST = Upvaluehelper.GetUpvalue(_GetSpawnPoint, "SPAWN_DIST")

    local function SummonSpawn(pt, upgrade, radius_override)
        -- local map = TheWorld.Map
        local x, y, z = pt:Get()

        -- local spawndat = deepcopy(_spawndata)

        if TheWorld:HasTag("cave") then
            _spawndata.base_prefab = "worm"
            _spawndata.winter_prefab = "worm"
            _spawndata.summer_prefab = "worm"
            _spawndata.upgrade_spawn = "worm_boss"
        elseif TheWorld.Map:HasTopologyTagAtPoint(x, 0, z, "civilized") then
            _spawndata.base_prefab = " "
            _spawndata.winter_prefab = " "
            _spawndata.summer_prefab = " "
            _spawndata.upgrade_spawn = " "
        elseif TheWorld.Map:IsPrimaryRegionAtPoint(x, 0, z, "hamlet") then
            _spawndata.base_prefab = "circlingbat"
            _spawndata.winter_prefab = "circlingbat"
            _spawndata.summer_prefab = "circlingbat"
            _spawndata.upgrade_spawn = " "
        elseif TheWorld.Map:IsPrimaryRegionAtPoint(x, 0, z, "shipwrecked") then
            _spawndata.base_prefab = "crocodog"
            _spawndata.winter_prefab = "watercrocodog"
            _spawndata.summer_prefab = "poisoncrocodog"
            _spawndata.upgrade_spawn = " "
        else
            _spawndata.base_prefab = "hound"
            _spawndata.winter_prefab = "icehound"
            _spawndata.summer_prefab = "firehound"
            _spawndata.upgrade_spawn = "warglet"
        end

        if _spawndata.base_prefab == "circlingbat" then
            _SPAWN_DIST = 4
        else
            _SPAWN_DIST = 30
        end

        Upvaluehelper.SetUpvalue(_GetSpawnPoint, _SPAWN_DIST, "SPAWN_DIST")
        return _SummonSpawn(pt, upgrade, radius_override)
    end

    debug.setupvalue(prv_fn, up_i, SummonSpawn)
end)
