-- 引入地图布局模块，用于加载预设的建筑结构
local obj_layout = require("map/object_layout")

-- 定义四个方向的步进值，用于在网格中进行坐标偏移
local DIR_STEP = {
    { x = 1,  z = 0 },
    { x = 0,  z = 1 },
    { x = -1, z = 0 },
    { x = 0,  z = -1 },
}

-- 标记重要唯一建筑是否已经生成，确保每个城市/世界只有一个
local made_palace = false
local made_cityhall = false
local made_playerhouse = false

-- 默认生成的城市数量
local CITIES = 2

-- 普通公园的布局选择池
local PARK_CHOICES = {
    "city_park_1",
    "city_park_2",
    "city_park_3",
    "city_park_4",
    "city_park_5",
    "city_park_8",
}

-- 具有唯一性质或特殊样式的公园布局选择池
local UNIQUE_PARK_CHOICES = {
    "city_park_6",
    "city_park_7",
    "city_park_9",
    "city_park_10",
}

-- 必须生成的农田布局（当前为空，预留给特殊任务道具如传送机零件）
local REQUIRED_FARMS = {
    --"teleportato_hamlet_potato_layout",
}

-- 普通农田的布局选择池
local FARM_CHOICES = {
    "farm_1",
    "farm_2",
    "farm_3",
    "farm_4",
    "farm_5",
}

-- 农田间隙填充物的布局选择池
local FARM_FILLER_CHOICES = {
    "farm_fill_1",
    "farm_fill_2",
    "farm_fill_3",
}

-- 城市1（通常是主城）的建筑配额，定义了各种商店和民居的数量
local BUILDING_QUOTAS = {
    { prefab = "pig_shop_deli",    num = 1 },
    -- { prefab = "pig_shop_academy", num = 1 },
    { prefab = "pig_shop_florist", num = 1 },
    { prefab = "pig_shop_general", num = 1 },
    { prefab = "pig_shop_hoofspa", num = 1 },
    { prefab = "pig_shop_produce", num = 1 },
    { prefab = "pig_shop_bank",    num = 1 },

    { prefab = "pig_shop_academy",      num = 1 },

    { prefab = "pig_guard_tower",           num = 15 },
    { prefab = "pighouse_city",             num = 50 },

}

-- 城市2（通常是副城/高级城）的建筑配额，包含武器店、奥术店等
local BUILDING_QUOTAS_2 = {
    -- { prefab = "pig_shop_antiquities",  num = 2 },
    -- { prefab = "pig_shop_hatshop", num = 1 },
    { prefab = "pig_shop_weapons", num = 1 },
    { prefab = "pig_shop_arcane",  num = 1 },
    { prefab = "pig_shop_tinker",  num = 1 },

    { prefab = "pig_shop_antiquities",  num = 2 },
    { prefab = "pig_shop_hatshop",          num = 1 },

    { prefab = "pig_guard_tower",           num = 15 },
    { prefab = "pighouse_city",             num = 50 },

}

-- 定义允许放置城市建筑的合法地皮类型
local VALID_TILES = { WORLD_TILES.SUBURB, WORLD_TILES.FOUNDATION, WORLD_TILES.FIELDS }

-- 基础地形校验地皮类型，包含道路
local VALID_TILES_BASE = { WORLD_TILES.SUBURB, WORLD_TILES.FOUNDATION, WORLD_TILES.ROAD, WORLD_TILES.FIELDS }

-- 城市中心区域的校验地皮类型
local VALID_TILES_CITY = { WORLD_TILES.CHECKEREDLAWN, WORLD_TILES.FOUNDATION, WORLD_TILES.ROAD }

-- 所有属于城市范畴的地皮类型汇总，用于边缘检测
local VALID_TILES_CITY_ALL = { WORLD_TILES.SUBURB, WORLD_TILES.CHECKEREDLAWN, WORLD_TILES.FOUNDATION,
    WORLD_TILES.ROAD, WORLD_TILES.COBBLEROAD }

-- 方向辅助函数：根据当前方向和增量（左转/右转）返回新的方向索引
local function get_dir(dir, inc)
    if dir == 1 then
        return inc > 0 and 2 or 4
    elseif dir == 2 then
        return inc > 0 and 3 or 1
    elseif dir == 3 then
        return inc > 0 and 4 or 2
    elseif dir == 4 then
        return inc > 0 and 1 or 3
    end
