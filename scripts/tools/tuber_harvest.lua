local M = {}
local SLOTS = { 8, 5, 7 }
local REGROW_TIME = 1440

function M.UpdateArt(inst)
    for index, slot in ipairs(SLOTS) do
        if index <= inst.tubers then
            inst.AnimState:Show("tubers" .. slot)
        else
            inst.AnimState:Hide("tubers" .. slot)
        end
    end
end

function M.Stop(inst)
    if inst.components.timer ~= nil then inst.components.timer:StopTimer("tuber_regrow") end
end

local function StartRegrowth(inst)
    if inst.tubers < #SLOTS and not inst.components.timer:TimerExists("tuber_regrow") then
        inst.components.timer:StartTimer("tuber_regrow", REGROW_TIME)
    end
end

function M.Configure(inst, fell)
    inst.tubers = #SLOTS
    inst:AddComponent("timer")
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(function(tree, worker)
        if tree.tubers == 0 then
            fell(tree, worker)
            return
        end
        tree.components.lootdropper:SpawnLootPrefab(TheWorld.state.issummer and "tuber_bloom_crop" or "tuber_crop")
        tree.tubers = tree.tubers - 1
        tree.components.workable:SetWorkLeft(tree.tubers > 0 and 3 or 1)
        M.UpdateArt(tree)
        StartRegrowth(tree)
    end)
    inst:ListenForEvent("timerdone", function(tree, data)
        if data.name == "tuber_regrow" and not tree:HasTag("stump") and not tree:HasTag("burnt") then
            local empty = tree.tubers == 0
            tree.tubers = math.min(#SLOTS, tree.tubers + 1)
            if empty then tree.components.workable:SetWorkLeft(3) end
            M.UpdateArt(tree)
            StartRegrowth(tree)
        end
    end)
    M.UpdateArt(inst)
end

function M.Load(inst, data)
    if data ~= nil and data.tubers ~= nil then
        inst.tubers = math.max(0, math.min(#SLOTS, data.tubers))
    elseif data ~= nil and data.workable ~= nil and data.workable.workleft ~= nil then
        local remaining = math.max(1, math.min(10, data.workable.workleft))
        inst.tubers = math.ceil((remaining - 1) / 3)
        inst.components.workable:SetWorkLeft(remaining - inst.tubers * 3 + (inst.tubers > 0 and 2 or 0))
    end
    M.UpdateArt(inst)
    StartRegrowth(inst)
end

return M
