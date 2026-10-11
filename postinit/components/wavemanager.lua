local TROENV = env
GLOBAL.setfenv(1, GLOBAL)


local function GetWaveBearing(map, ex, ey, ez)
	local radius = 3.5
	local tx, tz = ex % TILE_SCALE, ez % TILE_SCALE
	local left = tx - radius < 0
	local right = tx + radius > TILE_SCALE
	local up = tz - radius < 0
	local down = tz + radius > TILE_SCALE


	local offs_1 =
	{
		{ -1, -1, left and up }, { 0, -1, up }, { 1, -1, right and up },
		{ -1, 0,  left }, { 1, 0, right },
		{ -1, 1, left and down }, { 0, 1, down }, { 1, 1, right and down },
	}

	local width, height = map:GetSize()
	local halfw, halfh = 0.5 * width, 0.5 * height
	local x, y = map:GetTileXYAtPoint(ex, ey, ez)
	local xtotal, ztotal, n = 0, 0, 0

	local is_nearby_land_tile = false

	for i = 1, #offs_1, 1 do
		local curoff = offs_1[i]
		local offx, offy = curoff[1], curoff[2]

		local ground = map:GetTile(x + offx, y + offy)
		if IsLandTile(ground) then
			if curoff[3] then
				return false
			else
				is_nearby_land_tile = true
			end
			xtotal = xtotal + ((x + offx - halfw) * TILE_SCALE)
			ztotal = ztotal + ((y + offy - halfh) * TILE_SCALE)
			n = n + 1
		end
	end

	radius = 4.5
	local minoffx, maxoffx, minoffy, maxoffy
	if not is_nearby_land_tile then
		minoffx = math.floor((tx - radius) / TILE_SCALE)
		maxoffx = math.floor((tx + radius) / TILE_SCALE)
		minoffy = math.floor((tz - radius) / TILE_SCALE)
		maxoffy = math.floor((tz + radius) / TILE_SCALE)
	end

	local offs_2 =
	{
		{ -2, -2 }, { -1, -2 }, { 0, -2 }, { 1, -2 }, { 2, -2 },
		{ -2, -1 }, { 2, -1 },
		{ -2, 0 }, { 2, 0 },
		{ -2, 1 }, { 2, 1 },
		{ -2, 2 }, { -1, 2 }, { 0, 2 }, { 1, 2 }, { 2, 2 }
	}
	for i = 1, #offs_2, 1 do
		local curoff = offs_2[i]
		local offx, offy = curoff[1], curoff[2]

		local ground = map:GetTile(x + offx, y + offy)
		if IsLandTile(ground) then
			if not is_nearby_land_tile then
				is_nearby_land_tile = offx >= minoffx and offx <= maxoffx and offy >= minoffy and offy <= maxoffy
			end
			xtotal = xtotal + ((x + offx - halfw) * TILE_SCALE)
			ztotal = ztotal + ((y + offy - halfh) * TILE_SCALE)
			n = n + 1
		end
	end

	if n == 0 then return true end
	if not is_nearby_land_tile then return false end
	return -math.atan2(ztotal / n - ez, xtotal / n - ex) / DEGREES - 90
end
local function TrySpawnShore(self, map, x, y, z)
	local bearing = GetWaveBearing(map, x, y, z)
	if (bearing ~= true) and ((bearing ~= false)) then
		local wave = SpawnPrefab("wave_shore_tropical")
		wave.Transform:SetPosition(x, y, z)
		wave.Transform:SetRotation(bearing)
		wave:SetAnim()
	end
end

local function TrySpawnWavesOrShore_Lake(self, map, x, y, z)
	local bearing = GetWaveBearing(map, x, y, z)
	if bearing == false then return end

	if bearing == true then
		if math.random() < 0.3 then
			SpawnPrefab("wave_shimmer").Transform:SetPosition(x, y, z)
		end
	else
		local wave = SpawnPrefab("wave_shore_tropical")
		wave.Transform:SetPosition(x, y, z)
		wave.Transform:SetRotation(bearing)
		wave:SetAnim()
	end
end

local function TrySpawnWavesOrShore(self, map, x, y, z)
	local bearing = GetWaveBearing(map, x, y, z)
	if bearing == false then return end

	if bearing == true then
		SpawnPrefab("wave_shimmer_tropical").Transform:SetPosition(x, y, z)
	else
		local wave = SpawnPrefab("wave_shore_tropical")
		wave.Transform:SetPosition(x, y, z)
		wave.Transform:SetRotation(bearing)
		wave:SetAnim()
	end
end