end

-- 在临时实体列表中查找指定范围内、指定名称的实体
local function find_temp_ents(data, x, z, range, prefabs)
    local ents = {}

    for i, entity in ipairs(data) do
        local test = prefabs == nil
        if not test then
            for p, prefab in ipairs(prefabs) do
                if entity.prefab == prefab then
                    test = true
                end
            end
        end
        if test then
            local distsq = (math.abs(x - entity.x) * math.abs(x - entity.x)) +
                (math.abs(z - entity.z) * math.abs(z - entity.z))
            if distsq <= range * range then
                table.insert(ents, entity)
            end
        end
    end

    return ents
end

-- 向临时实体列表中添加一个新的待生成实体及其所属城市信息
local function add_temp_ents(data, x, z, prefab, city_id, properties)
    local save_data = {
        x = x,
        z = z,
        prefab = prefab,
        city = city_id,
        properties = properties,
    }

    table.insert(data, save_data)
end

-- 将实体数据转换为游戏引擎可识别的坐标格式（Tile 空间转世界空间）
local function set_entity(entities, width, height, prop, x, z, city_id, properties)
    if entities[prop] == nil then
        entities[prop] = {}
    end

    local scenario = nil
    if city_id then
        scenario = "set_city_possession_" .. city_id
    end

    local save_data = properties or {}
    save_data.x = (x - width / 2) * TILE_SCALE
    save_data.z = (z - height / 2) * TILE_SCALE
    -- save_data.scenario = scenario -- 预留的场景脚本标记

    table.insert(entities[prop], save_data)
end

-- 批量导出所有临时生成的刷怪笼/实体到最终的实体表
local function export_spawners_to_entites(entities, width, height, spawners)
    for i, spawner in ipairs(spawners) do
        set_entity(entities, width, height, spawner.prefab, spawner.x, spawner.z, spawner.city, spawner.properties)
    end
end

-- 检测目标点及其周围 5x5 范围内地皮是否属于合法的城市区域，防止建筑跨越到水里或森林
local function test_tile(pt, types)
    local ground = WorldSim:GetTile(pt.x, pt.z) -- 获取目标点地皮
    if types then
        for _, tiletype in ipairs(types) do
            if tiletype == ground then
                for i = -2, 2 do
                    for t = -2, 2 do
                        local edge_pt = {
                            x = pt.x + i,
                            z = pt.z + t
                        }
                        local ground = WorldSim:GetTile(edge_pt.x, edge_pt.z)
                        if ground and types then
                            if not table.contains(VALID_TILES_CITY_ALL, ground) then
                                return false -- 如果边缘触及非城市地皮，则判定无效
                            end
                        end
                    end
                end
                return true
            end
        end
    end
    return false
end

-- 修改指定坐标的地皮类型，默认修改为鹅卵石路（COBBLEROAD）
local function place_tile(pt, tile)
    local ground = WorldSim:GetTile(pt.x, pt.z)

    if ground then
        WorldSim:SetTile(pt.x, pt.z, tile)
    end
end


-- 定义清理黑名单，在生成城市建筑前，会自动移除这些原生资源（草、石块、树木等）
local unrequired_prefabs = {
    "grass",
    "rocks",
    "rock1",
    "rock2",
    "rock_flintless",
    "flint",
    "twigs",
    "sapling",
    "berrybush",
    "spoiled_food",
    "teatree",
    "chicken",
    "chickenhouse",
    "sapling_ham",
    "grass_ham"
}

-- 清理指定坐标点半径 8 范围内的原生杂物，为建筑腾出空间
local function clear_ground(entities, width, height, pt)
    local radius = 4
    for prefab, data_list in pairs(entities) do
        local should_clear = false
        for i, rprefab in ipairs(unrequired_prefabs) do
            if prefab == rprefab then
                should_clear = true
                break
            end
        end

        if should_clear then
            for i = #data_list, 1, -1 do
                local x_dist = math.abs(((data_list[i].x / TILE_SCALE) + width / 2.0) - pt.x) + 0.2
                local z_dist = math.abs(((data_list[i].z / TILE_SCALE) + height / 2.0) - pt.z) + 0.2

                if (x_dist * x_dist) + (z_dist * z_dist) <= radius * radius then
                    table.remove(data_list, i)
                end
            end
        end
    end
