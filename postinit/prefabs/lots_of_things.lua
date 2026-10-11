local AddPrefabPostInit = AddPrefabPostInit

for _, prefab in pairs({ "skeleton", "skeleton_player" }) do
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        local function ondropped(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if x and y and z then
                if (TheWorld.Map:IsOceanTileAtPoint(x, 0, z)) then
                    inst:DoTaskInTime(0.5, function(inst)
                        local bolha = SpawnPrefab("frogsplash")
                        if bolha then
                            bolha.Transform:SetPosition(x, y, z)
                        end
                        inst:Remove()
                    end)
                end
            end
        end
        inst:DoTaskInTime(0, ondropped)
    end)
end

for _, prefab in pairs({ "ash" }) do
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        inst:AddComponent("fertilizer")
    end)
end


for _, prefab in pairs({ "anchor" }) do
    AddPrefabPostInit(prefab, function(inst)
        -- if not TheWorld.ismastersim then
        --     return
        -- end

        inst:AddTag("ancora")
    end)
end



for _, prefab in pairs({ "gogglesheathat", "bathat", "molehat" }) do
    AddPrefabPostInit(prefab, function(inst)
        -- if not TheWorld.ismastersim then
        --     return
        -- end

        inst:AddTag("clearfog")
    end)
end

------------------------para a onda quebrar--------------

for _, prefab in pairs({ "cave_entrance_open", "cave_entrance_vulcao" }) do
    AddPrefabPostInit(prefab, function(inst)
        -- if not TheWorld.ismastersim then
        --     return
        -- end

        inst:AddTag("teleportapracaverna")
    end)
end

for _, prefab in pairs({ "cave_exit", "cave_exit_vulcao" }) do
    AddPrefabPostInit(prefab, function(inst)
        -- if not TheWorld.ismastersim then
        --     return
        -- end

        inst:AddTag("teleportaprafloresta")
    end)
end

for _, prefab in pairs({ "cave_exit", "cave_exit_vulcao" }) do
    AddPrefabPostInit(prefab, function(inst)
        -- if not TheWorld.ismastersim then
        --     return
        -- end

        inst:AddTag("teleportaprafloresta")
    end)
end

for _, prefab in pairs(
    { "seastack",
        "coralreef",
        "wreck",
        "waterygrave",
        "octopusking",
        "kraken",
        "ballphinhouse",
        "coral_brain_rock",
        "saltstackthen",
        "wall_enforcedlimestone",
        "kraken_tentacle",
        "sea_chiminea",
        "sea_yard",
        "buoy" }) do
    AddPrefabPostInit(prefab, function(inst)
        -- if not TheWorld.ismastersim then
        --     return
        -- end

        inst:AddTag("quebraonda")
    end)
end



for _, prefab in pairs({ "saplingnova", "sapling" }) do
    AddPrefabPostInit(prefab, function(inst)
        -- if not TheWorld.ismastersim then
        --     return
        -- end

        inst.entity:AddSoundEmitter() --ventania风相关
        inst:AddTag("saplingsw")
    end)
end


for _, prefab in pairs({ "sewing_tape" }) do
    AddPrefabPostInit(prefab, function(inst)
        inst:AddTag("boatrepairkit")
        inst:AddTag("interactions")
        if not TheWorld.ismastersim then
            return
        end

        inst:AddComponent("interactions")
    end)
end





for _, prefab in pairs(
    { "houndstooth",
        "gunpowder",
        "boards",
        "mosquitosack",
        "nightmarefuel",
        "stinger",
        "spear",
        "spear_wathgrithr" }) do
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        inst:AddComponent("tradable")
    end)
end


local rocks = {
    "rock1", "rock2", "rock_flintless", "rock_flintless_med", "rock_flintless_low", "rock_moon", "rock_moon_shell",
    "moonglass_rock", "rock_petrified_tree", "rock_petrified_tree_med", "rock_petrified_tree_tall",
    "rock_petrified_tree_short", "rock_petrified_tree_old", "pig_ruins_head", "pig_ruins_pig", "pig_ruins_ant",
    "pig_ruins_idol", "pig_ruins_plaque", "pig_ruins_artichoke", "pig_ruins_truffle", "pig_ruins_sow", "antqueen_throne",
    "rock_basalt", }

for _, prefab in pairs(rocks) do
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then
            return
        end
        if not inst.components.mystery then
            inst:AddComponent("mystery")
        end
    end)
end

AddPrefabPostInit("deco_palace_throne", function(inst)
    inst.OnEntityWake = function(inst)
        local ent = TheSim:FindFirstEntityWithTag("pigqueen")
        if ent then
            inst:DoTaskInTime(0, function(inst)
                ent.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end)
        end
    end
end
)
