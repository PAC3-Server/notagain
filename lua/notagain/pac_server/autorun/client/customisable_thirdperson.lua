ctp = ctp or {} local ctp = ctp

ctp.AllowedClasses = {
	"player",
	"prop_",
	"npc_",
}

ctp.DisabledElements = {
	"CHudSuitPower",
	"CHudHealth",
	"CHudBattery",
	"CHudAmmo",
	"CHudSecondaryAmmo",
	"CHudEPOE",
}

ctp.BoneList = {
	["pelvis"] = "ValveBiped.Bip01_Pelvis",
	["spine_1"] = "ValveBiped.Bip01_Spine",
	["spine_2"] = "ValveBiped.Bip01_Spine1",
	["spine_3"] = "ValveBiped.Bip01_Spine2",
	["spine_4"] = "ValveBiped.Bip01_Spine4",
	["neck"] = "ValveBiped.Bip01_Neck1",
	["head"] = "ValveBiped.Bip01_Head1",
	["right_clavicle"] = "ValveBiped.Bip01_R_Clavicle",
	["right_upper arm"] = "ValveBiped.Bip01_R_UpperArm",
	["right_forearm"] = "ValveBiped.Bip01_R_Forearm",
	["right_hand"] = "ValveBiped.Bip01_R_Hand",
	["left_clavicle"] = "ValveBiped.Bip01_L_Clavicle",
	["left_upper arm"] = "ValveBiped.Bip01_L_UpperArm",
	["left_forearm"] = "ValveBiped.Bip01_L_Forearm",
	["left_hand"] = "ValveBiped.Bip01_L_Hand",
	["right_thigh"] = "ValveBiped.Bip01_R_Thigh",
	["right_calf"] = "ValveBiped.Bip01_R_Calf",
	["right_foot"] = "ValveBiped.Bip01_R_Foot",
	["right_toe"] = "ValveBiped.Bip01_R_Toe0",
	["left_thigh"] = "ValveBiped.Bip01_L_Thigh",
	["left_calf"] = "ValveBiped.Bip01_L_Calf",
	["left_foot"] = "ValveBiped.Bip01_L_Foot",
	["left_toe"] = "ValveBiped.Bip01_L_Toe0",
	["none"] = "none",
	["eyepos"] = "eyepos",
	["bottom"] = "bottom",
}

ctp.DisabledHooks = {
	"CalcView",
	"ShouldDrawLocalPlayer",
	"CalcVehicleThirdPersonView",
}

ctp.HistoryCount = 10

local function HOOK(name, func)
	hook.Add(name, "ctp_" .. name, func or ctp[name])
end

local function UNHOOK(name)
	local unique = "ctp_" .. name
	local hooks = hook.GetTable()
	if hooks[name] and hooks[name][unique] then
		hook.Remove(name, unique)
	end
end

local function FindPlayerByName(str)
	if str == "" or not str then return LocalPlayer() end

	for key, ply in pairs(player.GetAll()) do
		if ply:Nick():lower():find(str:lower()) then
			return ply
		end
	end

	return LocalPlayer()
end

function ctp:Initialize()
	self.SmoothOrigin = self.SmoothOrigin or Vector(0, 0, 0)
	self.SmoothDirection = self.SmoothDirection or Vector(0, 0, 0)
	self.SmoothFOV = self.SmoothFOV or 0

	local vectors = {}

	for i=1, self.HistoryCount do
		table.insert(vectors, vector_origin)
	end

	self.PrevOrigin = self.PrevOrigin or Vector(0, 0, 0)
	self.PlyPosHistory = vectors
	self.PrevDirection = self.PrevDirection or Vector(0, 0, 0)
	self.DirectionHistory = vectors
	self.PrevFOV = self.PrevFOV or 0

	self.RelativeOriginSpeed = 1

	self.Direction = self.Direction or Vector(0, 0, 0)

	self.Roll = self.Roll or 0
	self.SmoothRoll = self.SmoothRoll or 0

	self.CVars = {}

	self:InitCVars()
end

do -- luadata
	local luadata = {}

	local tab = 0

	luadata.Types = {
		["number"] = function(var)
			return ("%s"):format(var)
		end,
		["string"] = function(var)
			return ("%q"):format(var)
		end,
		["boolean"] = function(var)
			return ("%s"):format(var and "true" or "false")
		end,
		["Vector"] = function(var)
			return ("Vector(%s, %s, %s)"):format(var.x, var.y, var.z)
		end,
		["Angle"] = function(var)
			return ("Angle(%s, %s, %s)"):format(var.p, var.y, var.r)
		end,
		["table"] = function(var)
			if
				type(var.r) == "number" and
				type(var.g) == "number" and
				type(var.b) == "number" and
				type(var.a) == "number"
			then
				return ("Color(%s, %s, %s, %s)"):format(var.r, var.g, var.b, var.a)
			end

			tab = tab + 1
			local str = luadata.Encode(var, true)
			tab = tab - 1
			return str
		end,
	}

	function luadata.SetModifier(type, callback)
		luadata.Types[type] = callback
	end

	function luadata.Type(var)
		local t

		if IsEntity(var) then
			if var:IsValid() then
				t = "Entity"
			else
				t = "NULL"
			end
		else
			t = type(var)
		end

		if t == "table" then
			if var.LuaDataType then
				t = var.LuaDataType
			end
		end

		return t
	end

	function luadata.ToString(var)
		local func = luadata.Types[luadata.Type(var)]
		return func and func(var)
	end

	function luadata.Encode(tbl, __brackets)
		local str = __brackets and "{\n" or ""

		for key, value in pairs(tbl) do
			value = luadata.ToString(value)
			key = luadata.ToString(key)

			if key and value and key ~= "__index" then
				str = str .. ("\t"):rep(tab) ..  ("[%s] = %s,\n"):format(key, value)
			end
		end

		str = str .. ("\t"):rep(tab-1) .. (__brackets and "}" or "")

		return str
	end

	function luadata.Decode(str)
		local func = CompileString("return {\n" .. str .. "\n}", "luadata", false)

		if type(func) == "string" then
			MsgN("luadata decode error:")
			MsgN(func)

			return {}
		end

		local ok, err = pcall(func)

		if not ok then
			MsgN("luadata decode error:")
			MsgN(err)
			return {}
		end

		return err
	end

	do -- file extension
		function luadata.WriteFile(path, tbl)
			file.Write(path, luadata.Encode(tbl))
		end

		function luadata.ReadFile(path)
			return luadata.Decode(file.Read(path) or "")
		end
	end

	ctp.luadata = luadata
end

do -- CVars

	function ctp:InitCVars()
		self:RegisterCVar("threshold_enabled", "ThresholdEnabled", "boolean")
		self:RegisterCVar("threshold_radius", "ThresholdRadius", "float", nil, 10)

		self:RegisterCVar("offset_relative", "OffsetRelative", "boolean")
		self:RegisterCVar("offset_lock_z", "ZLockEnabled", "boolean")

		self:RegisterCVar("offset_fov_zoom_distance_enabled", "ZoomDistanceEnabled", "boolean")
		self:RegisterCVar("offset_fov_zoom_distance", "ZoomDistance", "float")
		self:RegisterCVar("offset_fov_zoom_distance_min", "MinZoomDistance", "float")
		self:RegisterCVar("offset_fov", "FOV", "float")
		self:RegisterCVar("offset_right", "Right", "float")
		self:RegisterCVar("offset_forward", "Forward", "float")
		self:RegisterCVar("offset_up", "Up", "float")

		self:RegisterCVar("smoother_origin", "OriginSmoother", "float")
		self:RegisterCVar("smoother_direction", "DirectionSmoother", "float")
		self:RegisterCVar("smoother_nodes_direction", "float")
		self:RegisterCVar("smoother_fov", "FOVSmoother", "float")

		self:RegisterCVar("lerp_aim", "AimLerp", "float")

		self:RegisterCVar("angles_roll_amount", "RollAmount", "float")

		self:RegisterCVar("angles_limit", "AngleLimitEnabled", "boolean")
		self:RegisterCVar("angles_limit_smooth", "AngleLimitSmoothEnabled", "boolean")

		self:RegisterCVar("angles_pitch", "UserPitch", "float")
		self:RegisterCVar("angles_yaw", "UserYaw", "float")
		self:RegisterCVar("angles_roll", "UserRoll", "float")

		self:RegisterCVar("target_enable", "TargettingEnabled", "boolean")
		self:RegisterCVar("target_radius", "TargetRadius", "float")
		self:RegisterCVar("target_lerp", "TargetLerp", "float")
		self:RegisterCVar("target_fov", "TargetFOV", "float")

		self:RegisterCVar("movement_lock_pitch", "LockPitchEnabled", "boolean")

		self:RegisterCVar("movement_rtc_enable", "RTCEnabled", "boolean")
		self:RegisterCVar("movement_rtc_yaw_offset", "RTCYawOffset", "float")
		self:RegisterCVar("movement_rtc_turn_time", "RTCTurnTime", "float")
		self:RegisterCVar("movement_rtc_walk_focus", "WalkFocusEnabled", "boolean")

		self:RegisterCVar("hud_crosshair_enable", "CrosshairEnabled", "boolean")
		self:RegisterCVar("hud_crosshair_distance", "CrosshairDistance", "float")
		self:RegisterCVar("hud_hide", "HUDHidden", "boolean")
		self:RegisterCVar("hud_hide_all", "AllHUDHidden", "boolean")
		self:RegisterCVar("hud_black_bars_enable", "BlackBarsEnabled", "boolean")
		self:RegisterCVar("hud_black_bars_amount", "BlackBarAmount", "float")

		self:RegisterCVar("nodes_place_enable", "NodePlacerEnabled", "boolean")
		self:RegisterCVar("nodes_enable", "NodesEnabled", "boolean")
		self:RegisterCVar("nodes_draw", "DrawingNodesEnabled", "boolean")
		self:RegisterCVar("nodes_draw_spheres", "DrawingNodeSpheresEnabled", "boolean")
		self:RegisterCVar("nodes_load_by_map_name", "LoadByMapNameEnabled", "boolean")

		self:RegisterCVar("center_offset_forward", "CenterOffsetForward", "float")
		self:RegisterCVar("center_offset_right", "CenterOffsetRight", "float")
		self:RegisterCVar("center_offset_up", "CenterOffsetUp", "float")

		self:RegisterCVar("bone_name", "Bone", "string")

		self:RegisterCVar("trace_enable", "TraceBlockEnabled", "boolean")
		self:RegisterCVar("trace_smooth", "TraceBlockSmoothEnabled", "boolean")
		self:RegisterCVar("trace_forward", "TraceForward", "float")
		self:RegisterCVar("trace_down", "TraceDown", "float")

		self:RegisterCVar("near_z", "NearZ", "float")
		self:RegisterCVar("relative_near_z", "RelativeNearZ", "boolean")

	end

	function ctp:GetCVarValue(name)
		return self[self.CVars[name]].GetVar()
	end

	local function clamp(num, min, max)
		if not min and not max then
			return num
		end

		if min and not max then
			return math.max(num, min)
		end

		if max and not min then
			return math.min(num, max)
		end

		return math.Clamp(num, min, max)
	end

	function ctp:RegisterCVar(name, namefunc, type, dontsave, min, max)


		name = name:lower()
		type = type or "float"
		local default = ctp.DefaultPresets[1].cvars[name] -- valve thirdperson

		if not default then
			print("ctp missing default value for", name)
			default = 0
		end

		self.CVars[name] = {cvar = CreateClientConVar("cl_ctp_" .. name, default, not dontsave), type = type, dontsave = dontsave}

		local function GetVar()
			return
				type == "boolean" and self.CVars[name].cvar:GetBool() or
				type == "integer" and clamp(self.CVars[name].cvar:GetInt(), min, max) or
				type == "float" and clamp(self.CVars[name].cvar:GetFloat(), min, max) or
				type == "string" and self.CVars[name].cvar:GetString()
		end

		self.CVars[name].GetVar = GetVar

		self[(type == "boolean" and "Is" or "Get") .. namefunc] = function()
			return GetVar()
		end

	end

