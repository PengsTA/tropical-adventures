require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/pig_ruins_vines_door.zip"),
    Asset("ANIM", "anim/pig_ruins_vines_build.zip"),
}

local assets_wall =
{
    Asset("ANIM", "anim/pig_ruins_vines_wall.zip"),
    Asset("ANIM", "anim/pig_ruins_vines_build.zip"),
}

local prefabs =
{

}

local RUINS_ENTRANCE_VINES_HACKS = 4
local RUINS_DOOR_VINES_HACKS = 2

local function getanimname(inst)
    local stage_string = "_closed"

    if inst.stage == 1 then
        stage_string = "_med"
    elseif inst.stage == 0 then
        stage_string = "_open"
    end

    return inst.facing .. stage_string
end

local function blockdoor(inst)
    -- send event to dissable the door.  the listener will respond if it's the door OR the target door
    if inst.door then
        inst.door.components.vineable:SetDoorDissabled(true)
    end
end

local function cleardoor(inst)
    -- send event to enable the door. the listener will respond if it's the door OR the target door
    if inst.door then
        inst.door.components.vineable:SetDoorDissabled(false)
    end
end

local function regrow(inst)
    -- this is just for viuals, it doesn't actually lock the assotiated door.
    if inst.stage ~= 2 then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/vine_grow")
        inst.stage = 2
        inst.components.workable.workable = true
        inst.components.workable.workleft = inst.components.workable.maxwork
        inst:RemoveTag("NOCLICK")
        inst.AnimState:PlayAnimation(getanimname(inst) .. "_pre", true)
        inst.AnimState:PushAnimation(getanimname(inst), true)
        if inst.Physics then
            inst.Physics:SetActive(true)
        end
    end
end

local function hackedopen(inst)
    -- this is just for viuals, it doesn't actually open the assotiated door.
    inst.stage = 0
    inst.components.workable.workable = false
    inst:AddTag("NOCLICK")
    inst.AnimState:PlayAnimation(getanimname(inst), true)
    if inst.Physics then
        inst.Physics:SetActive(false)
    end
end

local function onhackedfn(inst, hacker, hacksleft)
    if hacksleft <= 0 then
        if inst.stage > 0 then
            inst.stage = inst.stage - 1

            if inst.stage == 0 then
                cleardoor(inst)
                if inst.Physics then
                    inst.Physics:SetActive(false)
                end
                if inst.door then
                    local alvo = inst.door.components.teleporter.targetTeleporter
                    if alvo and alvo.components.vineable and alvo.components.vineable.vines then
                        alvo.components.vineable.vines.stage = 0
                        alvo.components.vineable:SetDoorDissabled(false)
                        if alvo.components.vineable.vines.Physics then
                            alvo.components.vineable.vines.Physics:SetActive(false)
                        end
                    end
                end
            else
                inst.AnimState:PlayAnimation(getanimname(inst) .. "_hit")
                inst.AnimState:PushAnimation(getanimname(inst), true)
                inst.components.workable.workleft = inst.components.workable.maxwork
            end
        end
    else
        inst.AnimState:PlayAnimation(getanimname(inst) .. "_hit")
        inst.AnimState:PushAnimation(getanimname(inst), true)
    end

    local fx = SpawnPrefab("hacking_fx")
    if fx and fx.Transform then
        local x, y, z = inst.Transform:GetWorldPosition()
        fx.Transform:SetPosition(x, y + math.random() * 2, z)
    end
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/vine_hack")
end

local function setup(inst)
    blockdoor(inst)

    if inst.door:HasTag("door_north") then
        inst.facing = "north"
    elseif inst.door:HasTag("door_south") then
        inst.facing = "south"
    elseif inst.door:HasTag("door_east") then
        inst.facing = "east"
    elseif inst.door:HasTag("door_west") then
        inst.facing = "west"
    end

    if inst.facing ~= "south" then
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
    end

    inst.AnimState:PlayAnimation(getanimname(inst), true)
end

local function onsave(inst, data)
    data.stage = inst.stage
    data.facing = inst.facing
end

local function onload(inst, data)
    if data then
        if data.facing then
            inst.facing = data.facing
        end
        if data.stage then
            inst.stage = data.stage
            if inst.stage == 0 then
                hackedopen(inst)
            else
                inst.AnimState:PlayAnimation(getanimname(inst), true)
                if inst.Physics then
                    inst.Physics:SetActive(true)
                end
            end
        end
    end
end

local function makefn()
    local function fn(Sim)
        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
        local light = inst.entity:AddLight()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .75)

        inst.facing = "north"
        inst.stage = 2

        anim:SetBank("pig_ruins_vines_door")
        anim:SetBuild("pig_ruins_vines_build")
        inst.AnimState:PlayAnimation(getanimname(inst), true)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HACK)
        inst.components.workable.onwork = onhackedfn
        inst.components.workable.workleft = RUINS_DOOR_VINES_HACKS
        inst.components.workable.maxwork = RUINS_DOOR_VINES_HACKS

        inst:AddComponent("shearable")
        inst.components.shearable:SetProduct("cutgrass", 2)
        inst.canshear = function(inst) return inst.stage > 0 end
        inst.onshear = function(inst, shearer)
            inst:hackedopen()
            cleardoor(inst)
            if inst.door and inst.door.components.teleporter then
                local alvo = inst.door.components.teleporter.targetTeleporter
                if alvo and alvo.components.vineable and alvo.components.vineable.vines then
                    alvo.components.vineable.vines:hackedopen()
                    alvo.components.vineable:SetDoorDissabled(false)
                end
            end
            local fx = SpawnPrefab("hacking_fx")
            if fx and fx.Transform then
                local x, y, z = inst.Transform:GetWorldPosition()
                fx.Transform:SetPosition(x, y + math.random() * 2, z)
            end
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/vine_hack")
        end

        inst:AddComponent("inspectable")

        inst.setup = setup
        inst.regrow = regrow
        inst.hackedopen = hackedopen
        inst.OnSave = onsave
        inst.OnLoad = onload

        return inst
    end
    return fn
end

local function makewallfn(facing)
    local function fn(Sim)
        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
        local light = inst.entity:AddLight()
        inst.entity:AddNetwork()
        inst.entity:AddSoundEmitter()

        inst.Transform:SetRotation(-90)
        --        inst.AnimState:SetOrientation(ANIM_ORIENTATION.RotatingBillboard)
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(3)

        inst.facing = facing

        anim:SetBank("pig_ruins_vines_wall")
        anim:SetBuild("pig_ruins_vines_build")
        inst.AnimState:PlayAnimation(inst.facing .. math.random(1, 15), true)

        return inst
    end
    return fn
end

return Prefab("common/objects/pig_ruins_creeping_vines", makefn(), assets, prefabs),
    Prefab("common/objects/pig_ruins_wall_vines_north", makewallfn("north_"), assets_wall, prefabs),
    Prefab("common/objects/pig_ruins_wall_vines_east", makewallfn("east_"), assets_wall, prefabs),
    Prefab("common/objects/pig_ruins_wall_vines_west", makewallfn("west_"), assets_wall, prefabs)
