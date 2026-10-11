local containers = require("containers")
local barco_atlas = "images/ui/barco.xml"
local params = containers.params

params.armorvortexcloak = {
    widget = {
        slotpos = {},
        animbank = "ui_krampusbag_2x5",
        animbuild = "ui_krampusbag_2x5",
        bgimage = nil,
        bgatlas = nil,
        pos = Vector3(-5, -60, 0)
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1
}
for y = 0, 4 do
    for x = 0, 1 do
        table.insert(params.armorvortexcloak.widget.slotpos, Vector3(75 * x - 162, 75 * y - 186, 0))
    end
end
params.armorvortexcloak.itemtestfn = function(container, item, slot)
    return item.prefab ~= "wortox_soul"
end

params.armorvoidcloak = params.piggyback

local function antchestitemtestfn(container, item, slot)
    return ANTCHEST_PRESERVATION[item.prefab]
end
params.antchest = deepcopy(params.icebox)
params.antchest.itemtestfn = antchestitemtestfn

local hcpos = {
    x = 0,
    y = 0,
    r = 87,
    angle = 4
} -- 中心坐标 [x, y] | 半径 r | 起始角 angle(pi / 3 rad)
local antchest_slotbg = {
    image = "honeychest_slot.tex",
    atlas = resolvefilepath("images/ui/honeychest.xml")
}
params.honeychest = {
    widget = {
        slotpos = { Vector3(hcpos.x, hcpos.y + hcpos.r, 0) },
        slotbg = { antchest_slotbg },
        animbank = "ui_chest_3x3",
        animbuild = "ui_honeychest_7x",
        pos = Vector3(hcpos.x, hcpos.y + 200, 0),
        side_align_tip = 300 - hcpos.r
        -- bottom_align_tip = 0,
    },
    type = "chest",
    openlimit = 1,
    itemtestfn = antchestitemtestfn
}
for line = 1, 0, -1 do
    for rad = hcpos.angle, hcpos.angle - 2, -1 do
        table.insert(params.honeychest.widget.slotpos, Vector3(hcpos.x + hcpos.r * math.sin(rad * PI / 3),
            hcpos.y + hcpos.r * line + hcpos.r * math.cos(rad * PI / 3), 0))
        table.insert(params.honeychest.widget.slotbg, antchest_slotbg)
    end
end

params.corkchest = {
    widget = {
        slotpos = {},
        animbank = "ui_cookpot_1x4",
        animbuild = "ui_cookpot_1x4",
        pos = Vector3(80, 80, 0)
    },
    type = "cookpot"
}
for i = 3, 0, -1 do
    table.insert(params.corkchest.widget.slotpos, Vector3(0, 75 * i - 135, 0))
end

params.smelter = deepcopy(params.cookpot)
params.smelter.widget.buttoninfo.text = STRINGS.ACTIONS.SMELT
local smelting = require("tools/smelting")
function params.smelter.itemtestfn(container, item, slot)
    return smelting.isAttribute(item.prefab)
end

function params.smelter.widget.buttoninfo.fn(inst, doer)
    if inst.components.container ~= nil then
        BufferedAction(doer, inst, ACTIONS.SMELT):Do()
    elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
        SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.SMELT.code, inst, ACTIONS.SMELT.mod_name)
    end
end

params.thatchpack = deepcopy(params.corkchest)
params.thatchpack.widget.pos = Vector3(-60, -60, 0)
params.thatchpack.issidewidget = true
params.thatchpack.type = "pack"
params.thatchpack.openlimit = 1

local function boatitemtestfn(container, item, slot)
    if not slot then
        container._isswift = true
        container.inst:DoTaskInTime(0, function() container._isswift = nil end)
        return true
    end -- for "spslots for spitems"
    local slotitem = container:GetItemInSlot(slot)
    local s = true
    if container._isswift then s = slotitem == nil end
    if slot == 1 then
        return s and (item:HasTag("sail") or item.prefab == "trawlnet")
    elseif slot == 2 then
        return s and (item:HasTag("boatlight") or item:HasTag("quackeringram") or item:HasTag("cannon"))
    else -- if slot and slot > 2 then
        if item.components.stackable then
            for i = slot + 1, container:GetNumSlots() do
                local findslotitem = container:GetItemInSlot(i)
                if findslotitem and findslotitem.prefab == item.prefab and
                    not findslotitem.components.stackable:IsFull() then
                    return false
                end
            end
        end
        if not slotitem then return true end
        if slotitem.prefab ~= item.prefab then return false end -- slotitem ~= nil
        return slotitem.components.stackable and not slotitem.components.stackable:IsFull()
    end
end

local boatequip_bg = {
    {
        image = "barco.tex",
        atlas = barco_atlas,
    },
    {
        image = "luz.tex",
        atlas = barco_atlas,
    }
}

local function BoatParamCommon(build, inspectbuild, numslots)
    inspectbuild = inspectbuild or string.gsub(build, "hud", "inspect")
    local param = {
        widget = {
            slotpos = { Vector3(-80, 45, 0), Vector3(-155, 45, 0) },
            slotbg = boatequip_bg,
            animbank = build,
            animbuild = build,
            pos = BOATHUDPOSPRESET,
            badgepos = Vector3(0, 45, 0),
            isboat = true,
        },
        widgetinspect = {
            slotpos = { Vector3(40, 70, 0), Vector3(-35, 70, 0) },
            slotbg = boatequip_bg,
            animbank = inspectbuild,
            animbuild = inspectbuild,
            pos = Vector3(250, 0, 0),
            badgepos = Vector3(0, 167, 0),
            isboatinspect = true,
        },
        hasboatequipslots = true,
        boatcontainerequips = {
            [BOATEQUIPSLOTS.BOAT_SAIL] = 1,
            [BOATEQUIPSLOTS.BOAT_LAMP] = 2,
        },
        usespecificslotsforitems = true,
        type = "chest",
        itemtestfn = boatitemtestfn,
    }
    local line = ((numslots or 2) - 2) / 2
    for l = 1, line do
        for c = 0, 1 do
            table.insert(param.widgetinspect.slotpos, Vector3(-35 + c * 75, 70 - l * 75, 0))
        end
    end
    return param
end

params.cargoboat = BoatParamCommon("boat_hud_cargo", nil, 8)
for i = 0, 5 do
    table.insert(params.cargoboat.widget.slotpos, Vector3(-650 + 80 * i, 45, 0))
end

params.rowboat = BoatParamCommon("boat_hud_row", nil, 2)
params.rowboat.widgetinspect.bgpos = Vector3(0, 120, 0)

params.armouredboat = params.rowboat



params.encrustedboat = BoatParamCommon("boat_hud_encrusted", nil, 4)
table.insert(params.encrustedboat.widget.slotpos, Vector3(-330, 45, 0))
table.insert(params.encrustedboat.widget.slotpos, Vector3(-250, 45, 0))

params.woodlegsboat = params.encrustedboat

params.raft_old = {
    widget = {
        slotpos = {},
        animbank = "boat_hud_raft",
        animbuild = "boat_hud_raft",
        pos = BOATHUDPOSPRESET,
        isboat = true
    },
    widgetinspect = {
        slotpos = {},
        animbank = "boat_inspect_raft",
        animbuild = "boat_inspect_raft",
        pos = Vector3(250, 0, 0),
        badgepos = Vector3(0, 15, 0),
        isboatinspect = true,
    },
    type = "chest",
}

params.lograft_old = params.raft_old

params.surfboard = params.raft_old
params.corkboat = params.raft_old

params.trawlnetdropped = params.treasurechest

params.shadowwaxwell_boat = params.rowboat

for _, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end

return containers