end

do -- Enable

	CreateClientConVar("ctp_enabled", "0", false, true)

	local META = FindMetaTable("Player")

	function META:IsCTPEnabled()
		return self:GetNWBool("ctp_enabled")
	end

	function ctp:Enable()

		-- For shit like ctp.Enable() to match gmod's way.
		self = self or ctp

		if self:IsEnabled() then return end

		--MsgN("Enabling ctp")

		self:ResetSmoothers()

		for _, event in pairs(ctp.DisabledHooks) do
			local hooks = hook.GetTable()[event]

			if hooks then
				self.OldHooks = self.OldHooks or {}
				self.OldHooks[event] = self.OldHooks[event] or {}
				self.OldHooks[event] = table.Copy(hooks)

				for name in pairs(hooks) do
					hook.Remove(event, name)
				end
			end
		end

		HOOK("CalcView", function(...) return ctp:CalcView(...) end)
		HOOK("CalcVehicleThirdPersonView", function(_, ...) return ctp:CalcView(...) end)
		HOOK("CreateMove", function(ucmd) return ctp:CreateMove(ucmd) end)
		HOOK("HUDPaintBackground", function() ctp:HUDPaintBackground() end)
		HOOK("HUDPaint", function() return ctp:HUDPaint() end)
		HOOK("HUDShouldDraw", function(element) return ctp:HUDShouldDraw(element) end)
		HOOK("ShouldDrawLocalPlayer", function() if ctp:IsEnabled() then return true end end)
		HOOK("PlayerStepSoundTime", function(...) return ctp:PlayerStepSoundTime(...) end)
		HOOK("GUIMousePressed", function(...) return ctp:GUIMousePressed(...) end)
		HOOK("GUIMouseReleased", function(...) return ctp:GUIMouseReleased(...) end)
		HOOK("PreventScreenClicks", function(...) return ctp:PreventScreenClicks(...) end)

		self:SetPlayer(FindPlayerByName(self:GetPlayerName()))

		self.Enabled = true

		if self:IsLoadByMapNameEnabled() then
			self:LoadNodePreset(game.GetMap())
		end

		RunConsoleCommand("ctp_enabled", "1")

		local ply = FindPlayerByName(self:GetPlayerName())

		if IsValid(self.__player_text_entry)  then
			self.__player_text_entry:SetValue(ply:Nick())
		end

		self:SetPlayer(ply)
	end

	function ctp:Disable()

		self = self or ctp

		if not self:IsEnabled() then return end

		--MsgN("Disabling ctp")

		if self.OldHooks then
			for event, hooks in pairs(self.OldHooks) do
				for name, func in pairs(hooks) do
					hook.Add(event, name, func)
				end
			end
		end

		UNHOOK("CalcView")
		UNHOOK("PreRender")
		UNHOOK("Think")
		UNHOOK("CalcVehicleThirdPersonView")
		UNHOOK("CreateMove")
		UNHOOK("HUDPaintBackground")
		UNHOOK("HUDPaint")
		UNHOOK("HUDShouldDraw")
		UNHOOK("ShouldDrawLocalPlayer")
		UNHOOK("PlayerStepSoundTime")
		UNHOOK("GUIMousePressed")
		UNHOOK("GUIMouseReleased")
		UNHOOK("PreventScreenClicks")

		self.OldHooks = nil

		self:GetPlayer():SetEyeAngles(self:GetDirection():Angle())

		self.Enabled = false
		self.NodeView = false

		RunConsoleCommand("ctp_enabled", "0")
	end

	function ctp:IsEnabled()
		return self.Enabled
	end

	function ctp:Toggle()
		self = self or ctp

		if ctp:IsEnabled() then
			ctp:Disable()
		else
			ctp:Enable()
		end
	end

	function ctp:ShowMenu()
		if IsValid(ctp.Frame) then return end

		ctp.Frame = vgui.Create("ctp_MainFrame")
	end

	function ctp:CloseMenu()
		if IsValid(ctp.Frame) then ctp.Frame:Close() end
	end

	function ctp:IsMenuVisible()
		return IsValid(self.Frame)
	end

	function ctp:ToggleMenu()
		if ctp:IsMenuVisible() then
			ctp:CloseMenu()
		else
			ctp:ShowMenu()
		end
	end

	concommand.Add("ctp", function()
		ctp:Toggle()
	end)

	concommand.Add("ctp_toggle_menu", function()
		ctp:ToggleMenu()
	end)

	hook.Add("PopulateToolMenu", "ctp_PopulateToolMenu", function()
		spawnmenu.AddToolMenuOption("Utilities",
			"Visuals",
			"CTP",
			"CTP Options",    "",    "",
			function(panel)
				panel:AddPanel(vgui.Create("ctp_ContextMenu"))
			end
		)
	end)

end

