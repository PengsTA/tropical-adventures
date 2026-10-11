local M = {}

function M.IsSkyChair(inst)
    return inst ~= nil and inst:IsValid() and
        (inst.prefab == "skyworthy" or inst.prefab == "skyworthy_broken")
end

function M.IsAvailable(inst)
    return inst ~= nil and inst:IsValid() and not inst:HasTag("burnt") and not inst:HasTag("fire")
end

function M.NotifyChanged()
    if TheWorld ~= nil and TheWorld.ismastersim then
        TheWorld:PushEvent("ta_seaworthy_list_changed")
        if rawget(_G, "TA_SEAWORTHY_NOTIFY_ALL_SHARDS") ~= nil then
            TA_SEAWORTHY_NOTIFY_ALL_SHARDS()
        end
    end
end

function M.GetName(inst)
    local text = inst.components.writeable and inst.components.writeable:GetText()
    return (text ~= "" and text) or inst:GetDisplayName()
        or STRINGS.NAMES[M.IsSkyChair(inst) and "SKYWORTHY" or "SEAWORTHY"]
end

function M.PlayActivation(inst)
    local sky = M.IsSkyChair(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation(inst.is_broken and (sky and "idle_off" or "idle_broken") or "idle_on", true)
    inst.SoundEmitter:PlaySound(sky and "dontstarve_DLC003/common/crafted/skyworthy/place"
        or "dontstarve_DLC002/common/portal/place")
end

function M.GetWorldDisplayName()
    local shard_id = (TheShard ~= nil and TheShard.GetShardId ~= nil)
        and tostring(TheShard:GetShardId()) or "1"
    local world_name
    if TheWorld ~= nil then
        if TheWorld:HasTag("cave") then
            world_name = "洞穴"
        elseif TheWorld:HasTag("shipwrecked") or TheWorld:HasTag("tropical") then
            world_name = "海难"
        elseif TheWorld:HasTag("porkland") or TheWorld:HasTag("hamlet") then
            world_name = "哈姆雷特"
        elseif TheWorld:HasTag("forest") then
            world_name = "地表"
        else
            world_name = "主世界"
        end
    else
        world_name = "世界"
    end
    return world_name .. " [" .. shard_id .. "]", shard_id
end

return M
