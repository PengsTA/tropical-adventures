local CUBES = table.invert({ "default", "shipwrecked", "volcano", "hamlet", "aporkalypse" })


local dormant = resolvefilepath("images/colour_cubes/sw_volcano_cc.tex")
local active = resolvefilepath("images/colour_cubes/sw_volcano_active_cc.tex")
local bloodmoon = resolvefilepath("images/colour_cubes/pork_cold_bloodmoon_cc.tex")

local REGION_SEASON_COLOURCUBES = {
	shipwrecked = {
		autumn = {
			day = resolvefilepath("images/colour_cubes/sw_mild_day_cc.tex"),
			dusk = resolvefilepath("images/colour_cubes/SW_mild_dusk_cc.tex"),
			night = resolvefilepath("images/colour_cubes/SW_mild_dusk_cc.tex"),
			full_moon = resolvefilepath("images/colour_cubes/purple_moon_cc.tex"),
		},
		winter = {
			day = resolvefilepath("images/colour_cubes/SW_wet_day_cc.tex"),
			dusk = resolvefilepath("images/colour_cubes/SW_wet_dusk_cc.tex"),
			night = resolvefilepath("images/colour_cubes/SW_wet_dusk_cc.tex"),
			full_moon = resolvefilepath("images/colour_cubes/purple_moon_cc.tex"),
		},
		spring = {
			day = resolvefilepath("images/colour_cubes/sw_green_day_cc.tex"),
			dusk = resolvefilepath("images/colour_cubes/sw_green_dusk_cc.tex"),
			night = resolvefilepath("images/colour_cubes/sw_green_dusk_cc.tex"),
			full_moon = resolvefilepath("images/colour_cubes/purple_moon_cc.tex"),
		},
		summer = {
			day = resolvefilepath("images/colour_cubes/SW_dry_day_cc.tex"),
			dusk = resolvefilepath("images/colour_cubes/SW_dry_dusk_cc.tex"),
			night = resolvefilepath("images/colour_cubes/SW_dry_dusk_cc.tex"),
			full_moon = resolvefilepath("images/colour_cubes/purple_moon_cc.tex"),
		},
	},

	hamlet = {
		autumn = {
			day = resolvefilepath("images/colour_cubes/pork_temperate_day_cc.tex"),
			dusk = resolvefilepath("images/colour_cubes/pork_temperate_dusk_cc.tex"),
			night = resolvefilepath("images/colour_cubes/pork_temperate_night_cc.tex"),
			full_moon = resolvefilepath("images/colour_cubes/pork_temperate_fullmoon_cc.tex"),
		},
		winter = {
			day = resolvefilepath("images/colour_cubes/pork_cold_day_cc.tex"),
			dusk = resolvefilepath("images/colour_cubes/pork_cold_dusk_cc.tex"),
			night = resolvefilepath("images/colour_cubes/pork_cold_dusk_cc.tex"),
			full_moon = resolvefilepath("images/colour_cubes/pork_cold_fullmoon_cc.tex"),
		},
		spring = {
			day = resolvefilepath("images/colour_cubes/pork_lush_day_test.tex"),
			dusk = resolvefilepath("images/colour_cubes/pork_lush_dusk_test.tex"),
			night = resolvefilepath("images/colour_cubes/pork_lush_dusk_test.tex"),
			full_moon = resolvefilepath("images/colour_cubes/pork_warm_fullmoon_cc.tex"),
		},
		summer = {
			day = resolvefilepath("images/colour_cubes/SW_dry_day_cc.tex"),
			dusk = resolvefilepath("images/colour_cubes/SW_dry_dusk_cc.tex"),
			night = resolvefilepath("images/colour_cubes/SW_dry_dusk_cc.tex"),
			full_moon = resolvefilepath("images/colour_cubes/purple_moon_cc.tex"),
		},
	},

	volcano = {
		autumn = {
			day = dormant,
			dusk = dormant,
			night = dormant,
			full_moon = dormant
		},
		winter = {
			day = dormant,
			dusk = dormant,
			night = dormant,
			full_moon = dormant
		},
		spring = {
			day = dormant,
			dusk = dormant,
			night = dormant,
			full_moon = dormant
		},
		summer = {
			day = active,
			dusk = active,
			night = active,
			full_moon = active
		},
	},

	aporkalypse = {
		autumn = {
			day = bloodmoon,
			dusk = bloodmoon,
			night = bloodmoon,
			full_moon = bloodmoon

		},
	},


}