do -- Presets

	do -- default
		ctp.DefaultPresets =
		{
			{
				["name"] = "Valve Thirdperson",
				["description"] = "This preset mimics valve's thirdperson camera",
				["cvars"] = {
					["offset_fov_zoom_distance"] = 1200,
					["smoother_origin"] = 40,
					["nodes_load_by_map_name"] = 0,
					["hud_hide"] = 0,
					["movement_rtc_walk_focus"] = 0,
					["nodes_enable"] = 0,
					["center_offset_forward"] = 0,
					["hud_crosshair_enable"] = 1,
					["hud_black_bars_enable"] = 0,
					["offset_right"] = 0,
					["trace_forward"] = 20,
					["lerp_aim"] = 100,
					["offset_up"] = 52,
					["target_radius"] = 0,
					["smoother_nodes_direction"] = 50,
					["threshold_radius"] = 0,
					["bone_name"] = "none",
					["hud_crosshair_distance"] = 32000,
					["movement_rtc_yaw_offset"] = 0,
					["angles_pitch"] = 0,
					["angles_roll_amount"] = 0,
					["movement_lock_pitch"] = 0,
					["trace_smooth"] = 1,
					["angles_yaw"] = 0,
					["threshold_enabled"] = 0,
					["nodes_draw"] = 0,
					["nodes_draw_spheres"] = 0,
					["smoother_direction"] = 40,
					["offset_fov_zoom_distance_enabled"] = 0,
					["offset_fov"] = 90,
					["offset_fov_zoom_distance_min"] = 7,
					["offset_relative"] = 1,
					["trace_down"] = 0,
					["target_lerp"] = 0.3,
					["offset_lock_z"] = 1,
					["offset_forward"] = -144,
					["nodes_place_enable"] = 0,
					["angles_roll"] = 0,
					["center_offset_up"] = 0,
					["angles_limit"] = 0,
					["movement_rtc_turn_time"] = 0,
					["movement_rtc_enable"] = 0,
					["target_fov"] = 40,
					["center_offset_right"] = 0,
					["hud_black_bars_amount"] = 0,
					["trace_enable"] = 1,
					["target_enable"] = 0,
					["angles_limit_smooth"] = 0,
					["near_z"] = 3,
					["hud_hide_all"] = 0,
					["smoother_fov"] = 40,
					["relative_near_z"] = 0,
				},
			},
			{
				["name"] = "Cinematic 2",
				["description"] = " A cinematic camera",
				["cvars"] = {
					["offset_fov_zoom_distance"] = 1000,
					["smoother_origin"] = 1,
					["nodes_load_by_map_name"] = 0,
					["hud_hide"] = 1,
					["movement_rtc_walk_focus"] = 0,
					["nodes_enable"] = 0,
					["center_offset_forward"] = 0,
					["hud_crosshair_enable"] = 0,
					["hud_black_bars_enable"] = 1,
					["offset_right"] = 0,
					["trace_forward"] = 20,
					["lerp_aim"] = 5,
					["offset_up"] = 0,
					["target_radius"] = 400,
					["smoother_nodes_direction"] = 0,
					["threshold_radius"] = 1000,
					["bone_name"] = "head",
					["hud_crosshair_distance"] = 32000,
					["movement_rtc_yaw_offset"] = 0,
					["angles_pitch"] = 0,
					["angles_roll_amount"] = 15,
					["movement_lock_pitch"] = 0,
					["trace_smooth"] = 1,
					["angles_yaw"] = 0,
					["threshold_enabled"] = 1,
					["nodes_draw"] = 0,
					["nodes_draw_spheres"] = 0,
					["smoother_direction"] = 10,
					["offset_fov_zoom_distance_enabled"] = 1,
					["offset_fov"] = 75,
					["offset_fov_zoom_distance_min"] = 10,
					["offset_relative"] = 1,
					["trace_down"] = 100,
					["target_lerp"] = 15,
					["offset_lock_z"] = 1,
					["offset_forward"] = 0,
					["nodes_place_enable"] = 0,
					["angles_roll"] = 0,
					["center_offset_up"] = 0,
					["angles_limit"] = 1,
					["movement_rtc_turn_time"] = 2.2,
					["movement_rtc_enable"] = 0,
					["target_fov"] = 40,
					["center_offset_right"] = 0,
					["hud_black_bars_amount"] = 1.8,
					["trace_enable"] = 1,
					["target_enable"] = 1,
					["angles_limit_smooth"] = 0,
					["smoother_fov"] = 1,
					["near_z"] = 30,
					["relative_near_z"] = 0,
				},
			},
			{
				["name"] = "Slow",
				["description"] = "A very slow camera",
				["cvars"] = {
					["offset_fov_zoom_distance"] = 1500,
					["smoother_origin"] = 0.2,
					["nodes_load_by_map_name"] = 0,
					["hud_hide"] = 1,
					["movement_rtc_walk_focus"] = 0,
					["nodes_enable"] = 0,
					["center_offset_forward"] = 0,
					["hud_crosshair_enable"] = 1,
					["hud_black_bars_enable"] = 0,
					["offset_right"] = 0,
					["trace_forward"] = 20,
					["lerp_aim"] = 0,
					["offset_up"] = 0,
					["target_radius"] = 700,
					["smoother_nodes_direction"] = 50,
					["threshold_radius"] = 500,
					["bone_name"] = "head",
					["hud_crosshair_distance"] = 32000,
					["movement_rtc_yaw_offset"] = 0,
					["angles_pitch"] = 0,
					["angles_roll_amount"] = 0,
					["movement_lock_pitch"] = 0,
					["trace_smooth"] = 0,
					["angles_yaw"] = 0,
					["threshold_enabled"] = 1,
					["nodes_draw"] = 0,
					["nodes_draw_spheres"] = 0,
					["smoother_direction"] = 5,
					["offset_fov_zoom_distance_enabled"] = 1,
					["offset_fov"] = 75,
					["offset_fov_zoom_distance_min"] = 4,
					["offset_relative"] = 1,
					["trace_down"] = 70,
					["target_lerp"] = 25,
					["offset_lock_z"] = 1,
					["offset_forward"] = 0,
					["nodes_place_enable"] = 0,
					["angles_roll"] = 0,
					["center_offset_up"] = 0,
					["angles_limit"] = 1,
					["movement_rtc_turn_time"] = 10,
					["movement_rtc_enable"] = 0,
					["target_fov"] = 40,
					["center_offset_right"] = 0,
					["hud_black_bars_amount"] = 1.5,
					["trace_enable"] = 1,
					["target_enable"] = 1,
					["angles_limit_smooth"] = 1,
					["smoother_fov"] = 3,
					["near_z"] = 30,
					["relative_near_z"] = 0,
				},
			},
			{
				["name"] = "Cinematic",
				["description"] = " A cinematic camera",
				["cvars"] = {
					["offset_fov_zoom_distance"] = 800,
					["smoother_origin"] = 1,
					["nodes_load_by_map_name"] = 0,
					["hud_hide"] = 1,
					["movement_rtc_walk_focus"] = 0,
					["nodes_enable"] = 0,
					["center_offset_forward"] = 0,
					["hud_crosshair_enable"] = 1,
					["hud_black_bars_enable"] = 0,
					["offset_right"] = 0,
					["trace_forward"] = 20,
					["lerp_aim"] = 100,
					["offset_up"] = 0,
					["target_radius"] = 400,
					["smoother_nodes_direction"] = 50,
					["threshold_radius"] = 400,
					["bone_name"] = "none",
					["hud_crosshair_distance"] = 32000,
					["movement_rtc_yaw_offset"] = 0,
					["angles_pitch"] = 0,
					["angles_roll_amount"] = 0,
					["movement_lock_pitch"] = 0,
					["trace_smooth"] = 1,
					["angles_yaw"] = 0,
					["threshold_enabled"] = 1,
					["nodes_draw"] = 0,
					["nodes_draw_spheres"] = 0,
					["smoother_direction"] = 5,
					["offset_fov_zoom_distance_enabled"] = 0,
					["offset_fov"] = 50,
					["offset_fov_zoom_distance_min"] = 7,
					["offset_relative"] = 1,
					["trace_down"] = 30,
					["target_lerp"] = 100,
					["offset_lock_z"] = 1,
					["offset_forward"] = 0,
					["nodes_place_enable"] = 0,
					["angles_roll"] = 0,
					["center_offset_up"] = 0,
					["angles_limit"] = 1,
					["movement_rtc_turn_time"] = 10,
					["movement_rtc_enable"] = 0,
					["target_fov"] = 40,
					["center_offset_right"] = 0,
					["hud_black_bars_amount"] = 0,
					["trace_enable"] = 1,
					["target_enable"] = 0,
					["angles_limit_smooth"] = 1,
					["smoother_fov"] = 3,
					["near_z"] = 30,
					["relative_near_z"] = 0,
				},
			},
			{
				["name"] = "Helicopter View",
				["description"] = "Only works well in huge open areas",
				["cvars"] = {
					["offset_fov_zoom_distance"] = 1000,
					["smoother_origin"] = 1,
					["nodes_load_by_map_name"] = 0,
					["hud_hide"] = 1,
					["movement_rtc_walk_focus"] = 0,
					["nodes_enable"] = 0,
					["center_offset_forward"] = 0,
					["hud_crosshair_enable"] = 0,
					["hud_black_bars_enable"] = 0,
					["offset_right"] = 0,
					["trace_forward"] = 20,
					["lerp_aim"] = 2,
					["offset_up"] = 0,
					["target_radius"] = 400,
					["smoother_nodes_direction"] = 0,
					["threshold_radius"] = 10000,
					["bone_name"] = "head",
					["hud_crosshair_distance"] = 32000,
					["movement_rtc_yaw_offset"] = 0,
					["angles_pitch"] = 0,
					["angles_roll_amount"] = 0,
					["movement_lock_pitch"] = 0,
					["trace_smooth"] = 1,
					["angles_yaw"] = 0,
					["threshold_enabled"] = 1,
					["nodes_draw"] = 0,
					["nodes_draw_spheres"] = 0,
					["smoother_direction"] = 1,
					["offset_fov_zoom_distance_enabled"] = 1,
					["offset_fov"] = 75,
					["offset_fov_zoom_distance_min"] = 10,
					["offset_relative"] = 1,
					["trace_down"] = 2000,
					["target_lerp"] = 50,
					["offset_lock_z"] = 1,
					["offset_forward"] = 0,
					["nodes_place_enable"] = 0,
					["angles_roll"] = 0,
					["center_offset_up"] = 0,
					["angles_limit"] = 1,
					["movement_rtc_turn_time"] = 2.25,
					["movement_rtc_enable"] = 0,
					["target_fov"] = 40,
					["center_offset_right"] = 0,
					["hud_black_bars_amount"] = 1.75,
					["trace_enable"] = 0,
					["target_enable"] = 0,
					["angles_limit_smooth"] = 0,
					["smoother_fov"] = 2,
					["near_z"] = 30,
					["relative_near_z"] = 0,
				},
			},
			{
				["name"] = "Isometric",
				["description"] = "Isometric view",
				["cvars"] = {
					["offset_fov_zoom_distance"] = 1200,
					["smoother_origin"] = 40,
					["nodes_load_by_map_name"] = 0,
					["hud_hide"] = 1,
					["movement_rtc_walk_focus"] = 0,
					["nodes_enable"] = 0,
					["center_offset_forward"] = 0,
					["hud_crosshair_enable"] = 1,
					["hud_black_bars_enable"] = 0,
					["offset_right"] = 15000,
					["trace_forward"] = 20,
					["lerp_aim"] = 0,
					["offset_up"] = 15000,
					["target_radius"] = 400,
					["smoother_nodes_direction"] = 50,
					["threshold_radius"] = 0,
					["bone_name"] = "none",
					["hud_crosshair_distance"] = 100,
					["movement_rtc_yaw_offset"] = 0,
					["angles_pitch"] = 0,
					["angles_roll_amount"] = 0,
					["movement_lock_pitch"] = 1,
					["trace_smooth"] = 0,
					["angles_yaw"] = 0,
					["threshold_enabled"] = 0,
					["nodes_draw"] = 0,
					["nodes_draw_spheres"] = 0,
					["smoother_direction"] = 10,
					["offset_fov_zoom_distance_enabled"] = 0,
					["offset_fov"] = 0,
					["offset_fov_zoom_distance_min"] = 7,
					["offset_relative"] = 0,
					["trace_down"] = 0,
					["target_lerp"] = 100,
					["offset_lock_z"] = 0,
					["offset_forward"] = 15000,
					["nodes_place_enable"] = 0,
					["angles_roll"] = 0,
					["center_offset_up"] = 0,
					["angles_limit"] = 0,
					["movement_rtc_turn_time"] = 15,
					["movement_rtc_enable"] = 1,
					["target_fov"] = 40,
					["center_offset_right"] = 0,
					["hud_black_bars_amount"] = 0,
					["trace_enable"] = 0,
					["target_enable"] = 0,
					["angles_limit_smooth"] = 0,
					["smoother_fov"] = 40,
					["near_z"] = 30,
					["relative_near_z"] = 1,
				},
			},
			{
				["name"] = "Platformer",
				["description"] = "Isometric view",
				["cvars"] = {
					["offset_fov_zoom_distance"] = 1200,
					["smoother_origin"] = 10,
					["nodes_load_by_map_name"] = 0,
					["hud_hide"] = 1,
					["movement_rtc_walk_focus"] = 0,
					["nodes_enable"] = 0,
					["center_offset_forward"] = 100,
					["hud_crosshair_enable"] = 1,
					["hud_black_bars_enable"] = 0,
					["offset_right"] = 15000,
					["trace_forward"] = 20,
					["lerp_aim"] = 0,
					["offset_up"] = 0,
					["target_radius"] = 400,
					["smoother_nodes_direction"] = 50,
					["threshold_radius"] = 0,
					["bone_name"] = "none",
					["hud_crosshair_distance"] = 100,
					["movement_rtc_yaw_offset"] = 0,
					["angles_pitch"] = 0,
					["angles_roll_amount"] = 0,
					["movement_lock_pitch"] = 1,
					["trace_smooth"] = 0,
					["angles_yaw"] = 0,
					["threshold_enabled"] = 0,
					["nodes_draw"] = 0,
					["nodes_draw_spheres"] = 0,
					["smoother_direction"] = 2,
					["offset_fov_zoom_distance_enabled"] = 0,
					["offset_fov"] = 0,
					["offset_fov_zoom_distance_min"] = 7,
					["offset_relative"] = 0,
					["trace_down"] = 0,
					["target_lerp"] = 100,
					["offset_lock_z"] = 0,
					["offset_forward"] = 0,
					["nodes_place_enable"] = 0,
					["angles_roll"] = 0,
					["center_offset_up"] = 40,
					["angles_limit"] = 0,
					["movement_rtc_turn_time"] = 15,
					["movement_rtc_enable"] = 1,
					["target_fov"] = 40,
					["center_offset_right"] = 0,
					["hud_black_bars_amount"] = 0,
					["trace_enable"] = 0,
					["target_enable"] = 0,
					["angles_limit_smooth"] = 0,
					["smoother_fov"] = 40,
					["near_z"] = 30,
					["relative_near_z"] = 1,
				},
			}
		}
	end

	function ctp:SaveCVarPreset(name, description)

		local tbl = {}

		tbl.name = name
		tbl.description = description or "no description"
		tbl.cvars = {}

		for key, cvar in pairs(self.CVars) do
			if not cvar.dontsave then
				tbl.cvars[key] = cvar.GetVar()
			end
		end

		file.CreateDir("ctp")
		file.CreateDir("ctp/cvar_presets")

		ctp.luadata.WriteFile("ctp/cvar_presets/" .. name .. ".txt", tbl, "DATA")
	end

	function ctp:LoadCVarPreset(name)

		local tbl = self.CurrentPresets[name] or ctp.luadata.ReadFile("ctp/cvar_presets/" .. name .. ".txt")

		if not tbl.cvars then MsgN("CTP tried to load cvar preset '" .. name .. "' but it doesn't exist!") return end

		for key, value in pairs(tbl.cvars) do
			RunConsoleCommand("cl_ctp_" .. key, tostring(value))
		end

		self.CurrentCVarPreset = tbl
	end

	function ctp:GetCurrentCVarPreset()
		return self.CurrentCVarPreset
	end

	function ctp:DeleteCVarPreset(name)
		file.Delete("ctp/cvar_presets/" .. name .. ".txt", "DATA")
	end

	ctp.CurrentPresets = {}

	function ctp:GetCVarPresets(folder)
		folder = folder or "ctp/cvar_presets/"

		local tbl = {}

		local files = file.Find(folder .. "*", "DATA")

		for key, preset in pairs(files) do
			local preset = ctp.luadata.ReadFile(folder .. preset, "DATA")
			if preset.cvars then
				tbl[preset.name] = preset.description ~= "none" and preset.description or ""
				self.CurrentPresets[preset.name] = preset
			end
		end

		for key, preset in pairs(ctp.DefaultPresets) do
			tbl[preset.name] = preset.description ~= "none" and preset.description or ""
			ctp.CurrentPresets[preset.name] = preset
		end

		return tbl
	end

	function ctp:SaveNodePreset(name, description)

		local tbl = {}

		tbl.name = name
		tbl.description = description or "none"
		tbl.nodes = table.Sanitise(self.Nodes)

		file.CreateDir("ctp")
		file.CreateDir("ctp/node_presets")

		ctp.luadata.WriteFile("ctp/node_presets/" .. name .. ".txt", tbl, "DATA")

	end

	function ctp:LoadNodePreset(name)
		local tbl = ctp.luadata.ReadFile(file.Read("ctp/node_presets/" .. name .. ".txt", "DATA"))

		if not tbl.nodes then MsgN("CTP tried to load node preset '" .. name .. "' but it doesn't exist!") return end

		for key, value in pairs(tbl.nodes) do
			table.insert(self.Nodes, value)
		end

		self.CurrentNodePreset = tbl
	end

	function ctp:GetCurrentNodePreset()
		return self.CurrentNodePreset
	end

	function ctp:DeleteNodePreset(name)
		file.Delete("ctp/node_presets/" .. name .. ".txt", "DATA")
	end

	function ctp:GetNodePresets(folder)
		folder = folder or "ctp/node_presets/"

		local tbl = {}

		local files = file.Find(folder .. "*", "DATA")

		for key, preset in pairs(files) do
			local preset = ctp.luadata.ReadFile(folder .. preset, "DATA")
			if preset.nodes then
				tbl[preset.name] = preset.description ~= "none" and preset.description or ""
			end
		end

		return tbl
	end

end

do -- Meta
	AccessorFunc(ctp, "PlayerName", "PlayerName")
	AccessorFunc(ctp, "Player", "Player")

	function ctp:GetPlayer()
		return IsValid(self.Player) and self.Player or LocalPlayer()
	end

	AccessorFunc(ctp, "Origin", "Origin")
	AccessorFunc(ctp, "PrevOrigin", "PrevOrigin")

	-- Max map grid size is 32000, so there's no need for the camera to go outside these boundaries. It also prevents INF and NAN
	function ctp:SetOrigin(a)
		self.Origin = Vector(math.Clamp(a.x, -32000, 32000), math.Clamp(a.y, -32000, 32000), math.Clamp(a.z, -32000, 32000))
	end

	AccessorFunc(ctp, "Direction", "Direction")
	AccessorFunc(ctp, "PrevDirection", "PrevDirection")
	AccessorFunc(ctp, "DesiredDirection", "DesiredDirection")
	function ctp:SetDirection(a)
