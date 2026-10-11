local SERVER_SIDE
local CLIENT_SIDE
if TheNet:GetIsServer() then
    SERVER_SIDE = true
    if not TheNet:IsDedicated() then
        CLIENT_SIDE = true
    end
elseif TheNet:GetIsClient() then
    SERVER_SIDE = false
    CLIENT_SIDE = true
end

-- PrefabFiles = {
--     "sea2land_fork"
-- }

-- Assets = {
--     Asset("IMAGE", "images/sea2land_fork.tex"),
--     Asset("ATLAS", "images/sea2land_fork.xml"),
--     Asset("ANIM", "anim/swap_land_fork.zip"),
-- }

table.insert(PrefabFiles, "sea2land_fork_tro")

GLOBAL.STRINGS.RECIPE_DESC.SEA2LAND_FORK = '填海造陆！'
GLOBAL.STRINGS.NAMES.SEA2LAND_FORK = "填海叉"
GLOBAL.STRINGS.ACTIONS.CASTSPELL.SEA2LAND = "应用填海造陆"
--AddRecipe("sea2land_fork", { Ingredient("twigs", 2), Ingredient("flint", 2) }, RECIPETABS.TOOLS, TECH.SCIENCE_ONE, nil, nil, nil, nil, nil, "images/inventoryimages2.xml", "pitchfork.tex")

-- local rec = AddRecipe2("sea2land_fork", { Ingredient("twigs", 2), Ingredient("flint", 2) }, TECH.SCIENCE_ONE, {
--     atlas = "images/sea2land_fork.xml",
--     image = "sea2land_fork.tex"
-- }, { 'TOOLS' })
-- rec.sortkey = 0.046799

AddAction("SEA2LAND", "填海造陆", function(act)
    if act.invobject ~= nil and act.invobject.components.sea2land ~= nil then
        return act.invobject.components.sea2land:Sea2land(act:GetActionPoint())
    end
end)

ACTIONS.SEA2LAND.tile_placer = "gridplacer"
AddComponentAction("POINT", "sea2land", function(inst, doer, pos, actions, right)
    if right then
        table.insert(actions, ACTIONS.SEA2LAND)
    end
end)
local state_sea2land = GLOBAL.State {
    name = "sea2land",
    tags = { "busy" },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("shovel_pre")
        inst.AnimState:PushAnimation("shovel_loop", false)
    end,

    timeline = {
        TimeEvent(25 * FRAMES, function(inst)
            inst:PerformBufferedAction()
            inst.sg:RemoveStateTag("busy")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
        end),
    },

    events = {
        EventHandler("unequip", function(inst)
            inst.sg:GoToState("idle")
        end),
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.AnimState:PlayAnimation("shovel_pst")
                inst.sg:GoToState("idle", true)
            end
        end),
    },
}
AddStategraphState("wilson", state_sea2land)
AddStategraphState("wilson_client", state_sea2land)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.SEA2LAND, "sea2land"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.SEA2LAND, "sea2land"))

for _, v in ipairs(DST_CHARACTERLIST) do
    AddPrefabPostInit(v, function(inst)
        inst:AddTag("sea2land_admin")
    end)
end

AddComponentPostInit("playerspawner", function(OnPlayerSpawn, inst)
    inst:ListenForEvent("ms_playerjoined", function(self, player)
        if not (player and player.components) then
            return
        end
        local isAdmin = false
        for _, client in ipairs(TheNet:GetClientTable() or {}) do
            if player.userid == client.userid and client.admin then
                isAdmin = true
                break
            end
        end
        if not isAdmin then
            player:RemoveTag("sea2land_admin")
        end

        if (isAdmin or GetModConfigData('admin_only') == false) and not player:HasTag("sea2land_admin") then
            player:AddTag("sea2land_admin")
        end
    end)
end)

AddClientModRPCHandler("sea2land", "fork_equip_change", function(inst, turf, equip)
    if not ThePlayer then
        return
    end
    if equip then
        ThePlayer.HUD.controls.status.sea2land_spinner:Show()
        ThePlayer.HUD.controls.status.sea2land_spinner.fork_inst = inst
        ThePlayer.HUD.controls.status.sea2land_spinner.sea2land_spinner.spinner:SetSelected(turf)
    else
        ThePlayer.HUD.controls.status.sea2land_spinner:Hide()
        ThePlayer.HUD.controls.status.sea2land_spinner.fork_inst = nil
    end
end)

AddModRPCHandler("sea2land", "change_turf", function(player, inst, turf)
    if inst and inst.components and inst.components.inventoryitem and inst.components.inventoryitem.owner == player then
        inst.turf = turf
    end
end)

