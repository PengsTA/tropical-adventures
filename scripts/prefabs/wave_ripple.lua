local waveassets =
{
    Asset("ANIM", "anim/waverripple.zip"),
}

local rogueassets =
{
    Asset("ANIM", "anim/wave_rogue.zip"),
}

local WAVE_HIT_MOISTURE = 15
local WAVE_HIT_DAMAGE = 5

local ROGUEWAVE_HIT_MOISTURE = 25
local ROGUEWAVE_HIT_DAMAGE = 10
local WAVE_BOOST_ANGLE_THRESHOLD = 90
local WAVE_BOOST_KEY = "tropical_wave_boost"


local SPLASH_WETNESS = 9

local function GetActiveBoat(player)
    if player.components.sailor ~= nil and player.components.sailor:GetBoat() ~= nil then
        return player.components.sailor:GetBoat()
    end
end

local function DamageActiveBoat(player, amount)
    local boat = GetActiveBoat(player)
    if boat == nil then
        return
    end
    if boat.components.boathealth ~= nil then
        boat.components.boathealth:TryApplyImpact(-amount, "wave", player, .4)
    end
end

local function GetWaveSailor(other)
    if other == nil or not other:IsValid() or not other:HasTag("player") then
        return nil
    end

    local sailor = other.components.sailor
    local boat = sailor ~= nil and sailor:GetBoat() or nil
    return boat ~= nil and boat:IsValid() and boat:HasTag("boatsw") and other or nil
end

local function GetAngleDifference(first, second)
    local difference = math.abs(first - second) % 360
    return difference > 180 and 360 - difference or difference
end

local function ApplyWaveBoost(player, multiplier, duration, sanity_delta)
    local locomotor = player.components.locomotor
    if locomotor == nil then
        return
    end

    if player.wave_boost_task ~= nil then
        player.wave_boost_task:Cancel()
    end
    locomotor:SetExternalSpeedMultiplier(player, WAVE_BOOST_KEY, multiplier)
    player.wave_boost_task = player:DoTaskInTime(duration, function()
        if player.components.locomotor ~= nil then
            player.components.locomotor:RemoveExternalSpeedMultiplier(player, WAVE_BOOST_KEY)
        end
        player.wave_boost_task = nil
    end)
    if sanity_delta ~= nil and player.components.sanity ~= nil then
        player.components.sanity:DoDelta(sanity_delta)
    end
end

local function splash(inst)
    local wave_splash = SpawnPrefab("wave_splash")
    local pos = inst:GetPosition()
    if wave_splash ~= nil then
        TintByOceanTile(wave_splash)
        wave_splash.Transform:SetPosition(pos.x, pos.y, pos.z)
    end

    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 4, { "player" })
    for _, v in pairs(ents) do
        local moisture = v.components.moisture
        if moisture ~= nil then
            local waterproofness = (v.components.inventory and math.min(v.components.inventory:GetWaterproofness(), 1)) or
            0
            moisture:DoDelta(SPLASH_WETNESS * (1 - waterproofness))

            local entity_splash = SpawnPrefab("splash")
            entity_splash.Transform:SetPosition(v:GetPosition():Get())
        end
    end

    inst:Remove()
end

local function splash2(inst)
    local wave_splash = SpawnPrefab("splash_water")
    local pos = inst:GetPosition()
    if wave_splash ~= nil then
        TintByOceanTile(wave_splash)
        wave_splash.Transform:SetPosition(pos.x, pos.y, pos.z)
    end

    inst:Remove()
end