--[[ 		local info = debug.getinfo(2, "Sln")
		if info then
			Msg(string.format("\t%i: Line %d\t\"%s\"\t%s\n", 0, info.currentline, info.name, info.short_src))
		end ]]
		self.Direction = Vector(math.Clamp(a.x, -1, 1), math.Clamp(a.y, -1, 1), math.Clamp(a.z, -1, 1))
	end



	AccessorFunc(ctp, "Angles", "Angles")
	function ctp:GetAngles()
		return self:GetDirection():Angle()
	end

	function ctp:GetPrevAngles()
		return self:GetPrevDirection():Angle()
	end

	AccessorFunc(ctp, "Roll", "Roll")
	AccessorFunc(ctp, "FOV", "FOV")
	AccessorFunc(ctp, "PrevFOV", "PrevFOV")
	AccessorFunc(ctp, "RelativeOriginSpeed", "RelativeOriginSpeed")

	function ctp:GetFrameTime()
		return math.min(FrameTime(), 0.05)
	end

	function ctp:GetPlayerPos()

		if false and self:GetPlayer():GetVehicle():IsVehicle() then
			local ent = self:GetPlayer():GetVehicle()
			local pos = ent:GetPos() + Vector(0,0,36)

			pos = pos + ((Angle(0, ent:GetAngles().p, 0):Forward() * -self:GetCenterOffsetRight()))
			pos = pos  + ((Angle(0, ent:GetAngles().y, 0):Forward() * self:GetCenterOffsetForward()))
			pos = pos  + ((ent:GetAngles():Up() * self:GetCenterOffsetUp()))

			return pos
		else
			local bone = self:GetBone()
			local pos
			
			if bone == "bottom" then
				pos = self:GetPlayer():GetPos()
			elseif bone == "eyepos" then
				pos = self:GetPlayer():EyePos()
			elseif bone ~= "none" and ctp.BoneList[bone] then
				local id = self:GetPlayer():LookupBone(ctp.BoneList[bone])
				if id then
					pos = self:GetPlayer():GetBonePosition(id)
				end
			end

			if not pos then
				pos = self:GetPlayer():GetPos() + Vector(0,0,36)
			end

			pos = pos + ((Angle(0, self:GetPlayer():EyeAngles().p, 0):Forward() * -self:GetCenterOffsetRight()))
			pos = pos  + ((Angle(0, self:GetPlayer():EyeAngles().y, 0):Forward() * self:GetCenterOffsetForward()))
			pos = pos  + ((self:GetPlayer():EyeAngles():Up() * self:GetCenterOffsetUp()))

			return pos
		end
	end

	function ctp:IsTargeting()
		return self.IsTargeting
	end

	function ctp:IsViewingFromNode()
		return self.NodeView
	end

	function ctp:ResetSmoothers()
		self.SmoothOrigin = self:GetPlayer():EyePos()
		self.SmoothDirection = self:GetPlayer():EyeAngles():Forward()
		self.SmoothFOV = self:GetPlayer():GetFOV()
	end

	function ctp:GetDirectionVelocity()
		return self.DirectionHistory[1] - self.DirectionHistory[self.HistoryCount-1]
	end

	function ctp:GetPlyPosDelta()
		return self.PlyPosHistory[1] - self.PlyPosHistory[self.HistoryCount-1]
	end

	function ctp:GetFOV2()
		local wep = self:GetPlayer():GetActiveWeapon()
		if wep:IsValid() and wep:GetClass() == "gmod_camera" then
			return self:GetPlayer():GetFOV()
		end

		return self.FOV
	end
end

do -- CalcView

	function ctp:CalcView()

		if GetViewEntity() ~= LocalPlayer() then return end

		self:PreCalcView()

		table.insert(self.PlyPosHistory, self:GetPlayer():GetPos())

		if #self.PlyPosHistory > self.HistoryCount then
			table.remove(self.PlyPosHistory, 1)
		end

		local pos = self.Origin
		local ang = self.Direction:Angle() + Angle(-self:GetUserPitch(), self:GetUserYaw(), self:GetUserRoll() + self.Roll)
		local fov = math.Clamp(self:GetFOV2() or 0, 1, 150)

		local tbl =
		{
			origin = pos,
			angles = ang,
			fov = fov,

			znear = math.max(self.CalculatedNearZ or self:GetNearZ(), 0.01),
		}

		return tbl
	end

	function ctp:PreCalcView()

		local ply = LocalPlayer()

		if not self.taunt_cam_hacked and ply.m_CurrentPlayerClass then
			local data = ply.m_CurrentPlayerClass.TauntCam

			if data then
				if data.CreateMove then
					local old = data.CreateMove
					data.CreateMove = function(...)
						if not self:IsEnabled() then
							return old(...)
						end
					end
				end

				if data.ShouldDrawLocalPlayer then
					local old = data.ShouldDrawLocalPlayer
					data.ShouldDrawLocalPlayer = function(...)
						if not self:IsEnabled() then
							return old(...)
						end
					end
				end

				if data.CalcView then
					local old = data.CalcView
					data.CalcView = function(...)
						if not self:IsEnabled() then
							return old(...)
						end
					end
				end

				self.taunt_cam_hacked = true
			end
		end

		self.Origin = self:GetPlayerPos()
		self.Direction = vector_origin
		self.Angles = self:GetPlayer():EyeAngles()
		self.FOV = self:GetFOV()

		if self:IsZoomDistanceEnabled() then
			self:CalcZoomDistance()
		end

		if not self:IsThresholdEnabled() then
			self:CalcOffsets()
		end

		if self:IsThresholdEnabled() then
			self:CalcThreshold()
		end

		self:CalcDirection()

		self:CalcRoll()

		--self:CalcNoise() it doesn't look good

		if self:IsTargettingEnabled() then
			self:CalcTargetting()
		end

---		print(self:IsTraceBlockEnabled(), self:IsTraceBlockSmoothEnabled())
		
		if self:IsRelativeNearZ() then
			local trace_forward = util.TraceHull({
				mins = self:GetPlayer():OBBMins(),
				maxs = self:GetPlayer():OBBMaxs(),
				start = self:GetPlayerPos(),
				endpos = self:GetOrigin(),
				filter = ents.FindInSphere(ply:GetPos(), ply:BoundingRadius() * 4),
			})
			
			if trace_forward.Hit then
				self.CalculatedNearZ = math.max(self:GetOrigin():Distance(trace_forward.HitPos) - self:GetNearZ(), self:GetNearZ())
			else
				self.CalculatedNearZ = nil--self:GetOrigin():Distance(self:GetPlayerPos()) - self:GetNearZ()
			end
		else
			self.CalculatedNearZ = nil
		end
		
		if self:IsTraceBlockEnabled() and not self:IsThresholdEnabled() then
			self:CalcTraceBlock()
		end
				
		if self:GetTraceDown() > 0 then
			self:CalcDownTrace()
		end

		self.NodeView = false

		if self:IsNodesEnabled() then
			self:CalcNodes()
		end

		if self:IsAngleLimitEnabled() and self:IsAngleLimitSmoothEnabled() then
			self:CalcAngleLimit()
		end

		self:CalcShortcuts()

		self:CalcSmoothing()
		
		if self:IsTraceBlockEnabled() and self:IsThresholdEnabled() then
			self:CalcTraceBlock()
		end

		if self:IsAngleLimitEnabled() and not self:IsAngleLimitSmoothEnabled() then
			self:CalcAngleLimit()
		end

		self:CalcDrag()

		self.PrevOrigin = self.Origin
		self.PrevDirection = self.Direction
		self.PrevFOV = self.FOV
	end

	function ctp:CalcZoomDistance()
		self:SetFOV(math.Clamp((-(self:GetPlayerPos() - self:GetPrevOrigin()):Length() + self:GetZoomDistance())  / (self:GetZoomDistance() / 100), self:GetMinZoomDistance(), 75))
	end

	function ctp:CalcOffsets()

		local offset = vector_origin

		if self:IsOffsetRelative() then
			if self:IsZLockEnabled() then
				offset = offset + (self:GetPlayer():EyeAngles():Right() * self:GetRight())
				offset = offset + (self:GetPlayer():EyeAngles():Forward() * self:GetForward())
				offset = offset + (self:GetPlayer():EyeAngles():Up() * self:GetUp())
			else
				offset = offset + (Angle(0, self:GetPlayer():EyeAngles().p, 0):Forward() * -self:GetRight())
				offset = offset + (Angle(0, self:GetPlayer():EyeAngles().y, 0):Forward() * self:GetForward())
				offset = offset + (self:GetPlayer():EyeAngles():Up() * self:GetUp())
			end
		else
			offset = offset + Vector(-self:GetForward(), -self:GetRight(), self:GetUp())
		end

		self:SetOrigin(self:GetOrigin() + offset)

		return offset
	end

	function ctp:CalcDirection(origin)

		local lerp = self:GetAimLerp()/100*2

		local player = ((origin or self:GetPlayerPos()) - self:GetPrevOrigin()):GetNormalized()
		local hitpos = (self:GetPlayer():GetEyeTraceNoCursor().HitPos - self:GetOrigin()):GetNormalized()
		local aim = self:GetPlayer():EyeAngles():Forward()

		local direction = Vector(0, 0, 0)

		if lerp < 1 then
			direction = LerpVector(lerp, player, hitpos)
		else
			direction = LerpVector(lerp - 1, hitpos, aim)
		end

		if false and self:GetPlayer():GetVehicle():IsVehicle() or self:IsViewingFromNode() or self:IsRTCEnabled() and self:IsWalkFocusEnabled() and (self:GetPlayer():KeyDown(IN_MOVELEFT) or self:GetPlayer():KeyDown(IN_MOVERIGHT) or self:GetPlayer():KeyDown(IN_BACK) or self:GetPlayer():KeyDown(IN_FORWARD)) then
			direction = player
		end

		self:SetDirection(direction)

		self:SetDesiredDirection(direction)

	end

	function ctp:CalcRoll()
		self:SetRoll(math.Clamp(WorldToLocal(self:GetPlayer():GetVelocity(), Angle(0, 0, 0), Vector(0, 0, 0), self:GetAngles()).y * (-self:GetRollAmount() / 500), -90, 90))
	end

	function ctp:CalcNoise()
		self.SmoothNoise = self.SmoothNoise or vector_origin

		self.SmoothNoise = LerpVector(self:GetFrameTime() * 0.07, self.SmoothNoise, VectorRand() * (math.random() > 0.95 and 20 or 1))

		self:SetDirection(self:GetDirection() + self.SmoothNoise)
	end

	function ctp:CalcThreshold()
		local distance = self:GetPlayerPos():Distance(self:GetPrevOrigin()) / (self:GetThresholdRadius() * 0.5)

		distance = math.Round(math.Clamp(distance ^ 7-0.2, 0, 1), 5)

		self:SetRelativeOriginSpeed(distance)
	end

	local function FindValueInTable(tbl, target)
		for key, value in pairs(tbl) do
			if string.find(target, value) then
				return true
			end
		end
	end

	local distance = 300

	local function DistanceFromCenter(vec)
		local vec2 = vec:ToScreen()
		return math.Clamp((Vector(ScrW()/2, ScrH()/2, 0) - Vector(vec2.x, vec2.y, 0)):Length2D() / 1000, 0, 1)
	end

	local function CheckAim(vec)
		return ctp:GetPlayer():EyeAngles():Forward():DotProduct((vec - ctp:GetPlayer():EyePos()):GetNormalized())
	end

	function ctp:CalcTargetting()

		local positions = Vector(0, 0, 0)
		local count = 0

		for key, entity in pairs(ents.FindInSphere(self:GetPlayerPos(), self:GetTargetRadius())) do
			if
				entity ~= self:GetPlayer() and
				entity ~= self:GetPlayer():GetVehicle() and
				entity:GetMoveType() == MOVETYPE_VPHYSICS and
				(entity:BoundingRadius() > 30 and
				FindValueInTable(self.AllowedClasses, entity:GetClass())) and
				hook.Call("PhysgunPickup", GAMEMODE, self:GetPlayer(), entity) ~= false
			then
				local point = entity:IsPlayer() and entity:GetShootPos() or entity:OBBCenter() + entity:GetPos()
				--if CheckAim(point) > 0.8 then
					positions = positions + point
					count = count + 1
				--end
			end
		end

		self.IsTargeting = false

		if count == 0 then return end

		self.IsTargeting = true

		local point = positions / count

		local multiplier = math.Clamp((DistanceFromCenter(point) * CheckAim(point)) + 0.5, 0.5, 1)

		self:SetDirection(LerpVector(multiplier * self:GetTargetLerp() / 100, self:GetDirection(), (point - self:GetOrigin()):GetNormalized()))

		self:SetFOV(self:GetTargetFOV() * multiplier)
	end

	--Thanks to ralle for telling me how to do this!
	--I'm kind of hacking the jump it makes by doing a lerp

	function ctp:CalcAngleLimit()

		local pos = self:GetPlayerPos()

		local a1 = self:GetDirection():Angle()
		local a2 = (pos - self:GetPrevOrigin()):Angle()
		local FOV = self:GetFOV2() / 3
		local dir = a2:Forward() *-1

		local dot = math.Clamp(Angle(0, a1.y, 0):Forward():DotProduct(dir), 0, 1)

		a1.p = a2.p + math.Clamp(math.AngleDifference(a1.p, a2.p), -FOV, FOV)
		FOV = FOV / (ScrH()/ScrW())
		a1.y = a2.y + math.Clamp(math.AngleDifference(a1.y, a2.y), -FOV, FOV)

		a1.p = math.NormalizeAngle(a1.p)
		a1.y = math.NormalizeAngle(a1.y)

		self:SetDirection(LerpVector(dot, a1:Forward(), dir * -1))
	end

	function ctp:CalcShortcuts()
		self.IsCTRLE = false
		if self:GetPlayer():KeyDown(IN_WALK) and self:GetPlayer():KeyDown(IN_USE) then
			self:SetOrigin(self:GetPlayerPos() + self:GetPlayer():EyeAngles():Forward() * -150)
			self:SetDirection((self:GetPlayerPos() - self:GetOrigin()):GetNormalized())
			self:SetFOV(75)

			self.SmoothDirection = self:GetDirection()
			self.SmoothOrigin = self:GetOrigin()
			self.SmoothFOV = self:GetFOV2()

			self.IsCTRLE = true
		end
	end

	function ctp:CalcTraceBlock()
		local ply = self:GetPlayer()
		local veh = ply:GetVehicle()

		local filter

		if veh:IsValid() then
			filter = ents.FindInSphere(veh:GetPos(), veh:BoundingRadius() * 4)
		else
			filter = ents.FindInSphere(ply:GetPos(), ply:BoundingRadius() * 4)
		end

		local trace_forward = util.TraceLine({
			start = self:GetPlayerPos(),
			endpos = self:GetOrigin(),
			filter = filter,
		})
				
		if trace_forward.Hit and trace_forward.Entity ~= self:GetPlayer() and not trace_forward.Entity:IsPlayer() and not trace_forward.Entity:IsVehicle() and trace_forward.HitPos:Distance(trace_forward.StartPos) > 0 then
			self:SetOrigin(trace_forward.HitPos + (self:GetDirection() * self:GetTraceForward()))
			if self:IsThresholdEnabled() then
				self.SmoothOrigin = self:GetOrigin()
			end
		end
	end

	function ctp:CalcDownTrace()
		local trace_down = util.QuickTrace(self:GetOrigin(), vector_up * -self:GetTraceDown())

		if trace_down.Hit then
			local origin = self:GetOrigin()
			origin.z = 0
			self:SetOrigin(origin + Vector(0,0,trace_down.HitPos.z + self:GetTraceDown()))
		end
	end

	function ctp:CalcSmoothing()
		if self.IsCTRLE then return end

		if self:IsViewingFromNode() then
			self.SmoothOrigin = self:GetOrigin()
		else
			if self:IsThresholdEnabled() then
				self.SmoothOrigin = LerpVector(self:GetFrameTime() * (self:GetOriginSmoother() / (self:GetThresholdRadius() / 500)) * self:GetRelativeOriginSpeed(), self.SmoothOrigin, self:GetOrigin())
			elseif self:GetOriginSmoother() < 35 then
				self.SmoothOrigin = LerpVector(self:GetFrameTime() * self:GetOriginSmoother(), self.SmoothOrigin, self:GetOrigin())
			else
				self.SmoothOrigin = self:GetOrigin()
			end
		end

		if self:IsViewingFromNode() and self:GetDirectionSmoother() < 35 then
			self.SmoothDirection = LerpVector(self:GetFrameTime() * self:GetDirectionSmoother(), self.SmoothDirection, self:GetDirection())
		elseif not self:IsViewingFromNode() and self:GetDirectionSmoother() < 35 then
			self.SmoothDirection = LerpVector(self:GetFrameTime() * self:GetDirectionSmoother(), self.SmoothDirection, self:GetDirection())
			self.SmoothRoll = Lerp(self:GetFrameTime() * self:GetDirectionSmoother(), self.SmoothRoll, self:GetRoll())
		else
			self.SmoothDirection = self:GetDirection()
		end

		if self:GetFOVSmoother() < 35 then
			self.SmoothFOV = Lerp(self:GetFrameTime() * self:GetFOVSmoother(), self.SmoothFOV, self:GetFOV2())
		else
			self.SmoothFOV = self:GetFOV2()
		end

		self:SetOrigin(self.SmoothOrigin)
		self:SetDirection(self.SmoothDirection)
		self:SetFOV(self.SmoothFOV)
		self:SetRoll(self.SmoothRoll)

	end