AddComponentPostInit("colourcube", function(self)
	local OnOverrideCCPhaseFn, _UpdateAmbientCCTable, _SEASON_COLOURCUBES
	for i, v in ipairs(self.inst.event_listening["playeractivated"][TheWorld]) do
		OnOverrideCCPhaseFn = Upvaluehelper.GetUpvalue(v, "OnOverrideCCPhaseFn")
		if OnOverrideCCPhaseFn then
			break
		end
	end

	_UpdateAmbientCCTable = Upvaluehelper.GetUpvalue(OnOverrideCCPhaseFn, "UpdateAmbientCCTable")
	_SEASON_COLOURCUBES = Upvaluehelper.GetUpvalue(_UpdateAmbientCCTable, "SEASON_COLOURCUBES")

	local _activatedplayer
	local _showencc = CUBES.default
	local function UpdateAmbientCCTable(blendtime)
		if _activatedplayer then
			if TheWorld.state.isaporkalypse and not TheWorld:HasTag("cave") then
				if _showencc ~= CUBES.aporkalypse then
					_showencc = CUBES.aporkalypse
					Upvaluehelper.SetUpvalue(_UpdateAmbientCCTable, REGION_SEASON_COLOURCUBES.aporkalypse, "SEASON_COLOURCUBES")
				end
			elseif _activatedplayer:AwareInShipwreckedVolcanoRegion() then
				if _showencc ~= CUBES.volcano then
					_showencc = CUBES.volcano
					Upvaluehelper.SetUpvalue(_UpdateAmbientCCTable, REGION_SEASON_COLOURCUBES.volcano, "SEASON_COLOURCUBES")
				end
			elseif _activatedplayer:AwareInShipwreckedRegion() then
				--print("colourcube shipwrecked")
				if _showencc ~= CUBES.shipwrecked then
					_showencc = CUBES.shipwrecked
					Upvaluehelper.SetUpvalue(_UpdateAmbientCCTable, REGION_SEASON_COLOURCUBES.shipwrecked, "SEASON_COLOURCUBES")
				end
			elseif _activatedplayer:AwareInHamletRegion() then
				--print("colourcube hamlet")
				if _showencc ~= CUBES.hamlet then
					_showencc = CUBES.hamlet
					Upvaluehelper.SetUpvalue(_UpdateAmbientCCTable, REGION_SEASON_COLOURCUBES.hamlet, "SEASON_COLOURCUBES")
				end
			else
				--print("colourcube default")
				if _showencc ~= CUBES.default then
					_showencc = CUBES.default
					Upvaluehelper.SetUpvalue(_UpdateAmbientCCTable, _SEASON_COLOURCUBES, "SEASON_COLOURCUBES")
				end
			end
		end

		return _UpdateAmbientCCTable(blendtime)
	end

	Upvaluehelper.SetUpvalue(OnOverrideCCPhaseFn, UpdateAmbientCCTable, "UpdateAmbientCCTable")

	local function onClimateDirty()
		-- print("colourcube climate dirty")
		UpdateAmbientCCTable(6)
	end

	local function onClimateDirtyfast()
		UpdateAmbientCCTable(2)
	end
	self.inst:WatchWorldState("isaporkalypse", onClimateDirtyfast)
	self.inst:ListenForEvent("playeractivated", function(src, player)
		if player and _activatedplayer ~= player then
			if _activatedplayer ~= nil then
				_activatedplayer:RemoveEventCallback("regionchange_client", onClimateDirty)
			end
			player:ListenForEvent("regionchange_client", onClimateDirty)
			player:DoTaskInTime(0, function()
				if _activatedplayer == player then
					UpdateAmbientCCTable(.01)
				end
			end)
		end
		_activatedplayer = player
	end)
	self.inst:ListenForEvent("playerdeactivated", function(src, player)
		if player then
			player:RemoveEventCallback("regionchange_client", onClimateDirty)
			if _activatedplayer == player then
				_activatedplayer = nil
			end
		end
	end)
end)