end

-- 城市地块核心生成函数：清理地面、铺设 17x17 的地基（Foundation）以及 3x3 的路中心
local function place_tile_city(entities, width, height, pt)
    clear_ground(entities, width, height, pt)

    -- 循环生成大面积的地基，带有一点随机碎边效果
    for i = -8, 8 do
        for t = -8, 8 do
            local new_pt = {
                x = pt.x + i,
                z = pt.z + t
            }
            if WorldSim:GetTile(new_pt.x, new_pt.z) > 1 then
                -- 核心 9x9 区域必填，外围随机填充
                if math.random() < 0.15 or (math.abs(t) <= 4 and math.abs(i) <= 4) then
                    if test_tile(new_pt, VALID_TILES) then
                        place_tile(new_pt, WORLD_TILES.FOUNDATION)
                    end
                end
            end
        end
    end

    -- 在地块中心铺设 3x3 的街道
    for i = -1, 1 do
        for t = -1, 1 do
            local edge_pt = {
                x = pt.x + i,
                z = pt.z + t
            }
            if WorldSim:GetTile(edge_pt.x, edge_pt.z) > 1 then
                if test_tile(edge_pt, VALID_TILES) then
                    place_tile(edge_pt, WORLD_TILES.ROAD)
                end
            end
        end
    end

    place_tile(pt, WORLD_TILES.COBBLEROAD)
end

