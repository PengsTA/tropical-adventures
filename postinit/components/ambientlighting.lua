local COLOURS = {
	INTERIOR_COLOURS =
	{
		PHASE_COLOURS =
		{
			default =
			{
				day = { colour = Point(171 / 255, 146 / 255, 147 / 255), time = 4 },
				dusk = { colour = Point(101 / 255, 76 / 255, 77 / 255), time = 6 },
				night = { colour = Point(11 / 255, 6 / 255, 7 / 255), time = 8 },
			},
		},

		FULL_MOON_COLOUR = { colour = Point(0, 0, 0), time = 8 },
		CAVE_COLOUR = { colour = Point(0, 0, 0), time = 2 },
	},

	APORKALYPSE_COLOURS = {
		PHASE_COLOURS =
		{
			default =
			{
				day = { colour = Point(200 / 255, 0, 0), time = 2 },
				dusk = { colour = Point(200 / 255, 0, 0), time = 2 },
				night = { colour = Point(200 / 255, 0, 0), time = 2 },
			},
		},

		FULL_MOON_COLOUR = { colour = Point(200 / 255, 0, 0), time = 2 },
		CAVE_COLOUR = { colour = Point(20 / 255, 0, 0), time = 2 },
	},

	-- TROPICAL_COLOURS =
	-- {
	-- 	PHASE_COLOURS =
	-- 	{
	-- 		default =
	-- 		{
	-- 			day = { colour = Point(255 / 255, 244 / 255, 213 / 255), time = 6 },
	-- 			dusk = { colour = Point(171 / 255, 146 / 255, 147 / 255), time = 6 },
	-- 			night = { colour = Point(0 / 255, 0 / 255, 0 / 255), time = 6 },
	-- 		},
	-- 	},

	-- 	FULL_MOON_COLOUR = { colour = Point(0, 0, 0), time = 6 },
	-- 	CAVE_COLOUR = { colour = Point(0, 0, 0), time = 2 },
	-- },
}



AddComponentPostInit("ambientlighting", function(self, inst)
	-- if false and not TheNet:IsDedicated() then ------这种非全局性的东西还是不要放到ambientlighting
	-- 	local DoUpdateFlash = Upvaluehelper.GetUpvalue(self.OnUpdate, "DoUpdateFlash")
	-- 	local PushCurrentColour = Upvaluehelper.GetUpvalue(self.OnUpdate, "PushCurrentColour")
	-- 	local _realcolour = Upvaluehelper.GetUpvalue(DoUpdateFlash, "_realcolour")
	-- 	local _overridecolour = Upvaluehelper.GetUpvalue(DoUpdateFlash, "_overridecolour")
	-- 	local _ComputeTargetColour = Upvaluehelper.GetUpvalue(DoUpdateFlash, "ComputeTargetColour")

	-- 	local _activatedplayer

	-- 	local function ComputeTargetColour(targetsettings, timeoverride, ...)
	-- 		if _activatedplayer and targetsettings == _overridecolour and _overridecolour.currentcolourset.PHASE_COLOURS.spring then
	-- 			local temp = _overridecolour.currentcolourset

	-- 			if _activatedplayer:AwareInTropicalArea() then
	-- 				_overridecolour.currentcolourset = COLOURS.TROPICAL_COLOURS
	-- 			end
	-- 			_ComputeTargetColour(targetsettings, timeoverride, ...)
	-- 			_overridecolour.currentcolourset = temp
	-- 			return
	-- 		end
	-- 		_ComputeTargetColour(targetsettings, timeoverride, ...)
	-- 	end

	-- 	Upvaluehelper.SetUpvalue(DoUpdateFlash, ComputeTargetColour, "ComputeTargetColour")



	-- 	local function OnClimateChanged()
	-- 		-- ComputeTargetColour(_realcolour)
	-- 		ComputeTargetColour(_overridecolour)
	-- 		PushCurrentColour()
	-- 	end



	-- 	self.inst:ListenForEvent("playeractivated", function(src, player)
	-- 		--print("ambientlighting:OnClimateChanged")
	-- 		if player then
	-- 			player:ListenForEvent("regionchange_client", OnClimateChanged)
	-- 			player:DoTaskInTime(0, function() OnClimateChanged() end) --initialise
	-- 		end
	-- 		_activatedplayer = player
	-- 	end)
	-- 	self.inst:ListenForEvent("playerdeactivated", function(src, player)
	-- 		if player then
	-- 			player:RemoveEventCallback("regionchange_client", OnClimateChanged)
	-- 		end
	-- 		if _activatedplayer == player then
	-- 			_activatedplayer = nil
	-- 		end
	-- 	end)
	-- end

	if true then
		local DoUpdateFlash = Upvaluehelper.GetUpvalue(self.OnUpdate, "DoUpdateFlash")
		local PushCurrentColour = Upvaluehelper.GetUpvalue(self.OnUpdate, "PushCurrentColour")
		local _realcolour = Upvaluehelper.GetUpvalue(DoUpdateFlash, "_realcolour")   ---真正的颜色(控制查理)
		local _overridecolour = Upvaluehelper.GetUpvalue(DoUpdateFlash, "_overridecolour") ---表现的颜色
		local _ComputeTargetColour = Upvaluehelper.GetUpvalue(DoUpdateFlash, "ComputeTargetColour")

		local function ComputeTargetColour(targetsettings, timeoverride, ...)
			if TheWorld._ta_config_ready and not TheWorld:HasTag("cave") and TheWorld.state.isaporkalypse and targetsettings.currentcolourset.PHASE_COLOURS.spring then
				local temp = targetsettings.currentcolourset
				targetsettings.currentcolourset = COLOURS.APORKALYPSE_COLOURS
				_ComputeTargetColour(targetsettings, timeoverride, ...)
				targetsettings.currentcolourset = temp
				return
			end
			_ComputeTargetColour(targetsettings, timeoverride, ...)
		end

		Upvaluehelper.SetUpvalue(DoUpdateFlash, ComputeTargetColour, "ComputeTargetColour")



		local function OnClimateChanged()
			ComputeTargetColour(_realcolour)
			ComputeTargetColour(_overridecolour)
			PushCurrentColour()
		end

		self.inst:WatchWorldState("startaporkalypse", OnClimateChanged) ----为什么 用isaporkalypse就不行呢
		self.inst:WatchWorldState("stopaporkalypse", OnClimateChanged)
		self.inst:ListenForEvent("taconfigready", OnClimateChanged, TheWorld)
		self.inst:DoTaskInTime(0, OnClimateChanged)               --initialise
	end
end)