end

do -- Dragging
	function ctp:PreventScreenClicks()
		return true
	end

	function ctp:GUIMousePressed(code)
		if self.not_focused then return end

		if code == MOUSE_LEFT then
			self.MousePos = Vector(gui.MousePos())
			self.dragging = true
			self.DragDistance = self:GetOrigin():Distance(self:GetPlayerPos())
		end
		if code == MOUSE_RIGHT then
			self.MouseY = gui.MouseY()
			self.dragzooming = true
		end
	end

	function ctp:GUIMouseReleased()
		self.dragging = false
		self.dragzooming = false
	end

	ctp.CornerDistance = 10
	ctp.MousePos = vector_origin

	local xdelta = 0
	local ydelta = 0

	function ctp:CalcDrag()

		if not vgui.CursorVisible() or (not input.IsMouseDown(MOUSE_LEFT) and not input.IsMouseDown(MOUSE_RIGHT)) then
			xdelta = self:GetAngles().y
			ydelta = self:GetAngles().p
		return end

		if self.dragging then
			xdelta = (xdelta + (self.MousePos.x - gui.MouseX()) / 70)%360
			ydelta = (ydelta + (self.MousePos.y - gui.MouseY()) / 70)%360

			self:SetOrigin(self:GetPlayerPos() + Angle(ydelta, xdelta, 0):Forward() * -self.DragDistance)
			self:SetDirection((self:GetPlayerPos() - self:GetOrigin()):GetNormalized())

			self.SmoothOrigin = self:GetOrigin()
			self.SmoothDirection = self:GetDirection()
		end

		if self.dragzooming then
			self:SetOrigin(self:GetOrigin() + (self:GetDirection() * ((self.MouseY - gui.MouseY()) / 40)))
			self.SmoothOrigin = self:GetOrigin()
		end

	end
end

do -- Nodes

	ctp.Nodes = ctp.Nodes or {}

	function ctp:CreateNode(point, size)
		MsgN("Adding node: " .. tostring(point))
		table.insert(self.Nodes, {size = size or 0, point = point})
	end

	function ctp:RemoveNode(point)
		for key, value in pairs(self.Nodes) do
			if value.point:Distance(point) < 100 then
				MsgN("Removing node: " .. tostring(value))
				self.Nodes[key] = nil
				return true
			end
		end
	end

	ctp.trail_material = Material("cable/redlaser")

	ctp.sphere_model = ClientsideModel("models/XQM/Rails/gumball_1.mdl")
	ctp.sphere_model:SetNoDraw(true)
	ctp.sphere_model:SetMaterial("models/debug/debugwhite")

	ctp.camera_model = ClientsideModel("models/Tools/camera/camera.mdl")
	ctp.camera_model:SetNoDraw(true)

	function ctp:DrawSphere(point, size, color)

		color = color or color_white

		self.sphere_model:SetRenderOrigin(point)
			render.SetBlend(0.2)
				render.SuppressEngineLighting(true)
					render.SetColorModulation(color.r/255, color.g/255, color.b/255)
						render.CullMode(MATERIAL_CULLMODE_CW)
						self.sphere_model:DrawModel()
						render.CullMode(MATERIAL_CULLMODE_CCW)
						self.sphere_model:DrawModel()
					render.SetColorModulation(1, 1, 1)
				render.SuppressEngineLighting(false)
			render.SetBlend(1)
		self.sphere_model:SetupBones()

		self.sphere_model:SetModelScale(1/15*size, 0)
	end

	function ctp:DrawEye(point, color)
		self.camera_model:SetRenderOrigin(point)
		self.camera_model:SetRenderAngles((self:GetPlayer():GetShootPos() - point):Angle())
		render.SetColorModulation(color.r/255, color.g/255, color.b/255)
		render.SuppressEngineLighting(true)
		self.camera_model:DrawModel()
		render.SuppressEngineLighting(false)
		self.camera_model:SetupBones()
	end

	function ctp:PostDrawOpaqueRenderables()
		if self:IsViewingFromNode() then return end

		if self.TempNode then
			local startpos = self.TempNode
			local endpos =  self:GetPlayer():GetEyeTraceNoCursor().HitPos

			render.SetMaterial(self.trail_material)
			render.DrawBeam(startpos, endpos, 10, 0, 1)

			self:DrawSphere(self.TempNode, (startpos-endpos):Length())
			self:DrawEye(self.TempNode, color_white)
		end

		if self:IsDrawingNodesEnabled() or self:IsNodePlacerEnabled() then
			for key, data in pairs(self.Nodes) do
				local color = self:GetPlayer():GetShootPos():Distance(data.point)-1 < data.size and Color(0, 255, 0, 255) or Color(255, 0, 0, 255)
				self:DrawEye(data.point, color)
				if self:IsDrawingNodeSpheresEnabled() then
					self:DrawSphere(data.point, data.size, color)
				end
			end
		end
	end
	hook.Add("PostDrawOpaqueRenderables", "ctp_PostDrawOpaqueRenderables", function() return ctp:PostDrawOpaqueRenderables() end)

	function ctp:CalcNodes()

		if #self.Nodes == 0 then return end

		table.sort(self.Nodes,function(a,b)
			if a and b then return a.point:Distance(self:GetPlayer():EyePos()) < b.point:Distance(self:GetPlayer():EyePos()) end
		end)

		local closest

		for i = 1, #self.Nodes do
			local node = self.Nodes[i]
			if
				node and
				node.point:Distance(self:GetPlayer():EyePos()) < node.size and
				not util.TraceLine{start = node.point, endpos = self:GetPlayer():EyePos()}.HitWorld
			then
				closest = self.Nodes[i]
			break end
		end

		if closest then
			self:SetOrigin(closest.point)
			self:SetDirection((self:GetPlayerPos() - closest.point):GetNormalized())

			self.NodeView = true
		end

	end

	ctp.press_hack = false

	function ctp:KeyPress(ply, key)

		if key == IN_BACK or key == IN_FORWARD or key == IN_MOVELEFT or key == IN_MOVERIGHT then
			self.Walking = true
		end

		if self.press_hack then return end

		if not self:IsNodePlacerEnabled() then return end

		if key == IN_ATTACK then
			self.TempNode = nil

			local trace = util.QuickTrace(self:GetPlayer():GetShootPos(), self:GetPlayer():EyeAngles():Forward() * 32000, self:GetPlayer())
			self.TempNode = trace.HitPos + (trace.HitNormal * 20)
			self:GetPlayer():EmitSound("buttons/button17.wav")
		end

		if key == IN_ATTACK2 then
			self.TempNode = nil

			if self:RemoveNode(self:GetPlayer():GetEyeTraceNoCursor().HitPos) then
				self:GetPlayer():EmitSound("buttons/button16.wav")
			end
		end

		self.press_hack = true
		timer.Create("ctp_PressHack", 0.05, 1, function() self.press_hack = false end)
	end
	hook.Add("KeyPress", "ctp_KeyPress", function(ply, key) ctp:KeyPress(ply, key) end)

	ctp.release_hack = false

	function ctp:KeyRelease(ply, key)

		if key == IN_BACK or key == IN_FORWARD or key == IN_MOVELEFT or key == IN_MOVERIGHT then
			self.Walking = false
		end

		if self.release_hack then return end

		if not self:IsNodePlacerEnabled() then return end

		if self.TempNode and key == IN_ATTACK then
			self:CreateNode(self.TempNode, (self:GetPlayer():GetEyeTraceNoCursor().HitPos - self.TempNode):Length())

			self.TempNode = nil

			self:GetPlayer():EmitSound("buttons/button17.wav")
		end

		self.release_hack = true
		timer.Create("ctp_ReleaseHack", 0.05, 1, function() self.release_hack = false end)
	end
	hook.Add("KeyRelease", "ctp_KeyRelease", function(ply, key) ctp:KeyRelease(ply, key) end)