-- 生成预设布局（Setpiece），如猪王宫殿、市政厅。处理旋转、翻转、地皮校验及实体添加
local function spawn_setpiece(entities, width, height, spawners, layout, pt, city)
    local setpiece = obj_layout.LayoutForDefinition(layout)
    -- 校验布局必须为奇数尺寸，以便有一个明确的中心点
    assert(#setpiece.ground % 2 ~= 0, "ERROR, THE SET PIECE HAS AN EVEN NUMBER OF ROWS")
    assert(#setpiece.ground[1] % 2 ~= 0, "ERROR, THE SET PIECE HAS AN EVEN NUMBER OF COLS")

    local reverse = math.random() < 0.5 -- 随机交换 X/Z 轴（旋转 90 度）
    local flip = math.random() < 0.5    -- 随机镜像翻转

    local offset_x = ((#setpiece.ground - 1) / 2 + 1)
    local offset_z = ((#setpiece.ground[1] - 1) / 2 + 1)

    local x_flip = 1
    if flip then
        offset_x = offset_x * -1
        x_flip = -1
    end

    -- 第一遍：检查布局覆盖的所有地皮是否都在陆地上
    local ground_valid = true
    for x = 1, #setpiece.ground do
        for y = 1, #setpiece.ground[x] do
            local new_pt = {}
            if reverse then
                new_pt = { x = (pt.x - offset_x + (x * x_flip)), y = 0, z = (pt.z - offset_z + (y)) }
            else
                new_pt = { x = (pt.x - offset_x + (y * x_flip)), y = 0, z = (pt.z - offset_z + (x)) }
            end
            local original_tile_type = WorldSim:GetTile(math.floor(new_pt.x), math.floor(new_pt.z))
            if not original_tile_type or not IsLandTile(original_tile_type) then
                ground_valid = false
            end
        end
    end

    -- 第二遍：如果地皮合法，则正式铺设地皮并添加实体到 spawners 列表
    if ground_valid then
        -- Failed candidates must leave resources and shop placeholders intact.
        local radius = math.max(#setpiece.ground, #setpiece.ground[1]) / 2 * 1.4
        for prefab, data_list in pairs(entities) do
            if tableutil.has_component(unrequired_prefabs, prefab) then
                for i = #data_list, 1, -1 do
                    local xdist = math.abs(data_list[i].x / TILE_SCALE + width / 2 - pt.x) + 0.2
                    local zdist = math.abs(data_list[i].z / TILE_SCALE + height / 2 - pt.z) + 0.2
                    if xdist * xdist + zdist * zdist <= radius * radius then
                        table.remove(data_list, i)
                    end
                end
            end
        end
        for x = 1, #setpiece.ground do
            for y = 1, #setpiece.ground[x] do
                local new_pt = {}
                if reverse then
                    new_pt = { x = (pt.x - offset_x + (x * x_flip)), y = 0, z = (pt.z - offset_z + (y)) }
                else
                    new_pt = { x = (pt.x - offset_x + (y * x_flip)), y = 0, z = (pt.z - offset_z + (x)) }
                end
                local tile = setpiece.ground_types[setpiece.ground[x][y]]
                if tile and tile > 0 then
                    place_tile(new_pt, tile)
                end
            end
        end

        for prefab, list in pairs(setpiece.layout) do
            for t, data in ipairs(list) do
                local new_pt = {}
                if reverse then
                    new_pt = { x = (pt.x + (list[t].y * x_flip)), y = 0, z = (pt.z + (list[t].x)) }
                else
                    new_pt = { x = (pt.x + (list[t].x * x_flip)), y = 0, z = (pt.z + (list[t].y)) }
                end

                local city_temp = city.city_id
                -- 处理特殊情况：有些掉落物（如金币）或玩家房子不应继承城市所有权脚本
                if layout == "city_park_7" and prefab == "oinc" then city_temp = nil end
                if layout == "pig_playerhouse_1" and prefab ~= "playerhouse_city" then city_temp = nil end

                add_temp_ents(spawners, new_pt.x, new_pt.z, prefab, city_temp, data.properties)
            end
        end
        return true
    else
        print("!!!!!! WORLD_TILES WAS NOT VALID !!!!!!!!!!!!")
        return false
    end
end

-- 在路边指定位置放置“商店占位符”，后续会被替换为真正的商店实体
local function set_shop(spawners, pt, dir, i, offset, nil_wieght, city)
    local spawn = "pig_shop_spawner"
    local OFFSET = 8 / 4 -- 这里的 2.0 偏移量让商店对齐到 8x8 街道侧边
    local new_pt = {
        x = pt.x + (DIR_STEP[dir].x * i * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].x),
        y = 0,
        z = pt.z + (DIR_STEP[dir].z * i * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].z)
    }

    local pigshops_spawners = find_temp_ents(spawners, new_pt.x, new_pt.z, 1, { spawn })

    if #pigshops_spawners == 0 and test_tile(new_pt, VALID_TILES_CITY) then
        add_temp_ents(spawners, new_pt.x, new_pt.z, spawn, city.city_id)
    end
end

-- 在道路的两侧尝试添加商店
local function add_pig_shops(spawners, pt, dir, nil_wieght, city)
    for i = 1, 3 do
        set_shop(spawners, pt, dir, i, 1, nil_wieght, city)
        set_shop(spawners, pt, dir, i, -1, nil_wieght, city)
    end
end

-- 计算并记录“公园区域”的坐标，公园通常占地较大（8x8 街区）
local function set_park_coord(pt, dir, i, offset, city)
    local OFFSET = 8 / 4

    local new_pt = {
        x = pt.x + (DIR_STEP[dir].x * i * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].x * math.abs(offset)),
        y = 0,
        z = pt.z + (DIR_STEP[dir].z * i * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].z * math.abs(offset))
    }

    local pass = true
    -- 确保拟定公园区域内的地皮是完整的，没有穿模到水里
    for x = -2, 2 do
        for y = -2, 2 do
            local ground = WorldSim:GetTile(math.floor(new_pt.x) + (x), math.floor(new_pt.z) + (y))
            if not ground or ground ~= WORLD_TILES.FOUNDATION then
                pass = false
                break
            end
        end
    end

    if pass then
        local pass = true
        for i, park in ipairs(city.parks) do
            if new_pt.x == park.x and new_pt.z == park.z then
                pass = false
                break
            end
        end
        if pass then
            new_pt.city_id = city.city_id
            table.insert(city.parks, new_pt) -- 存入城市的公园候选点列表
        end
    end
end

-- 在街道尽头或特定偏移处标记公园候选区域
local function add_park_zones(pt, dir, city)
    local i = 2
    set_park_coord(pt, dir, i, 2, city)
    set_park_coord(pt, dir, i, -2, city)
end

-- 在路灯杆位放置路灯实体，防止重复放置
local function spawn_city_light(spawners, pt, dir, offset, city_id)
    local spawn = "city_lamp"
    local OFFSET = 1
    local newpt = {
        x = pt.x + (DIR_STEP[dir].x * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].x),
        y = 0,
        z = pt.z + (DIR_STEP[dir].z * OFFSET) + (OFFSET * DIR_STEP[get_dir(dir, offset)].z)
    }

    local lamps = find_temp_ents(spawners, newpt.x, newpt.z, 0.5, { spawn })

    if #lamps == 0 then
        if test_tile(newpt, VALID_TILES_CITY) then
            add_temp_ents(spawners, newpt.x, newpt.z, spawn, city_id)
        end
    end
end

-- 在街道节点两侧添加路灯
local function add_city_lights(spawners, pt, dir, city_id)
    spawn_city_light(spawners, pt, dir, 1, city_id)
    spawn_city_light(spawners, pt, dir, -1, city_id)
end

-- 道路延展逻辑：从当前点向指定方向“走”一段距离，边走边铺设城市地皮，并沿途添加设施
local function make_road(entities, width, height, spawners, pt, dir, sub_urb, city)
    local step_max = 9
    local step = 1
    local new_pt = nil
    local offset = 1

    local nil_pig_shop_weight = 6
    if sub_urb then nil_pig_shop_weight = 12 end

    while step < step_max and step > -1 do
        new_pt = {
            x = pt.x + (DIR_STEP[dir].x * step * offset),
            y = 0,
            z = pt.z + (DIR_STEP[dir].z * step * offset)
        }

        if test_tile(new_pt, VALID_TILES_BASE) then
            place_tile_city(entities, width, height, new_pt)
            step = step + 1
        else
            step = -1 -- 遇到边缘停止延伸
        end
    end

    -- 如果道路延伸成功，则在末端添加配套设施
    if step == step_max then
        add_pig_shops(spawners, pt, dir, nil_pig_shop_weight, city)
        add_park_zones(pt, dir, city)
        add_city_lights(spawners, pt, dir, city.city_id)
    end
end

-- 基础坐标取整辅助函数
local function get_div1_tile(x, y, z)
    x = x - (math.fmod(x, 1))
    z = z - (math.fmod(z, 1))
    return x, y, z
end

-- 8x8 网格对齐函数：确保所有街道节点都锁定在 8 为倍数的网格中心点上
local function get_div8_tile(x, y, z)
    x = x - (math.fmod(x, 8)) + 4
    z = z - (math.fmod(z, 8)) + 4
    return x, y, z
end

-- 检查某个点是否已经存在于坐标列表中，避免重复处理
local function is_pt_in_list(pt, data)
    local idx = nil
    for i, coord in ipairs(data) do
        if coord.x == pt.x and coord.y == pt.y and coord.z == pt.z then
            idx = i
            break
        end
    end
    return idx
end

-- 迷宫式生长辅助函数：从当前点向四面探测，如果在待选网格内则加入开放路径
local function add_dirs(pt, grid, open_dirs)
    for dir, data in ipairs(DIR_STEP) do
        local new_pt = {
            x = pt.x + (data.x * 8),
            y = pt.y,
            z = pt.z + (data.z * 8)
        }

        local idx = is_pt_in_list(new_pt, grid)
        if idx then
            table.insert(open_dirs, { pt = pt, newpt = new_pt, dir = dir })
            table.remove(grid, idx)
        else
            -- 随机概率允许向已处理的方向生成“断头路”
            if math.random() < 0.3 then
                table.insert(open_dirs, { pt = pt, dir = dir })
            end
        end
    end
    return grid, open_dirs
end


-- 城市生成核心逻辑：选择起点，填充网格，通过类似 Prim 算法的逻辑随机生成街道网格
local function find_city_start(city, width, height)
    local count = #city.citynodes
    if count == 0 then return nil end
    local first = math.random(count)
    local function Check(node, x, z)
        local tx, _, tz = get_div8_tile(x, 0, z)
        local pt = { x = tx, y = 0, z = tz }
        if tx >= 2 and tz >= 2 and tx < width - 2 and tz < height - 2
            and WorldSim:PointInSite(node.id, tx, tz) and test_tile(pt, VALID_TILES) then
            return pt
        end
    end
    -- Visit each centroid once, then exhaust the aligned grid inside each polygon.
    for offset = 0, count - 1 do
        local node = city.citynodes[(first + offset - 1) % count + 1]
        local pt = Check(node, node.cent[1], node.cent[2])
        if pt then return pt end
    end
    for offset = 0, count - 1 do
        local node = city.citynodes[(first + offset - 1) % count + 1]
        local minx, minz, maxx, maxz = width, height, 0, 0
        for i, x in ipairs(node.poly.x) do
            local z = node.poly.y[i]
            minx, minz = math.min(minx, x), math.min(minz, z)
            maxx, maxz = math.max(maxx, x), math.max(maxz, z)
        end
        minx = math.ceil((math.max(2, minx) - 4) / 8) * 8 + 4
        minz = math.ceil((math.max(2, minz) - 4) / 8) * 8 + 4
        for x = minx, math.min(maxx, width - 3), 8 do
            for z = minz, math.min(maxz, height - 3), 8 do
                local pt = Check(node, x, z)
                if pt then return pt end
            end
        end
    end
end

local function create_city(entities, width, height, spawners, city)
    local start_pt = find_city_start(city, width, height)
    if start_pt == nil then return false end
    local x, y, z = start_pt.x, start_pt.y, start_pt.z

    local grid = { { x = x, y = y, z = z } }

    -- 扫描 17x17 的范围，将所有属于城市 Tag 且地皮合法的点加入网格列表
    for nx = -8, 8 do
        for nz = -8, 8 do
            local newpt = {
                x = x + (nx * 8),
                y = y,
                z = z + (nz * 8)
            }
            local in_city_node = false
            for i, node in ipairs(city.citynodes) do
                if WorldSim:PointInSite(node.id, newpt.x, newpt.z) then
                    in_city_node = true
                end
            end
            if (nx ~= 0 or nz ~= 0) and test_tile(newpt, VALID_TILES) and in_city_node then
                table.insert(grid, newpt)
            end
        end
    end

    local idx = math.random(1, #grid)
    local start = grid[idx]
    table.remove(grid, idx)

    if test_tile(start, VALID_TILES) then
        place_tile_city(entities, width, height, start)
    end

    -- 迭代生成路口和街道
    local maxintersections = 30
    local opendirs = {}

    grid, opendirs = add_dirs(start, grid, opendirs)

    while maxintersections > 0 and #opendirs > 0 do
        local idx = math.random(1, #opendirs)
        local data = opendirs[idx]
        make_road(entities, width, height, spawners, data.pt, data.dir, true, city)
        if data.newpt then
            grid, opendirs = add_dirs(data.newpt, grid, opendirs)
            maxintersections = maxintersections - 1
        end
        table.remove(opendirs, idx)
    end
    return true
end

-- 在预留的公园候选点生成公园、皇宫、市政厅或玩家房子
local function make_parks(entities, width, height, spawners, city, unique, unique_parks)
    local total_parks = #city.citynodes
    if unique then total_parks = unique_parks end

    for i = 1, total_parks do
        local choice, selection
        if not made_palace and city.city_id == 2 then
            choice = "pig_palace_1"
        elseif not made_cityhall and city.city_id == 1 then
            choice = "pig_cityhall_1"
        elseif not made_playerhouse and city.city_id == 1 then
            choice = "pig_playerhouse_1"
        elseif unique then
            if #city.unique_park_choices == 0 then return end
            selection = math.random(#city.unique_park_choices)
            choice = city.unique_park_choices[selection]
        else
            choice = PARK_CHOICES[math.random(#PARK_CHOICES)]
        end

        local placed = false
        while not placed and #city.parks > 0 do
            local park = table.remove(city.parks, math.random(#city.parks))
            local old_shops = find_temp_ents(spawners, park.x, park.z, 3, { "pig_shop_spawner" })
            placed = spawn_setpiece(entities, width, height, spawners, choice, park, city)
            if placed then
                for _, spawner in ipairs(old_shops) do
                    for s = #spawners, 1, -1 do
                        if spawner == spawners[s] then table.remove(spawners, s) end
                    end
                end
                if choice == "pig_palace_1" then made_palace = true end
                if choice == "pig_cityhall_1" then made_cityhall = true end
                if choice == "pig_playerhouse_1" then made_playerhouse = true end
                if selection then table.remove(city.unique_park_choices, selection) end
            end
        end
        if not placed then return end
    end
end

-- 在农田区域生成具体的农田布局
local function place_farm(entities, width, height, spawners, nodes, city, total, set)
    local placed_farms = 0
    local break_limit = 0
    while total > placed_farms and break_limit < 50 and #nodes > 0 do
        local tested_nodes = {}
        local total_nodes = #nodes
        local finished = false

        while #tested_nodes < total_nodes and finished == false do
            local farm_num = math.random(1, #nodes)
            local untested = true
            for i, checked_node in ipairs(tested_nodes) do
                if checked_node == farm_num then untested = false end
            end

            if untested then
                table.insert(tested_nodes, farm_num)
                local location = { x = nodes[farm_num].cent[1], y = 0, z = nodes[farm_num].cent[2] }
                location.x, location.y, location.z = get_div1_tile(location.x, location.y, location.z)

                -- 校验：农田不能太靠近水边
                local place_farm = true and not SpawnUtil.IsCloseToWaterTile(location.x, location.z, 1)
                if place_farm then
                    local choice = set[math.random(1, #set)]
                    if spawn_setpiece(entities, width, height, spawners, choice, { x = location.x, y = location.y, z = location.z }, city) then
                        placed_farms = placed_farms + 1
                        table.remove(nodes, farm_num)
                        finished = true
                    end
                end
            end
        end
        if finished == false then
            break_limit = break_limit + 1
            print("COULDNT FIND ANY PLACE TO FIT THIS FARM")
        end
    end
    return nodes
end

-- 放置必须生成的特殊农田（如传送机基座相关的）
local function place_unique_farms(entities, width, height, spawners, cities)
    for i, farm in ipairs(REQUIRED_FARMS) do
        local city = math.random(1, CITIES)
        local nodes = cities[city].farmnodes
        place_farm(entities, width, height, spawners, nodes, cities[city], 1, { farm })
    end
end

-- 在被标记为 Cultivated（耕作地）的区域生成农田和农田守卫塔
local function make_farms(entities, width, height, spawners, nodes, city)
    nodes = place_farm(entities, width, height, spawners, nodes, city, 3, FARM_CHOICES)
    nodes = place_farm(entities, width, height, spawners, nodes, city, 5, FARM_FILLER_CHOICES)

    for i, node in ipairs(nodes) do
        local prefabs = find_temp_ents(spawners, node.cent[1], node.cent[2], 1)
        if #prefabs == 0 then
            if test_tile({ x = node.cent[1], z = node.cent[2] }, { WORLD_TILES.FIELDS }) then
                add_temp_ents(spawners, node.cent[1], node.cent[2], "pig_guard_tower", city.city_id)
            end
        end
    end
end

-- 建筑配额结算：将“商店占位符”随机替换为配额表中定义的具体商店和房屋
local function set_buildings(spawners, city)
    local building_quotas = {}
    local set = BUILDING_QUOTAS
    if city.city_id == 2 then set = BUILDING_QUOTAS_2 end

    for item, data in pairs(set) do building_quotas[item] = data end

    local eligable_list = {}
    for i, spawn in ipairs(spawners) do
        if spawn.prefab == "pig_shop_spawner" and spawn.city == city.city_id then
            table.insert(eligable_list, i)
        end
    end

    for _, data_set in ipairs(building_quotas) do
        local building_type = data_set.prefab
        local num = data_set.num
        for t = 1, num do
            if #eligable_list > 0 then
                local location = math.random(1, #eligable_list)
                spawners[eligable_list[location]].prefab = building_type
                table.remove(eligable_list, location)
            else
                print("*********** RAN OUT OF ELIGABLE LOCATIONS FOR ", building_type, " @ " .. t .. " of " .. num)
            end
        end
    end

    -- 移除最后剩下没被替换的占位符
    for i = #spawners, 1, -1 do
        if spawners[i].prefab == "pig_shop_spawner" and spawners[i].city == city.city_id then
            table.remove(spawners, i)
        end
    end
end

-- 全局移除所有剩余的商店占位符（冗余清理）
local function remove_shop_spawners(spawners)
    for i = #spawners, 1, -1 do
        if spawners[i].prefab == "pig_shop_spawner" then
            table.remove(spawners, i)
        end
    end
end

local function validate_city_buildings(spawners, city)
    local required = city.city_id == 1
        and { pig_shop_cityhall = 1, playerhouse_city = 1 }
        or { pig_palace_entrance = 1 }
    local quotas = city.city_id == 1 and BUILDING_QUOTAS or BUILDING_QUOTAS_2
    for _, quota in ipairs(quotas) do
        if quota.prefab ~= "pig_guard_tower" and quota.prefab ~= "pighouse_city" then
            required[quota.prefab] = quota.num
        end
    end
    for _, spawner in ipairs(spawners) do
        if spawner.city == city.city_id and required[spawner.prefab] ~= nil then
            required[spawner.prefab] = required[spawner.prefab] - 1
        end
    end
    for prefab, missing in pairs(required) do
        if missing > 0 then
            return false, string.format("city %d is missing %d %s", city.city_id, missing, prefab)
        end
    end
    return true
end

-- 列表查找并移除辅助函数
local function is_in_list(list_item, list, dont_remove)
    for i, item in ipairs(list) do
        if item == list_item then
            if not dont_remove then table.remove(list, i) end
            return item
        end
    end
    return false
end

-- 嵌套列表查找辅助函数
local function is_in_nested_list(list_item, parent_list)
    for i, items in pairs(parent_list) do
        if is_in_list(list_item, items, true) then return list_item end
    end
    return false
end

-- 【核心主函数】：执行整个猪人城市的生成流程
local function make_cities(entities, topology_save, worldsim, width, height, setcurrent_gen_params)
    print("BUILDING PIG CULTURE")

    local spawners = {} -- 初始化临时实体列表

    -- 重置全局唯一建筑标记
    made_palace = false
    made_cityhall = false
    made_playerhouse = false
    local unique_park_choices = deepcopy(UNIQUE_PARK_CHOICES)

    -- 第一阶段：根据世界拓扑数据识别并分类城市节点和农田节点
    local cities = {}
    for city_id = 1, CITIES do
        cities[city_id] = { parks = {}, citynodes = {}, farmnodes = {}, city_id = city_id,
            unique_park_choices = unique_park_choices }

        for task, node in pairs(topology_save.root:GetNodes(true)) do
            if table.contains(node.data.tags, "City" .. city_id) then
                local poly_x, poly_y = WorldSim:GetPointsForSite(node.id)
                local c_x, c_y = WorldSim:GetSiteCentroid(node.id)
                local nodedata = { cent = { c_x, c_y }, id = node.id, poly = { x = poly_x, y = poly_y } }

                if is_in_nested_list(node.id, topology_save.GlobalTags["City_Foundation"]) then
                    table.insert(cities[city_id].citynodes, nodedata)
                end

                if is_in_nested_list(node.id, topology_save.GlobalTags["Cultivated"]) then
                    table.insert(cities[city_id].farmnodes, nodedata)
                end
            end
        end
    end

    -- 第二阶段：生成农田布局
    place_unique_farms(entities, width, height, spawners, cities)

    -- 第三阶段：对每个城市执行网格生成、公园放置、建筑结算
    for city_ID, city in ipairs(cities) do
        if not create_city(entities, width, height, spawners, city) then
            return nil, string.format("city %d has no valid starting point", city.city_id)
        end
        make_parks(entities, width, height, spawners, city, true, 2)
        make_parks(entities, width, height, spawners, city)
        set_buildings(spawners, city)
        make_farms(entities, width, height, spawners, city.farmnodes, city)
        local valid, reason = validate_city_buildings(spawners, city)
        if not valid then return nil, reason end
    end

    -- 第四阶段：收尾，清理占位符并将结果导出到游戏世界实体列表
    remove_shop_spawners(spawners)
    export_spawners_to_entites(entities, width, height, spawners)

    return entities
end

-- 返回生成函数给世界加载器
return make_cities
