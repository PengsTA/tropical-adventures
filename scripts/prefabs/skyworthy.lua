local assets = {
    Asset("ANIM", "anim/portal_hamlet.zip"),
    Asset("ANIM", "anim/portal_hamlet_build.zip"),
    Asset("ANIM", "anim/wormhole_hamlet.zip"),
    Asset("ANIM", "anim/ui_board_5x3.zip"),
}

local prefabs = {
    "collapse_small",
    "ta_skyworthy_vortex_fx",
    "nightmarefuel",
    "livinglog",
    "trinket_giftshop_4",
    "transistor",
    "gears",
}

local PlayerCraftedFn, BrokenFn = require("tools/ta_seaworthy_prefab")({
    name = "skyworthy", bank = "hamportal", build = "portal_hamlet_build",
    icon = "portal_ham.tex", broken_anim = "idle_off", colour = Vector3(1, 0.9, 0.6),
    status = "电线: %d/%d, 齿轮: %d/%d",
    repaired = "天空之椅已修复完成！已激活跨界航向定位。",
    wrong_item = "这个物品无法用来修复天空之椅。",
    progress = "已填入部件。当前进度:\n",
    broken_description = "破损的天空之椅，只能作为单向降落点。\n修复需要: ",
    description = "运转正常的天空之椅，可右键定位并传送至已知世界节点。",
})

return Prefab("skyworthy", PlayerCraftedFn, assets, prefabs),
    Prefab("skyworthy_broken", BrokenFn, assets, prefabs),
    MakePlacer("skyworthy_placer", "hamportal", "portal_hamlet_build", "idle_on")