end

do -- Move

	function ctp:CreateMove(ucmd)
		self.UCMD = ucmd

		if self:IsRTCEnabled() then self:CalcRelativeMovement() end

		--self:MouseToWorld()

		if self:IsLockPitchEnabled() then
			self:GetUCMD():SetViewAngles(Angle(0, self:GetUCMD():GetViewAngles().y, 0))
		end
	end

	function ctp:GetUCMD()
		return self.UCMD or self:GetPlayer():GetCurrentCommand()
	end

	ctp.smooth_yaw = 0
	ctp.moved_behind = false
	ctp.pitch = 0
	ctp.angle = Angle(0,0,0)

	function ctp:CalcRelativeMovement()
		local cmd = self:GetUCMD()

		if self.Walking and self:IsViewingFromNode() then
			self.TempYaw = self.smooth_yaw
		end

		if self:GetPlayer():KeyPressed(IN_BACK) then
			moved_behind = false
		end

		if self:GetPlayer():KeyDown(IN_BACK) then
			self.angle = (self:GetPrevAngles():Forward() *-1):Angle()
		end

		if self:GetPlayer():KeyDown(IN_FORWARD) or moved_behind then
			self.angle = self:GetPrevAngles():Forward():Angle()
		end

		if self:GetPlayer():KeyDown(IN_MOVELEFT) then
			self.angle = (self:GetPrevAngles():Right() *-1):Angle()
		end

		if self:GetPlayer():KeyDown(IN_MOVERIGHT) then
			self.angle = self:GetPrevAngles():Right():Angle()
		end

		self.pitch = math.Clamp(self.pitch + (cmd:GetMouseY() / (self:GetPlayer():GetInfo("sensitivity") * self:GetPlayer():GetInfo("m_pitch") < 0 and -50 or 50)),-89,89)
		self.smooth_yaw = math.ApproachAngle(self.smooth_yaw, self.angle.y, self:GetRTCTurnTime())

		if self:GetPlayer():KeyDown(IN_MOVELEFT) or self:GetPlayer():KeyDown(IN_MOVERIGHT) or self:GetPlayer():KeyDown(IN_BACK) or self:GetPlayer():KeyDown(IN_FORWARD) then
			cmd:SetForwardMove(1000)
			cmd:SetSideMove(0)

			if self:GetPlayerPos():Distance(self:GetPrevOrigin()) < 10 and self:GetPlayer():KeyDown(IN_BACK) then
				self.moved_behind = true
			end

			if moved_behind and self:GetPlayer():KeyDown(IN_FORWARD) then
				self.moved_behind = false
			end

			local ang = Angle(math.NormalizeAngle(self.pitch), math.NormalizeAngle(self.smooth_yaw+self:GetRTCYawOffset()), 0)
			cmd:SetViewAngles(ang)
		end
	end

end

do -- HUD

	function ctp:HUDPaint()
		if self:IsAllHUDHidden() then
			return false
		end
	end

	function ctp:HUDPaintBackground()
		if self:IsCrosshairEnabled() then
			self:DrawCrosshair()
		end

		if self:IsBlackBarsEnabled() then
			self:DrawBlackBars()
		end

	end

	function ctp:DrawBlackBars()

		local amount = (-self:GetFOV2() + 75) * self:GetBlackBarAmount()

		surface.SetDrawColor(0, 0, 0, 255)

		surface.DrawRect(0, -1, ScrW(), amount)
		surface.DrawRect(0, ScrH()-amount+1, ScrW(), amount)

	end

	function ctp:DrawCrosshair()

		local weapon = self:GetPlayer():GetActiveWeapon()
		local trace = util.QuickTrace(self:GetPlayer():GetShootPos(), self:GetPlayer():EyeAngles():Forward() * (IsValid(weapon) and weapon:GetClass() == "weapon_physgun" and math.min(self:GetCrosshairDistance(), 2500) or self:GetCrosshairDistance()), self:GetPlayer())

		local vec2 = trace.HitPos:ToScreen()

		if util.TraceLine({start = self:GetPrevOrigin(), endpos = trace.HitPos}).Fraction < 0.96 then
			surface.SetDrawColor(255, 100, 100, 255)
		else
			surface.SetDrawColor(255, 255, 255, 255)
		end

		local distance = 9 --* (-(trace.StartPos:Distance(trace.HitPos) / self:GetCrosshairDistance()) + 1)

		--EpoePrint(distance)
		local fatness = 2

		surface.DrawRect(vec2.x, vec2.y, fatness, fatness)

		surface.DrawRect(vec2.x, vec2.y + distance, fatness, fatness)
		surface.DrawRect(vec2.x, vec2.y - distance, fatness, fatness)

		surface.DrawRect(vec2.x + distance, vec2.y, fatness, fatness)
		surface.DrawRect(vec2.x - distance, vec2.y, fatness, fatness)
	end

	function ctp:HUDShouldDraw(element)
		if element == "CHudCrosshair" then
			return false
		end

		if self:IsHUDHidden() and table.HasValue(self.DisabledElements, element) then
			return false
		end
	end

end

do -- Mouse To World
	function ctp:MouseToWorld()
		local eye = self:GetPrevAngles()
		local fov = self:GetPrevFOV()
		local mousex = gui.MouseX()
		local mousey = gui.MouseY()
		local screenwidth = ScrW()
		local screenheight = ScrH()

		local yaw = eye.y+fov/2-(mousex/screenwidth)*fov
		local pitch = eye.p-(fov/2-(mousey/screenheight)*fov)*screenheight/screenwidth

		local hitpos = util.QuickTrace(self:GetPrevOrigin(), Angle(pitch, yaw, 0):Forward() * 1000, ply).HitPos

		--print(hitpos:Distance(self:GetPlayerPos()))

		debugoverlay.Cross(hitpos, 100, 0.1)

		return hitpos
	end

end

do --Misc hooks
	function ctp:PlayerStepSoundTime(ply, type, running)
		if ply ~= self:GetPlayer() then return end

		local running = self:GetPlayer():KeyDown(IN_SPEED)
		local walking = self:GetPlayer():KeyDown(IN_WALK)
		local sideways = not self:IsRTCEnabled() and (self:GetPlayer():KeyDown(IN_MOVELEFT) or self:GetPlayer():KeyDown(IN_MOVERIGHT))
		local forward = self:GetPlayer():KeyDown(IN_FORWARD)
		local back = not self:IsRTCEnabled() and self:GetPlayer():KeyDown(IN_BACK)

		local time = 240

		if running then
			time = 140
			if sideways then
				time = 200
			end
		end
		if walking then
			time = 285
			if forward then
				time = 390
			end
			if back then
				time = 330
			end
		end
		if sideways and not forward then
			time = time * 0.75
		end

		if not walking and not running and back then
			time = 200
		end

		return time
	end
end

ctp:Initialize()

hook.Add("InitPostEntity", "ctp_InitPostEntity", function() ctp:Initialize() end)