local function TrySpawnWaveShimmerMedium(self, map, x, y, z)
	if map:IsSurroundedByWater(x, y, z, 4) then
		local wave = SpawnPrefab("wave_shimmer_med_tropical")
		wave.Transform:SetPosition(x, y, z)
	end
end

local function TrySpawnWaveShimmerDeep(self, map, x, y, z)
	if map:IsSurroundedByWater(x, y, z, 5) then
		local wave = SpawnPrefab("wave_shimmer_deep_tropical")
		wave.Transform:SetPosition(x, y, z)
	end
end


local function calcShimmerRadius()
	local percent = (math.clamp(TheCamera:GetDistance(), 30, 100) - 30) / (70)
	local radius = (75 - 30) * percent + 30
	return radius
end

local function calcPerSecMult(min, max)
	local percent = (math.clamp(TheCamera:GetDistance(), 30, 100) - 30) / (70)
	local mult = (1.5 - 1) * percent + 1 -- 1x to 1.5x
	return mult
end

local FLOOD_RIPPLES_PER_SECOND = 8
local FLOOD_RIPPLE_ATTEMPTS = 12

local function TrySpawnFloodRipple()
    local player = ThePlayer
    local visuals = player ~= nil and player.components.floodwatervisuals or nil
    if visuals == nil or not visuals:IsInFloodRegion() then
        return false
    end

    local x, _, z = player.Transform:GetWorldPosition()
    local radius = calcShimmerRadius()
    for _ = 1, FLOOD_RIPPLE_ATTEMPTS do
        local angle = math.random() * 2 * PI
        local distance = math.sqrt(math.random()) * radius
        local wave_x = x + math.cos(angle) * distance
        local wave_z = z + math.sin(angle) * distance
        if visuals:IsFloodedAtPoint(wave_x, wave_z) then
            local wave = SpawnPrefab("wave_shimmer_flood_tropical")
            if wave ~= nil then
                wave.Transform:SetPosition(wave_x, 0, wave_z)
            end
            return true
        end
    end
    return false
end



local tro_shimmer = {
	[WORLD_TILES.LILYPOND] = { per_sec = 200, spawn_rate = 0, tryspawn = TrySpawnWavesOrShore_Lake },
	[WORLD_TILES.OCEAN_CORAL] = { per_sec = 80, spawn_rate = 0, tryspawn = TrySpawnWaveShimmerDeep },
	[WORLD_TILES.MANGROVE] = { per_sec = 80, spawn_rate = 0, tryspawn = TrySpawnWavesOrShore },


	[WORLD_TILES.OCEAN_SHALLOW_SHORE] = { per_sec = 200, spawn_rate = 0, tryspawn = TrySpawnShore },
	[WORLD_TILES.OCEAN_SHALLOW] = { per_sec = 75, spawn_rate = 0, tryspawn = TrySpawnWavesOrShore },
	[WORLD_TILES.OCEAN_MEDIUM] = { per_sec = 75, spawn_rate = 0, tryspawn = TrySpawnWaveShimmerMedium },
	[WORLD_TILES.OCEAN_DEEP] = { per_sec = 70, spawn_rate = 0, tryspawn = TrySpawnWaveShimmerDeep },
	[WORLD_TILES.OCEAN_SHIPGRAVEYARD] = { per_sec = 80, spawn_rate = 0, tryspawn = TrySpawnWaveShimmerDeep },

	-- FLOOD = {per_sec = 80, spawn_rate = 0, checkfn = CheckFlood, spawnfn = SpawnTropicalWaveFlood},
}

-- local function SetWaveSettings(self, shimmer)
-- 	self.shimmer_per_sec_mod = shimmer
-- end

TROENV.AddComponentPostInit("wavemanager", function(cmp)
	for i, v in pairs(tro_shimmer) do
		cmp.shimmer[i] = v
	end

	-- Flooded land is not a real map tile in DST, so it cannot be registered
	-- in shimmer[] like ocean ground. Feed the same wave manager from the
	-- client-side flood view instead; the view uses the server's synced level
	-- and the shared deterministic flood pattern.
	local old_onupdate = cmp.OnUpdate
	function cmp:OnUpdate(dt)
		old_onupdate(self, dt)
		if ThePlayer == nil or ThePlayer.components.floodwatervisuals == nil then
			return
		end

		self._tropical_flood_ripple_accumulator =
			(self._tropical_flood_ripple_accumulator or 0) + dt * FLOOD_RIPPLES_PER_SECOND
		while self._tropical_flood_ripple_accumulator >= 1 do
			self._tropical_flood_ripple_accumulator = self._tropical_flood_ripple_accumulator - 1
			TrySpawnFloodRipple()
		end
	end
end)
