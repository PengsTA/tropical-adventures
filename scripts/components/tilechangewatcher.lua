local TileChangeWatcher = Class(function(self, inst)
    self.inst = inst

    self.last_tile_center = nil
    self.tile_cache = DataGrid(1, 1)

    self.update_listeners = {}
end)

-- 墙壁更新时调用，检查玩家是否移动到了新地砖，如果是则通知监听者
function TileChangeWatcher:OnWallUpdate(dt)
    local current_tile_center = Vector3(TheWorld.Map:GetTileCenterPoint(self.inst.Transform:GetWorldPosition()))
    if current_tile_center == self.last_tile_center then
        return
    end
    self.last_tile_center = current_tile_center
    self:NotifyUpdate()
end

-- 注册监听者，当地砖发生变化时会收到通知
function TileChangeWatcher:ListenToUpdate(listener)
    table.insert(self.update_listeners, listener)
    self.inst:StartWallUpdatingComponent(self)
end

-- 取消注册监听者，停止接收地砖变化通知
function TileChangeWatcher:UnlistenToUpdate(listener)
    table.removearrayvalue(self.update_listeners, listener)
    if #self.update_listeners == 0 then
        self.inst:StopWallUpdatingComponent(self)
    end
end

-- 通知所有注册的监听者地砖已发生变化
function TileChangeWatcher:NotifyUpdate()
    local width, height = TheWorld.Map:GetSize()
    self.tile_cache = DataGrid(width, height)
    for _, listener in ipairs(self.update_listeners) do
        listener()
    end
    self.tile_cache = DataGrid(width, height)
end

-- 在监听者的回调函数中使用，可以替换TheWorld.Map:GetTileAtPoint调用，提供缓存功能
function TileChangeWatcher:CachedTileAtPoint(x, y, z)
    local grid_x = x / TILE_SCALE
    local grid_z = z / TILE_SCALE
    local cache = self.tile_cache:GetDataAtPoint(grid_x, grid_z)
    if cache then
        return cache
    end
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    self.tile_cache:SetDataAtPoint(grid_x, grid_z, tile)
    return tile
end

return TileChangeWatcher