do -- GUI

	ctp.Spacing = 7

	ctp.FormFont = "DermaDefault"

	do -- ctp_Preset
		local PANEL = vgui.Register("ctp_Preset", {}, "DPanel")

		function PANEL:Init()
			self.choice = vgui.Create("DComboBox", self)

			self.choice.OnCursorEntered = function()
				self.choice:RequestFocus()
			end

			self.choice.OnCursorExited = function()
				self.choice:KillFocus()
			end

			self.choice.OnSelect = function(_,_,value)
				self.presetname = value

				self.currentdata = self:GetType() == "cvar" and ctp:GetCVarPresets()[value] or self:GetType() == "nodes" and ctp:GetNodePresets()[value]

				if self.currentdata then
					self.choice:SetTooltip(self.currentdata)
				else
					self.choice:SetTooltip([[This preset has no description.
					You can make a description by typing it after a semicolon like so:
					valve thirdperson;this is just like the valve thirdperson camera!
					where the everything before " ; " is the name and everything after is the description]])
				end

				ctp:LoadCVarPreset(self.presetname)
			end

			self.save = vgui.Create("DButton", self)
			self.save:SetText("S")
			self.save:NoClipping(true)
			self.save:SetTooltip("Save")
			self.save.DoClick = function()
				--MsgN("Saving preset '" .. self.choice:GetValue() .. "'")

				Derma_StringRequest("filename", "enter the filename", self.presetname or "", function(str)
					local name, description = unpack(string.Explode(";", str))
					description = description or self.currentdata
					if self:GetType() == "cvar" then
						ctp:SaveCVarPreset(name, description)
					elseif self:GetType() == "nodes" then
						ctp:SaveNodePreset(name, description)
					end
					self.choice:Clear()
					self:Refresh()
				end)
			end

			self.delete = vgui.Create("DButton", self)
			self.delete:SetText("X")
			self.delete:NoClipping(true)
			self.delete:SetTooltip("Delete")
			self.delete.DoClick = function()
				if self.presetname then
					MsgN("Deleting preset '" .. self.presetname .. "'")
					if self:GetType() == "cvar" then
						ctp:DeleteCVarPreset(self.presetname)
					elseif self:GetType() == "nodes" then
						ctp:DeleteNodePreset(self.presetname)
					end
					self.choice:Clear()
					self:Refresh()
				end
			end

		end

		AccessorFunc(PANEL, "Type", "Type")

		function PANEL:Refresh()

		end

		function PANEL:AddTable(tbl)
			for name, description in pairs(tbl) do
				self.choice:AddChoice(name, description ~= "" and description)
				if self:GetType() == "cvar" and ctp:GetCurrentCVarPreset() and ctp:GetCurrentCVarPreset().name == name then
					self.choice:ChooseOption(name)
				elseif self:GetType() == "nodes" and ctp:GetCurrentNodePreset() and ctp:GetCurrentNodePreset().name == name  then
					self.choice:ChooseOption(name)
				end
			end
		end

		function PANEL:PerformLayout()
			self.delete:SetWide(20)
			self.delete:AlignTop(ctp.Spacing)
			self.delete:AlignRight(ctp.Spacing)
			self.delete:SetTall(self:GetTall() - (ctp.Spacing * 2))

			self.save:SetWide(20)
			self.save:AlignTop(ctp.Spacing)
			self.save:MoveLeftOf(self.delete, ctp.Spacing)
			self.save:SetTall(self:GetTall() - (ctp.Spacing * 2))

			self.choice:AlignTop(ctp.Spacing)
			self.choice:AlignLeft(ctp.Spacing)
			self.choice:StretchRightTo(self.save, ctp.Spacing)
			self.choice:SetTall(self:GetTall() - (ctp.Spacing * 2))

		end
	end

	do -- ctp_Slider
		local PANEL = vgui.Register("ctp_Slider", {}, "DNumSlider")

		function PANEL:Init()
			self:CopyHeight(self.Wang)

			self.Slider:SetTall(13)

			self:SetDecimals(1)
		end

		function PANEL:PerformLayout()
			self.Label:SetPos(0, 0)
			self.Label:CenterVertical()
			self.Label:SizeToContents()

			self.Wang:SizeToContents()
			self.Wang:SetWide(10)
			self.Wang:SetPos(0, 0)
			self.Wang:AlignRight(0)

			self.Slider:CenterVertical()
			self.Slider:MoveRightOf(self.Wang, ctp.Spacing)
			self.Slider:SetWide(self:GetParent():GetWide() - ctp.Spacing)
			self.Slider:SetSlideX(self.Wang:GetFraction())
		end

		function PANEL:SetText(str)
			DNumSlider.SetText(self, str)

			self.Label:SizeToContents()
			self:InvalidateLayout()
		end
	end

	do -- ctp_VectorSliders
		local PANEL = vgui.Register("ctp_VectorSliders", {}, "DForm")

		function PANEL:Init()
			self.xslider = vgui.Create("ctp_Slider", self)
			self:AddItem(self.xslider)

			self.yslider = vgui.Create("ctp_Slider", self)
			self:AddItem(self.yslider)

			self.zslider = vgui.Create("ctp_Slider", self)
			self:AddItem(self.zslider)

			self.reset = vgui.Create("DButton", self)
			self.reset:SetText("reset")
			self:AddItem(self.reset)

			self.BaseClass.Init(self)
		end

		function PANEL:SetText(title, x, y, z, tooltip)
			self:SetName(title)
			self.xslider:SetText(x)
			self.yslider:SetText(y)
			self.zslider:SetText(z)

			self:SetTooltip(tooltip)
		end

		function PANEL:SetMinMax(xmin, xmax, ymin, ymax, zmin, zmax)
			self.xslider:SetMin(not xmax and -xmin or xmin)
			self.xslider:SetMax(xmax or xmin)

			self.yslider:SetMin(ymin or -xmin)
			self.yslider:SetMax(ymax or xmin)

			self.zslider:SetMin(zmin or -xmin)
			self.zslider:SetMax(zmax or xmin)
		end

		function PANEL:SetCVars(x, y, z)
			x = "cl_ctp_" .. x
			y = "cl_ctp_" .. y
			z = "cl_ctp_" .. z

			self.xslider:SetConVar(x)
			self.yslider:SetConVar(y)
			self.zslider:SetConVar(z)

			self.reset.DoClick = function()
				RunConsoleCommand(x, 0)
				RunConsoleCommand(y, 0)
				RunConsoleCommand(z, 0)
			end
		end
	end

	do -- ctp_MainFrame

		local NumSlider = function(self, strLabel, strConVar, numMin, numMax, dec)
			local left = vgui.Create( "ctp_Slider", self )
			left:SetText( strLabel )
			left:SetMinMax( numMin, numMax )
			if dec then left:SetDecimals(dec) end

			left:SetConVar(strConVar)
			left:SizeToContents()

			self:AddItem(left, nil)

			return left
		end

		do -- ctp_SheetBase
			local PANEL = vgui.Register("ctp_SheetBase", {}, "DPanelList")

			function PANEL:Init()
				self:EnableHorizontal(false)
				self:EnableVerticalScrollbar(true)
				self:SetPadding(ctp.Spacing)
				self:SetSpacing(ctp.Spacing)

				self:Rebuild()
			end

			function PANEL:Paint(w, h)
				derma.SkinHook("Paint", "Tree", self, w, h)
			end
		end

		do -- ctp_SheetOrigin
			local PANEL = vgui.Register("ctp_SheetOrigin", {}, "ctp_SheetBase")

			function PANEL:Init()
				self.offset = vgui.Create("ctp_VectorSliders", self)
					self:AddItem(self.offset)
					self.offset:SetMinMax(1000)
					self.offset:SetCVars("offset_right", "offset_forward", "offset_up")
					self.offset:SetText("Offset", "X", "Y", "Z",
						[[This controls the camera offset.
						It can be relative to player position or world position.]]
					)

				self.trace = vgui.Create("DForm", self)
					self:AddItem(self.trace)
					self.trace:SetName("Trace Block")
					self.trace.NumSlider = NumSlider

					self.trace:CheckBox("Enable Forward", "cl_ctp_trace_enable"):SetTooltip(
					[[Enables the trace block which will move the camera forward if
					something is in the way of the player and the camera]])

					-- self.trace:CheckBox("Smooth", "cl_ctp_trace_smooth"):SetTooltip(
					-- [[If this is checked, it will obey the position smoother]])

					self.trace:NumSlider("Forward", "cl_ctp_trace_forward", -100, 100, 2):SetTooltip(
					[[This is the how much forward the camera will go from the blocking point]])

					self.trace:NumSlider("Down Trace Length", "cl_ctp_trace_down", 0, 500, 2):SetTooltip(
					[[This will keep the camera from going too close to the ground.
					For instance if it's at 100, it will keep itself 100 units from ground]])

				self.threshold = vgui.Create("DForm", self)
					self:AddItem(self.threshold)
					self.threshold:SetName("Threshold")
					self.threshold.NumSlider = NumSlider

					self.threshold:CheckBox("Enable", "cl_ctp_threshold_enabled"):SetTooltip(
					[[If this is checked, the camera will stop following when it reaches the radius given]])

					self.threshold:NumSlider("Radius", "cl_ctp_threshold_radius", 0, 2000, 0):SetTooltip(
					[[This is the radius of the threshold camera.]])

				self.misc = vgui.Create("DForm", self)
					self:AddItem(self.misc)
					self.misc:SetName("Misc")
					self.misc.NumSlider = NumSlider

					self.misc:CheckBox("Relative to player", "cl_ctp_offset_relative"):SetTooltip(
					[[If this is off the camera won't follow player angles.
					It's like mayamode in Valve's thirdperson camera]])

					self.misc:CheckBox("Follow pitch", "cl_ctp_offset_lock_z"):SetTooltip(
					[[If this is off, the camera won't follow the player's pitch.
					In other words the camera won't go up and down]])

					self.misc:NumSlider("Near Z", "cl_ctp_near_z", 1, 50, 1):SetTooltip(
					[[The higher this is the less flickering you will see. This is very useful for addons like PAC.]])
					
					self.misc:CheckBox("Relative Near Z", "cl_ctp_relative_near_z"):SetTooltip(
					[[Makes the near z plane be relative to player]])

				self.BaseClass.Init(self)
			end
		end

		do -- ctp_SheetDirection
			local PANEL = vgui.Register("ctp_SheetDirection", {}, "ctp_SheetBase")

			function PANEL:Init()
				self.aim = vgui.Create("DForm", self)
					self:AddItem(self.aim)
					self.aim:SetName("Aim")
					self.aim.NumSlider = NumSlider

					self.aim:NumSlider("Lerp Aim", "cl_ctp_lerp_aim", 0, 100, 2):SetTooltip(
					[[This makes a lerp (blend) between what to aim at.
					0 = player
					50 = what the player sees
					100 the players aim]])

					self.aim:NumSlider("Zoom", "cl_ctp_offset_fov", 0, 150, 2):SetTooltip(
					[[The amount of zoom the camera should do]])

					self.aim:NumSlider("Roll Amount", "cl_ctp_angles_roll_amount", -100, 100, 2):SetTooltip(
					[[This will make the camera roll based on the player's side velocity.
					It obeys direction stiffness]])

				self.zoomdistance = vgui.Create("DForm", self)
					self:AddItem(self.zoomdistance)
					self.zoomdistance:SetName("Zoom Distance")
					self.zoomdistance.NumSlider = NumSlider

					self.zoomdistance:CheckBox("Enable", "cl_ctp_offset_fov_zoom_distance_enabled"):SetTooltip(
					[[Enabling this will make the camera zoom in further based on how far the player is from the camera]])

					self.zoomdistance:NumSlider("Distance", "cl_ctp_offset_fov_zoom_distance", 0, 5000, 0):SetTooltip(
					[[The distance for when it should start zooming in]])

					self.zoomdistance:NumSlider("Minimum Zoom", "cl_ctp_offset_fov_zoom_distance_min", 0, 75, 0):SetTooltip(
					[[The minimum distance for distance zooming]])

				self.angles = vgui.Create("ctp_VectorSliders", self)
					self:AddItem(self.angles)
					self.angles:SetMinMax(180)
					self.angles:SetCVars("angles_pitch", "angles_yaw", "angles_roll")
					self.angles:SetText("Angle Offset", "P", "Y", "R",
					[[This controls the angle offset.]])

				self.angleslimit = vgui.Create("DForm", self)
					self:AddItem(self.angleslimit)
					self.angleslimit:SetName("Angle Limit")

					self.angleslimit:CheckBox("Enable", "cl_ctp_angles_limit"):SetTooltip(
					[[Turning this on will make it so the camera tries not to aim away
					from the player	thus making the player always visible. (well it will try to)]])

					self.angleslimit:CheckBox("Smooth", "cl_ctp_angles_limit_smooth"):SetTooltip(
					[[Enabling this will make the angle limit obey direction smoothness]])

				self.BaseClass.Init(self)
			end

		end

		do -- ctp_SheetMisc
			local PANEL = vgui.Register("ctp_SheetMisc", {}, "ctp_SheetBase")

			function PANEL:Init()
				self.player = vgui.Create("DForm")
					self:AddItem(self.player)
					self.player:SetName("Player")

					local entry = self.player:TextEntry("Player Name", "_")
					entry:SetTooltip(
					[[Type in the player's name partially here to change the player used for thirdperson.
					The camera needs to be retoggled.
					To use self, leave blank.]])
					entry.OnEnter = function()
						ctp:SetPlayer(FindPlayerByName(entry:GetValue()))
					end
					entry.OnTextChanged = entry.OnEnter
					ctp.__player_text_entry = entry

					local ply = ctp:GetPlayer()
					if ply:IsPlayer() then
						entry:SetValue(ply:Nick())
					end

					entry.UpdateConvarValue = function() end


				self.smoothers = vgui.Create("DForm")
					self:AddItem(self.smoothers)
					self.smoothers:SetName("Stiffness")
					self.smoothers.NumSlider = NumSlider

					self.smoothers:NumSlider("Position", "cl_ctp_smoother_origin", 0, 40, 2):SetTooltip(
					[[Low values equal slow movement, while high values equal fast movement]])

					self.smoothers:NumSlider("Aim", "cl_ctp_smoother_direction", 0, 40, 2):SetTooltip(
					[[Low values equal slow movement, while high values equal fast movement]])

					self.smoothers:NumSlider("Zoom", "cl_ctp_smoother_fov", 0, 40, 2):SetTooltip(
					[[Low values equal slow movement, while high values equal fast movement]])

				self.center = vgui.Create("ctp_VectorSliders", self)
					self:AddItem(self.center)
					self.center:SetMinMax(300)
					self.center:SetCVars("center_offset_right", "center_offset_forward", "center_offset_up")
					self.center:SetText("Center Offset", "X", "Y", "Z",
					[[This controls where the center of the player is for the camera.]])

					local choice = self.center:ComboBox("Bone", "cl_ctp_bone_name")
					self:AddItem(self.misc)

					choice:SetTooltip([[This controls the bone the camera will think where the
					player is.]])

					for key in SortedPairs(ctp.BoneList) do
						choice:AddChoice(key)
					end

					choice:ChooseOption(GetConVarString("cl_ctp_bone_name"))

				self.target = vgui.Create("DForm")
					self:AddItem(self.target)
					self.target:SetName("Targetting")
					self.target.NumSlider = NumSlider

					self.target:CheckBox("Enable", "cl_ctp_target_enable"):SetTooltip(
					[[Targetting makes it so the camera target props, players and npcs
					If it finds more than one target it will get the center of all found targets
					It's a cinematic effect]])

					self.target:NumSlider("Radius", "cl_ctp_target_radius", 0, 3000, 0):SetTooltip(
					[[The search radius for finding targets]])

					self.target:NumSlider("Blend", "cl_ctp_target_lerp", 0, 100, 2):SetTooltip(
					[[A blend between target and normal aim.

					0 = aim
					100 = target

					so 50 would be in between]])

					self.target:NumSlider("FOV", "cl_ctp_target_fov", 0, 150, 2):SetTooltip(
					[[When targetting is on, it will zoom by this amount]])

				self.rtc = vgui.Create("DForm")
					self:AddItem(self.rtc)
					self.rtc:SetName("Relative Movement")
					self.rtc.NumSlider = NumSlider

					self.rtc:CheckBox("Enable", "cl_ctp_movement_rtc_enable"):SetTooltip(
					[[This will make it so you automatically turn relatively to the camera angle]])

					self.rtc:CheckBox("Lock Pitch", "cl_ctp_movement_lock_pitch"):SetTooltip(
					[[This will constantly make your pitch 0]])

					self.rtc:CheckBox("Walk Focus", "cl_ctp_movement_rtc_walk_focus"):SetTooltip(
					[[Enabling this will make the camera aim at the player when walking]])

					self.rtc:NumSlider("Yaw Offset", "cl_ctp_movement_rtc_yaw_offset", -180, 180, 2):SetTooltip(
					[[Offsets the yaw by this angle]])

					self.rtc:NumSlider("Turn Time", "cl_ctp_movement_rtc_turn_time", 0, 15, 3):SetTooltip(
					[[Makes it so you turn this much per frame. Lower is slower, higher is faster.]])

				self.nodes = vgui.Create("DForm")
					self:AddItem(self.nodes)
					self.nodes:SetName("Nodes")
					self.nodes.NumSlider = NumSlider

					self.preset = vgui.Create("ctp_Preset")
					self.preset:SetType("nodes")
					self.preset:SetTall(35)
					self.nodes:AddItem(self.preset)
					self.preset:AddTable(ctp:GetNodePresets())
					self.preset.Refresh = function()
						self.preset:AddTable(ctp:GetNodePresets())
					end

					local button = vgui.Create("DButton")

					button:SetText("Clear Nodes")
					button.DoClick = function()
						ctp.Nodes = {}
					end

					self.nodes:AddItem(button)

					self.nodes:CheckBox("Enable", "cl_ctp_nodes_enable"):SetTooltip(
					[[This will enable node cameras. Node cameras are nodes ctp will switch to
					when you are close and seeable by them. It's kind of like silent hill.
					]])

					self.nodes:NumSlider("Stiffness", "cl_ctp_smoother_nodes_direction", 0, 40, 3):SetTooltip(
					[[Makes it so you turn this much per frame. Lower is slower, higher is faster.]])


					self.nodes:CheckBox("Auto Load", "cl_ctp_nodes_load_by_map_name"):SetTooltip(
					[[This will make it so it tries to load a node preset with the same name as the map
					so if you were on gm_construct it would try to load a node preset called "gm_construct" automatically]])

					self.nodes:CheckBox("Enable Placer", "cl_ctp_nodes_place_enable"):SetTooltip(
					[[This enables placing of nodes.
					To Create a node press and hold primary attack, drag it to a desired radius and release.

					to remove a node press secondary attack near the node]])

					self.nodes:CheckBox("Draw Cameras", "cl_ctp_nodes_draw"):SetTooltip(
					[[Draws the node cameras]])

					self.nodes:CheckBox("Draw Spheres", "cl_ctp_nodes_draw_spheres"):SetTooltip(
					[[Draws the radius spheres from the node cameras]])

				self.hud = vgui.Create("DForm")
					self:AddItem(self.hud)
					self.hud:SetName("HUD")
					self.hud.NumSlider = NumSlider

					self.hud:CheckBox("Hide", "cl_ctp_hud_hide"):SetTooltip(
					[[Hides uneeded hud elements. Good for machinimas]])

					self.hud:CheckBox("Hide All", "cl_ctp_hud_hide_all"):SetTooltip(
					[[Hides all hud elements.]])

					self.hud:CheckBox("Crosshair", "cl_ctp_hud_crosshair_enable"):SetTooltip(
					[[Draws a crosshair]])

					self.hud:NumSlider("Crosshair Distance", "cl_ctp_hud_crosshair_distance", 0, 32000, 2):SetTooltip(
					[[The distance of the crosshair from the player in units]])

					self.hud:CheckBox("Black Bars", "cl_ctp_hud_black_bars_enable"):SetTooltip(
					[[Enables black bars which are tied to zoom]])

					self.hud:NumSlider("Black Bars Amount", "cl_ctp_hud_black_bars_amount", 0, 5, 4):SetTooltip(
					[[Controls how much the black bars should lower with zoom]])


				self.BaseClass.Init(self)
			end

		end

		do -- MainFrame
			local PANEL = vgui.Register("ctp_MainFrame", {}, "DFrame")

			function PANEL:Init()

				ctp.DraggingAllowed = false

				self.preset = vgui.Create("ctp_Preset", self)
				self.preset:SetType("cvar")
				self.preset:AddTable(ctp:GetCVarPresets())
				self.preset.Refresh = function()
					self.preset:AddTable(ctp:GetCVarPresets())
				end


				self.enable = vgui.Create("DButton", self)
				self.enable:SetText("Toggle")
				self.enable.DoClick = function()
					ctp:Toggle()
				end

				self.sheet = vgui.Create("DPropertySheet", self)
				self.sheet:SetShowIcons(false)

				self.sheet:AddSheet(
					"Position",
					vgui.Create("ctp_SheetOrigin", self),
					nil,
					false,
					false,
					"This sheet is for controlling the position offsets such as where the camera is oriented around the player"
				)

				self.sheet:AddSheet(
					"Aim",
					vgui.Create("ctp_SheetDirection", self),
					nil,
					false,
					false,
					"This sheet is for controlling the aim settings such as where the camera is pointing or/and at what"
				)

				self.sheet:AddSheet(
					"Misc",
					vgui.Create("ctp_SheetMisc", self),
					nil,
					false,
					false,
					"This sheet is for misc options"
				)

				hook.Add("GUIMousePressed", "ctp_gui_GUIMousePressed", function(code)
					local x, y = self:LocalToScreen()

					if
						(
							x + self:GetWide() < gui.MouseX() or
							y + self:GetTall() < gui.MouseY() or
							gui.MouseX() < x or
							gui.MouseY() < y
						) and
						code == MOUSE_LEFT and
						not ctp.not_focused
					then
						self:KillFocus()
						self:SetMouseInputEnabled(false)
						self:SetKeyBoardInputEnabled(false)
						gui.EnableScreenClicker(false)
						ctp.not_focused = true
						self:AlphaTo(50, 0.1, 0)

						self.allowclick = false

						timer.Simple(0.2, function()
							self.allowclick = true
							ctp.DraggingAllowed = true
						end)

					end
				end)

				hook.Add("StartChat", "ctp_StartChat", function()
					self.ChatEnabled = true
				end)

				hook.Add("FinishChat", "ctp_FinishChat", function()
					timer.Simple(0.1, function() self.ChatEnabled = false end)
				end)

				self.fixbutton = vgui.Create("DButton", self)
				self.fixbutton.DoClick = function ()
					self:SetSize(250, 400)
					self:SetSizable(true)
					self:AlignTop(ctp.Spacing)
					self:AlignRight(ctp.Spacing)
					self:SetTall(ScrH() - (ctp.Spacing * 2))
				end
				self.fixbutton:SetDrawBorder(false)
				self.fixbutton:SetDrawBackground(false)
				self.fixbutton:SetTooltip("Defaults the window position and size")

				self.fixbutton:SetSize(15, 15)
				self.btnClose:SetSize(15, 15)

				self:SetSize(250, 400)
				self:SetSizable(true)
				self:AlignTop(ctp.Spacing)
				self:AlignRight(ctp.Spacing)
				self:SetTall(ScrH() - (ctp.Spacing * 2))
				self:SetTitle("CTP Options")
				self:MakePopup()

				self:SetCookieName("ctp_OptionsMenu")

				local x = self:GetCookieNumber("x")
				local y = self:GetCookieNumber("y")
				local w = self:GetCookieNumber("w")
				local h = self:GetCookieNumber("h")

				if x and y and w and h then
					self:SetPos(x,y)
					self:SetWide(w,h)
				end

			end

			function PANEL:PerformLayout()
				DFrame.PerformLayout(self)
				self.sheet:StretchToParent(ctp.Spacing, ctp.Spacing + 90, ctp.Spacing, ctp.Spacing)

				self.enable:MoveAbove(self.sheet, ctp.Spacing)
				self.enable:StretchBottomTo(self.sheet, ctp.Spacing)
				self.enable:AlignLeft(ctp.Spacing)
				self.enable:CopyWidth(self.sheet)

				self.preset:CopyWidth(self.sheet)
				self.preset:AlignTop(ctp.Spacing + 20)
				self.preset:AlignLeft(ctp.Spacing)
				self.preset:StretchBottomTo(self.enable, ctp.Spacing)

				self.fixbutton:AlignTop(2)
				self.fixbutton:MoveLeftOf(self.btnClose, ctp.Spacing)
			end

			function PANEL:Close()
				local x,y = self:GetPos()

				self:SetCookie("x", x)
				self:SetCookie("y", y)
				self:SetCookie("w", self:GetWide())
				self:SetCookie("h", self:GetTall())

				hook.Remove("GUIMousePressed", "ctp_gui_GUIMousePressed")
				hook.Remove("StartChat", "ctp_StartChat")
				hook.Remove("FinishChat", "ctp_FinishChat")

				ctp.DraggingAllowed = true

				self:Remove()
			end

			function PANEL:Think()
				DFrame.Think(self)

				if self.allowclick and ctp.not_focused and vgui.CursorVisible() and not self.ChatEnabled then
					self:MakePopup()
					ctp.not_focused = false
					self:AlphaTo(255, 0.1, 0)
					ctp.DraggingAllowed = false
				end
			end
		end

		do -- ContextMenu
			local PANEL = vgui.Register("ctp_ContextMenu", {}, "DPanel")

			function PANEL:Init()
				self.preset = vgui.Create("ctp_Preset", self)
				self.preset:SetType("cvar")
				self.preset:AddTable(ctp:GetCVarPresets())
				self.preset.Refresh = function()
					self.preset:AddTable(ctp:GetCVarPresets())
				end


				self.enable = vgui.Create("DButton", self)
				self.enable:SetText("Toggle Thirdperson")
				self.enable.DoClick = function()
					ctp:Toggle()
				end

				self.sheet = vgui.Create("DPropertySheet", self)
				self.sheet:SetShowIcons(false)

				self.sheet:AddSheet(
					"Position",
					vgui.Create("ctp_SheetOrigin", self),
					nil,
					false,
					false,
					"This sheet is for controlling the position offsets such as where the camera is oriented around the player"
				)

				self.sheet:AddSheet(
					"Aim",
					vgui.Create("ctp_SheetDirection", self),
					nil,
					false,
					false,
					"This sheet is for controlling the aim settings such as where the camera is pointing or/and at what"
				)

				self.sheet:AddSheet(
					"Misc",
					vgui.Create("ctp_SheetMisc", self),
					nil,
					false,
					false,
					"This sheet is for misc options"
				)

				self:StretchToParent(ctp.Spacing, ctp.Spacing - 350, ctp.Spacing, ctp.Spacing)
			end

			function PANEL:PerformLayout()
				self.sheet:StretchToParent(ctp.Spacing, ctp.Spacing + 90, ctp.Spacing, ctp.Spacing)

				self.enable:MoveAbove(self.sheet, ctp.Spacing)
				self.enable:StretchBottomTo(self.sheet, ctp.Spacing)
				self.enable:AlignLeft(ctp.Spacing)
				self.enable:CopyWidth(self.sheet)

				self.preset:CopyWidth(self.sheet)
				self.preset:AlignTop(ctp.Spacing + 20)
				self.preset:AlignLeft(ctp.Spacing)
				self.preset:StretchBottomTo(self.enable, ctp.Spacing)
			end
		end
	end

end