if CLIENT_SIDE then
    GLOBAL.Sea2Land = {
        DATA = {
            Sea2landSpinnerPos = { 0, -50, 0 },
        }
    }
    local DATA_FILE = "mod_config_data/sea2land_data_save"

    GLOBAL.Sea2Land.LoadData = function()
        TheSim:GetPersistentString(DATA_FILE, function(load_success, str)
            if load_success and #str > 0 then
                local run_success, data = RunInSandboxSafe(str)
                if run_success then
                    for k, v in pairs(data) do
                        if v ~= nil then
                            GLOBAL.Sea2Land.DATA[k] = v
                        end
                    end
                end
            end
        end)
    end

    GLOBAL.Sea2Land.SaveData = function()
        SavePersistentString(DATA_FILE, DataDumper(GLOBAL.Sea2Land.DATA, nil, true), false, nil)
    end

    AddSimPostInit(function()
        GLOBAL.Sea2Land.LoadData()
    end)

    local TEMPLATES = require "widgets/redux/templates"
    local Widget = require "widgets/widget"
    local delta = 25

    local Sea2landSpinner = Class(Widget, function(self)
        Widget._ctor(self, "Sea2landSpinner")
        self:SetScaleMode(SCALEMODE_PROPORTIONAL)
        self:SetVAnchor(ANCHOR_TOP)
        self:SetHAnchor(ANCHOR_MIDDLE)
        self.root = self:AddChild(Widget("ROOT"))
        if Sea2Land.DATA.Sea2landSpinnerPos then
            self.root:SetPosition(unpack(Sea2Land.DATA.Sea2landSpinnerPos))
        else
            self.root:SetPosition(0, -50, 0)
        end

        local turf_options = {



            { text = '珊瑚海', data = GROUND.OCEAN_CORAL },
            { text = '红树林', data = GROUND.MANGROVE },
            { text = '热带海岸', data = GROUND.OCEAN_SHALLOW_SHORE },

            { text = '热带中海', data = GROUND.OCEAN_MEDIUM },
            { text = '热带深海', data = GROUND.OCEAN_DEEP },
            { text = '船墓', data = GROUND.OCEAN_SHIPGRAVEYARD },

            { text = '虚空', data = GROUND.IMPASSABLE },
            { text = '海岸', data = GROUND.OCEAN_COASTAL_SHORE },
            { text = '浅海', data = GROUND.OCEAN_COASTAL },

            { text = '莲花池', data = GROUND.LILYPOND },

            { text = '热带浅海', data = GROUND.OCEAN_SHALLOW },

            { text = '中海', data = GROUND.OCEAN_SWELL },
            { text = '深海', data = GROUND.OCEAN_ROUGH },
            { text = '盐矿海', data = GROUND.OCEAN_BRINEPOOL },
            { text = '盐矿海岸', data = GROUND.OCEAN_BRINEPOOL_SHORE },
            { text = '危险海域', data = GROUND.OCEAN_HAZARDOUS },
            { text = '水中木海', data = GROUND.OCEAN_WATERLOG },

        }
        self.sea2land_spinner = self.root:AddChild(TEMPLATES.LabelSpinner(
            '地皮', turf_options, 50, 180, 50, 0, BODYTEXTFONT, 40, 0, function(selected)
                SendModRPCToServer(MOD_RPC['sea2land']["change_turf"], self.fork_inst, selected)
            end
        ))
        self.sea2land_spinner:SetTooltip('按住F1拖动')

        self:StartUpdating()
    end)

    function Sea2landSpinner:OnControl(control, down)
        if TheInput:IsKeyDown(KEY_F1) then
            self:Passive_OnControl(control, down)
            return true
        end
        return self.sea2land_spinner:OnControl(control, down)
    end

    function Sea2landSpinner:Passive_OnControl(control, down)
        if control == CONTROL_ACCEPT then
            if down then
                self:StartDrag()
            else
                self:EndDrag()
            end
        end
    end

    function Sea2landSpinner:SetDragPosition(x, y, z)
        local pos
        if type(x) == "number" then
            pos = Vector3(x, y, z)
        else
            pos = x
        end
        local diff = (pos - self.dragPosDiff_mouse)
        local scale = self:GetScale()
        local scale2 = ThePlayer and ThePlayer.HUD.controls.status:GetScale() or 1
        diff.x = diff.x * scale2.x / scale.x
        diff.y = diff.y * scale2.y / scale.y
        local w, h = TheSim:GetScreenSize()
        w = w * scale2.x / scale.x / 2
        h = h * scale2.y / scale.y
        local new_pos = diff + self.dragPosDiff_widget
        if new_pos.y > -delta then
            new_pos.y = -delta
        elseif new_pos.y < -h + delta then
            new_pos.y = -h + delta
        end
        if new_pos.x < -w + delta then
            new_pos.x = -w + delta
        elseif new_pos.x > w - delta then
            new_pos.x = w - delta
        end
        self.root:SetPosition(new_pos)
    end

    function Sea2landSpinner:StartDrag()
        if not self.follow_handler then
            local mouse_pos = TheInput:GetScreenPosition()
            self.dragPosDiff_widget = self.root:GetPosition()
            self.dragPosDiff_mouse = mouse_pos
            self.follow_handler = TheInput:AddMoveHandler(function(x, y)
                self:SetDragPosition(x, y, 0)
                if not TheInput:IsKeyDown(KEY_F1) then
                    self:EndDrag()
                end
            end)
            self:SetDragPosition(mouse_pos)
        end
    end

    function Sea2landSpinner:EndDrag()
        if self.follow_handler then
            self.follow_handler:Remove()
        end
        local x, y, z = self.root:GetPosition():Get()
        Sea2Land.DATA.Sea2landSpinnerPos = { x, y, z }
        Sea2Land.SaveData()
        self.follow_handler = nil
        self.dragPosDiff = nil
        self:MoveToBack()
    end

    function Sea2landSpinner:OnUpdate()
        local w, h = TheSim:GetScreenSize()
        local scale = self:GetScale()
        local scale2 = ThePlayer.HUD.controls.status:GetScale()
        w = w * scale2.x / scale.x / 2
        h = h * scale2.y / scale.y
        local x, y, _ = self.root:GetPosition():Get()
        local ox, oy = x, y
        if y > -delta then
            y = -delta
        elseif y < -h + delta then
            y = -h + delta
        end
        if x < -w + delta then
            x = -w + delta
        elseif x > w - delta then
            x = w - delta
        end
        if ox ~= x or oy ~= y then
            self.root:SetPosition(x, y, 0)
        end
    end

    AddClassPostConstruct("widgets/statusdisplays", function(self)
        self.sea2land_spinner = self:AddChild(Sea2landSpinner())
        self.sea2land_spinner:MoveToBack()
        self.sea2land_spinner:Hide()
    end)
end