local function oncollidewave(inst, other)
    if not inst.waveactive then
        return
    end

    local sailor = GetWaveSailor(other)
    local barrel = GetClosestInstWithTag("redbarrel", inst, 2)
    if barrel then
        if barrel.components.workable ~= nil then
            barrel.components.workable:WorkedBy(barrel, 1)
        end
        splash(inst)
        return
    end
    local wavebreaker = GetClosestInstWithTag("quebraonda", inst, 2)
    if wavebreaker then
        splash(inst)
        return
    end

    local boostThreshold = WAVE_BOOST_ANGLE_THRESHOLD

    if sailor then
        local moving = sailor.sg ~= nil and sailor.sg:HasStateTag("moving")
        local playerAngle = sailor.Transform:GetRotation()
        if playerAngle < 0 then playerAngle = playerAngle + 360 end
        local waveAngle = inst.Transform:GetRotation()
        if waveAngle < 0 then waveAngle = waveAngle + 360 end
        local angleDiff = GetAngleDifference(waveAngle, playerAngle)


        if angleDiff < boostThreshold and moving then
            local boat = GetActiveBoat(sailor)
            local surfing = boat ~= nil and (boat.prefab == "surfboard" or boat:HasTag("surfboard"))
            ApplyWaveBoost(sailor, surfing and 2 or 1.5, surfing and 3 or 2,
                sailor.prefab == "walani" and TUNING.SANITY_SUPERTINY or nil)

            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wave_boost")
            splash2(inst)
        else
            DamageActiveBoat(sailor, WAVE_HIT_DAMAGE)
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wave_break")
            splash(inst)
        end
    end
end


local function oncolliderogue(inst, other)
    if not inst.waveactive then
        return
    end

    local sailor = GetWaveSailor(other)
    local barrel = GetClosestInstWithTag("redbarrel", inst, 2)
    if barrel then
        if barrel.components.workable ~= nil then
            barrel.components.workable:WorkedBy(barrel, 1)
        end
        splash(inst)
        return
    end

    local boostThreshold = WAVE_BOOST_ANGLE_THRESHOLD

    if sailor then
        local moving = sailor.sg ~= nil and sailor.sg:HasStateTag("moving")
        local playerAngle = sailor.Transform:GetRotation()
        if playerAngle < 0 then playerAngle = playerAngle + 360 end
        local waveAngle = inst.Transform:GetRotation()
        if waveAngle < 0 then waveAngle = waveAngle + 360 end
        local angleDiff = GetAngleDifference(waveAngle, playerAngle)


        if angleDiff < boostThreshold and moving and sailor.prefab == "walani" then
            local boat = GetActiveBoat(sailor)
            local surfing = boat ~= nil and (boat.prefab == "surfboard" or boat:HasTag("surfboard"))
            ApplyWaveBoost(sailor, surfing and 3 or 2.25, surfing and 4.5 or 3,
                sailor.prefab == "walani" and TUNING.SANITY_SUPERTINY * 1.5 or nil)

            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wave_boost")
            splash2(inst)
        else
            DamageActiveBoat(sailor, ROGUEWAVE_HIT_DAMAGE)
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wave_break")
            splash(inst)
        end
    end
end

local function CheckGround(inst)
    if inst.sg:HasStateTag("lowering") then
        return
    end

    --Check if I'm about to hit land
    local x, y, z = inst.Transform:GetWorldPosition()
    local vx, vy, vz = inst.Physics:GetVelocity()

    local plataforma = GetClosestInstWithTag("walkableplatform", inst, 6)
    local ancora = GetClosestInstWithTag("anchor_lowered", inst, 9)


    if plataforma then
        if not ancora then
            local speed_modifier = VecUtil_Length(vx, vz)
            vx, vz = VecUtil_Normalize(vx, vz)
            if plataforma.components.boatphysics then
                local boat_physics = plataforma.components.boatphysics
                boat_physics:ApplyForce(vx, vz, speed_modifier)
            end
        end
        splash(inst)
        return
    end


    local ground = TheWorld.Map:GetTile(TheWorld.Map:GetTileCoordsAtPoint(x, y, z))
    if ground == GROUND.INVALID or ground == GROUND.IMPASSABLE then
        splash(inst)
        return
    end

    if TheWorld.Map:IsVisualGroundAtPoint(x + vx, y, z + vz) then
        splash(inst)
        return
    end
end

