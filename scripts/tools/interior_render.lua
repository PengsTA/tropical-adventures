local M = {}

function M.SetWallDecorationLayer(inst)
    if inst:HasTag("wallsection") and not inst:HasTag("cornerpost") then
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(1)
    end
end

function M.EnsureBounds(x, z)
    local extent = math.ceil(2 * (math.max(math.abs(x), math.abs(z)) + 128))
    if TheWorld._ta_interior_render_extent == nil or extent > TheWorld._ta_interior_render_extent then
        TheSim:UpdateRenderExtents(extent)
        TheWorld._ta_interior_render_extent = extent
    end
end

return M
