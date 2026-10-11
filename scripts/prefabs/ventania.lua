local assets =
{
    Asset("SOUND", "sound/forest.fsb"),
    Asset("ANIM", "anim/wind_fx.zip"),
}

local prefabs =
{
    "windtrail",
    "windswirl",
}

local GUST_DURATION = 6
local GUST_INTERVAL = .5

local function GetWindDirection(inst)
    if inst.wind_direction ~= nil then
        return inst.wind_direction
    end

    local player = GetClosestInstWithTag("player", inst, 25)
    if player ~= nil and player.components.inventory ~= nil then
        local hand_item = player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if hand_item ~= nil and hand_item.prefab == "sail_stick" then
            return player.Transform:GetRotation() + 180
        end
    end

    return TheWorld.state.isday and 225 or 45
end

local function EmitGust(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local direction = GetWindDirection(inst)
    local distance = 6 + math.random() * 10
    local offset = Vector3(math.cos(direction * DEGREES), 0, -math.sin(direction * DEGREES))
    local gust_x = x + offset.x * distance
    local gust_z = z + offset.z * distance

    local swirl = SpawnPrefab("windswirl")
    if swirl ~= nil then
        swirl.Transform:SetPosition(gust_x, y, gust_z)
        swirl.Transform:SetRotation(direction + 180)
    end

    local trail = SpawnPrefab("windtrail")
    if trail ~= nil then
        trail.Transform:SetPosition(gust_x, y, gust_z)
        trail.Transform:SetRotation(direction)
    end
end

local function OnRemove(inst)
    if inst.gust_task ~= nil then
        inst.gust_task:Cancel()
        inst.gust_task = nil
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("ventania")
    inst.persists = false

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    function inst:SetWindDirection(direction)
        inst.wind_direction = direction % 360
    end

    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wind_tree_creak")
    inst:DoTaskInTime(0, EmitGust)
    inst.gust_task = inst:DoPeriodicTask(GUST_INTERVAL, EmitGust)
    inst:DoTaskInTime(GUST_DURATION, inst.Remove)
    inst:ListenForEvent("onremove", OnRemove)

    return inst
end

return Prefab("ventania", fn, assets, prefabs)