local function activate_collision(inst)
    inst.Physics:SetCollides(false) --Still will get collision callback, just not dynamic collisions.
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
end

local function onRemove(inst)
    if inst and inst.soundloop then
        inst.SoundEmitter:KillSound(inst.soundloop)
    end
end

local function onSleep(inst)
    inst:Remove()
end

local function ripple(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    trans:SetEightFaced()
    inst.entity:AddPhysics()
    inst.Physics:SetSphere(1)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:SetCollisionMask(
        COLLISION.WORLD,
        COLLISION.OBSTACLES,
        COLLISION.SMALLOBSTACLES,
        COLLISION.CHARACTERS,
        COLLISION.GIANTS
    )
    inst.Physics:SetCollides(false)
    inst.done = false
    inst.persists = false
    local anim = inst.entity:AddAnimState()
    inst.AnimState:SetBuild("waverripple")
    inst.AnimState:SetBank("wave_ripple_sw")

    inst:AddTag("FX")
    inst:AddTag("aquatic")
    inst:AddTag("ondamedia")
    inst:AddTag("wave")
    inst:AddTag("scarytoprey")
    inst:AddTag("tropical_wave")

    if not TheNet:IsDedicated() then
        inst:AddComponent("boattrail")
        inst.components.boattrail.effect_spawn_rate = 2.5
        inst.components.boattrail.radius = 1
        inst.components.boattrail.scale_x = .75
        inst.components.boattrail.scale_z = .75
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- TintByOceanTile can remove waves on invalid tiles; only the server owns their lifetime.
    TintByOceanTile(inst)
    inst.OnEntitySleep = onSleep
    inst.hitdamage = -WAVE_HIT_DAMAGE
    inst.hitmoisture = WAVE_HIT_MOISTURE
    inst:SetStateGraph("SGwavesw")
    inst.idle_time = 5
    inst.soundrise = "small"
    inst.activate_collision = activate_collision
    inst.Physics:SetCollisionCallback(oncollidewave)

    inst:DoPeriodicTask(.75, CheckGround)

    return inst
end

local function rogue(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    trans:SetEightFaced()
    inst.entity:AddPhysics()
    inst.Physics:SetSphere(1)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:SetCollisionMask(
        COLLISION.WORLD,
        COLLISION.OBSTACLES,
        COLLISION.SMALLOBSTACLES,
        COLLISION.CHARACTERS,
        COLLISION.GIANTS
    )
    inst.Physics:SetCollides(false)
    inst.done = false
    inst.persists = false
    local anim = inst.entity:AddAnimState()
    anim:SetBuild("wave_rogue")
    anim:SetBank("wave_rogue")

    inst:AddTag("aquatic")
    inst:AddTag("FX")
    inst:AddTag("wave")
    inst:AddTag("scarytoprey")
    inst:AddTag("tropical_wave")

    if not TheNet:IsDedicated() then
        inst:AddComponent("boattrail")
        inst.components.boattrail.effect_spawn_rate = 2.5
        inst.components.boattrail.radius = 1.25
        inst.components.boattrail.scale_x = 1.1
        inst.components.boattrail.scale_z = 1.1
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    TintByOceanTile(inst)
    inst.hitdamage = -ROGUEWAVE_HIT_DAMAGE
    inst.hitmoisture = ROGUEWAVE_HIT_MOISTURE

    inst:SetStateGraph("SGwavesw")

    inst.idle_time = 5

    inst.soundrise = "large"
    inst.soundloop = "large_LP"
    inst.soundtidal = "tidal_wave"

    inst.activate_collision = activate_collision
    inst.Physics:SetCollisionCallback(oncolliderogue)
    inst:ListenForEvent("onremove", onRemove)

    inst:DoPeriodicTask(.75, CheckGround)
    inst.OnEntitySleep = onSleep

    return inst
end

return Prefab("common/fx/wave_ripple", ripple, waveassets),
    Prefab("common/fx/rogue_wave", rogue, rogueassets)
