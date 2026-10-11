local assets = {
    Asset("ANIM", "anim/portal_shipwrecked.zip"),
    Asset("ANIM", "anim/portal_shipwrecked_build.zip"),
    Asset("ANIM", "anim/wormhole_shipwrecked.zip"),
    Asset("ANIM", "anim/wormhole_hamlet.zip"),
    Asset("ANIM", "anim/ui_board_5x3.zip"),
}

local prefabs = {
    "collapse_small",
    "ta_seaworthy_vortex_fx",
    "nightmarefuel",
    "livinglog",
    "sunken_boat_trinket_4",
    "transistor",
    "gears",
}

local PlayerCraftedFn, BrokenFn = require("tools/ta_seaworthy_prefab")({
    name = "seaworthy", bank = "boatportal", build = "portal_shipwrecked_build",
    icon = "shipwrecked_exit.tex", broken_anim = "idle_broken", colour = Vector3(0.6, 0.9, 1),
    status = "电线: %d/%d, 齿轮: %d/%d",
    repaired = "海洋之椅已修复完成！已激活跨界航向定位。",
    wrong_item = "这个物品无法用来修复海洋之椅。",
    progress = "已填入部件。当前进度:\n",
    broken_description = "破损的海洋之椅，只能作为单向降落点。\n修复需要: ",
    description = "运转正常的海洋之椅，可右键定位并航行至已知世界节点。",
})

local function MakeVortexFx(name, build)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("teleporter_worm")
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("in")
        inst.AnimState:PushAnimation("out", false)

        inst:AddTag("FX")
        inst:AddTag("NOCLICK")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:DoTaskInTime(0 * FRAMES, function()
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/portal/open")
        end)
        inst:DoTaskInTime(8 * FRAMES, function()
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/portal/jump_in")
        end)

        inst.persists = false
        inst:ListenForEvent("animqueueover", inst.Remove)

        return inst
    end
    return Prefab(name, fn, assets)
end

return Prefab("seaworthy", PlayerCraftedFn, assets, prefabs),
    Prefab("seaworthy_broken", BrokenFn, assets, prefabs),
    MakePlacer("seaworthy_placer", "boatportal", "portal_shipwrecked_build", "idle_on"),
    Prefab("ligamundosw", BrokenFn, assets, prefabs),
    MakeVortexFx("ta_seaworthy_vortex_fx", "wormhole_shipwrecked"),
    MakeVortexFx("ta_skyworthy_vortex_fx", "wormhole_hamlet")
