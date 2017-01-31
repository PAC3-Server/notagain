do return end

AddCSLuaFile()

local tod = {}
_G.tod = tod

tod.Params = {}
tod.CurrentParams = {}

local P = tod.Params
local C = tod.CurrentParams

-- sky paint
local function GetSky()
	local ent = ents.FindByClass("env_skypaint")[1] or NULL

	if not ent:IsValid() then
		ent = ents.Create("env_skypaint")
		ent:Spawn()
		ent:Activate()

		ent:SetKeyValue("sunposmethod", "0")
		ent:SetKeyValue("drawstars", "1")
		ent:SetKeyValue("startexture", "skybox/starfield")

		RunConsoleCommand("sv_skyname", "painted")
	end
	return ent
end

local function ADD_SKY_KEYVALUE(name, default, mult_by_world_light)
	if CLIENT then
		P["sky_" .. name] = default
	end
	if SERVER then
		local type = type(default)
		if type == "Vector" then
			P["sky_" .. name] = function(val)
				if mult_by_world_light then
					val = val * C.world_light_multiplier
				end
				GetSky():SetKeyValue(name, val.x .. " " .. val.y .. " " .. val.z)
			end
		elseif type == "number" then
			P["sky_" .. name] = function(val) GetSky():SetKeyValue(name, val) end
		end
	end
end

local min = 98

function tod.MultToLightEnv(mult)
	return math.Clamp(math.Round(min + (mult * min)), min, 127)
end

ADD_SKY_KEYVALUE("topcolor", Vector(0.2, 0.5, 1), true)
ADD_SKY_KEYVALUE("bottomcolor", Vector(0.8, 1, 1), true)
ADD_SKY_KEYVALUE("fadebias", 1)
ADD_SKY_KEYVALUE("sunsize", 2)
ADD_SKY_KEYVALUE("suncolor", Vector(0.2, 0.1, 0))
ADD_SKY_KEYVALUE("duskscale", 1)
ADD_SKY_KEYVALUE("duskintensity", 1)
ADD_SKY_KEYVALUE("duskcolor", Vector(1, 0.2, 0))
ADD_SKY_KEYVALUE("starscale", 0.2)
ADD_SKY_KEYVALUE("starfade", 1)
ADD_SKY_KEYVALUE("starspeed", 0.01)
ADD_SKY_KEYVALUE("hdrscale", 0.66)

RunConsoleCommand("sv_skyname", "painted")

if SERVER then
	hook.Add("InitPostEntity","tod",function()
		GetSky()
		hook.Remove("InitPostEntity", "tod")
	end)
end

if CLIENT then
	P.bloom_darken = 0
	P.bloom_multiply = 0
	P.bloom_width = 1
	P.bloom_height = 1
	P.bloom_passes = 1
	P.bloom_saturation = 1
	P.bloom_color = Vector(1, 1, 1)

	P.color_add = Vector(0, 0, 0)
	P.color_multiply = Vector(0, 0, 0)
	P.color_brightness = 0
	P.color_contrast = 1
	P.color_saturation = 1

	P.sharpen_contrast = 0
	P.sharpen_distance = 0

	P.star_intensity = 0
	P.moon_size = 1
	P.moon_angles = Angle(0,0,0)

	P.fog_color = Vector(1,1,1)
	P.fog_start = 0
	P.fog_end = 32000
	P.fog_max_density = 1

	P.sun_angles = Angle(0,0,0)

	P.shadow_color = Vector(0,0,0)
	P.shadow_angles = Angle(0,0,0)

	P.world_light_multiplier = 0.5
end

if SERVER then

	P.sun_angles = function(val)
		local ent = ents.FindByClass("env_sun")[1] or NULL

		local n = -val:Forward()
		GetSky():SetKeyValue("sunnormal", n.x .. " " .. n.y .. " " .. n.z)

		do
			local ent = ents.FindByClass("shadow_control")[1] or NULL

			if ent:IsValid() then
				ent:Fire("SetAngles", math.Round(val.p).." "..math.Round(val.y).." "..math.Round(val.r))

				local fade = (val.p/180)
				ent:Fire("SetDistance", fade * 70)
				if fade > 0 then
					ent:Fire("SetShadowsDisabled", "0")
				else
					ent:Fire("SetShadowsDisabled", "1")
				end
			end
		end

		if ent:IsValid() then
			timer.Create("tod_sun_angles_hack", 0, 2, function()
				ent:SetAngles(val)
				ent:Fire("addoutput", "pitch " .. -val.p)
				ent:Activate()
			end)
		end
	end

	P.shadow_color = function(val)
		local ent = ents.FindByClass("shadow_control")[1] or NULL

		if ent:IsValid() then
			ent:Fire("color", math.Round(val.x).." "..math.Round(val.y).." "..math.Round(val.z))
		end
	end

	P.world_light_multiplier = function(val)
		local ent = ents.FindByClass("light_environment")[1] or NULL

		if ent:IsValid() then
			ent:Fire("SetPattern", string.char(tod.MultToLightEnv(val)))
		else
		--	engine.LightStyle(tod.MultToLightEnv(val), 0)
			engine.LightStyle(0, tod.MultToLightEnv(val)) -- You just made a mistake with the parameters
		end
	end
end

if CLIENT then
	do -- texture collector
		local bsp = requirex("bsp")

		local map_data = bsp.Open()
		local found = map_data:ReadLumpTextDataStringData()

		for k,v in pairs(found) do
			if v:find("water/") then
				found[k] = nil
			end
		end

		function tod.GetMapTextures()
			return found
		end

		hook.Add("Think", "tod_replacetextures", function()
			if not LocalPlayer():IsValid() then return end

			for _, tex in pairs(tod.GetMapTextures()) do
				hook.Run("TOD_ReplaceGrassTexture", tex)
			end

			hook.Remove("Think", "tod_replacetextures")
		end)
	end

	local last_byte

	timer.Create("tod_update_lightmap", 0.1, 0, function()
		local byte = tod.MultToLightEnv(tod.GetCycle())

		if last_byte ~= byte then
			-- this function is very slow
			render.RedownloadAllLightmaps()
			last_byte = byte
		end
	end)


	do -- stars	and moon
		tod.moon_ent = NULL

		do
			local earth = Material("models/props_wasteland/rockcliff02c")
			local atmosphere = Material("models/props/de_tides/clouds")
			local atmosphere_outter = Material("models/debug/debugwhite")

			local render = render
			local SetMaterialOverride = function(m)
				if _G.net then
					render.MaterialOverride(m == 0 and nil or m)
				else
					SetMaterialOverride(m)
				end
			end

			local render_SetColorModulation = render.SetColorModulation
			local render_SetBlend = render.SetBlend
			local render_MaterialOverride = render.MaterialOverride
			local math_Rand = math.Rand

			function tod.MoonRender(self)
				local normal_scale = C.moon_size * 40

				local fraction = 1
				local ply = LocalPlayer()

				if ply:GetAimVector():DotProduct((self:GetPos() - ply:EyePos()):GetNormalized()) > 0.999 then
					fraction = ply:GetFOV() / 5
					fraction = fraction ^ 20
				end

				--render.SuppressEngineLighting( true )
					--render.SetAmbientLight( 1, 1, 1)

						local rand = math_Rand(1, 100)
						render_SetColorModulation(rand, rand, rand)
						render_SetBlend(1)
						render_MaterialOverride(0)
						self:SetModelScale(normal_scale, 0)
						self:DrawModel()

						render_SetColorModulation(0.7, 0.8, 0.9)
						render_SetBlend(fraction)
						render_MaterialOverride(earth)
						self:SetModelScale(normal_scale, 0)
						self:DrawModel()

						render_SetColorModulation( 1,1,1 )
						render_SetBlend(0.5)
						render_MaterialOverride(atmosphere)
						self:SetModelScale(normal_scale, 0)
						self:DrawModel()

						render_SetColorModulation( 3.5,3.6,3.9 )
						render_SetBlend(fraction)
						render_MaterialOverride(atmosphere)
						self:SetModelScale(normal_scale * 1.1, 0)
						self:DrawModel()

						render_SetColorModulation(1, 1, 1)
						render_SetBlend(1)
						render_MaterialOverride(0)
					--render.SetAmbientLight( 1, 1, 1)
				--render.SuppressEngineLighting( false )

				if fraction < 0.2 then
					LocalPlayer():SetDSP(23)
					for i=1, 4 do
						LocalPlayer():EmitSound("weapons/explode"..math.random(3, 5)..".wav", 0, math.random(4))
					end
					timer.Create("tod_moon_sound", 0.25, 1, function()
						LocalPlayer():SetDSP(0)
						LocalPlayer():ConCommand("stopsound")
					end)
				end
			end

			function tod.InitializeSky()
				local origin = vector_origin
				local angles = vector_origin

				hook.Add("RenderScene", "tod_moon", function(pos, ang) origin = pos angles = ang end)

				local render_DrawSprite = render.DrawSprite
				local render_SetMaterial = render.SetMaterial
				local cam_Start3D = cam.Start3D
				local cam_End3D = cam.End3D

				hook.Add("PostDrawSkyBox", "tod_moon", function()
					if tod.moon_ent:IsValid() then
						local pos = origin + C.moon_angles:Forward() * -8000
						tod.moon_ent:SetPos(pos)
						tod.moon_ent:SetAngles((pos - origin):Angle() + Angle(-90,0,180))
						tod.MoonRender(tod.moon_ent)
					else
						timer.Simple(0.1, function()
							local ent = ents.CreateClientProp()

							ent:SetModel("models/dav0r/hoverball.mdl")
							ent:SetMaterial("models/gman/gman_face_map3")
							ent:SetPos(origin)
							ent:SetColor(170,190,255,255)
							ent:SetNoDraw(true)

							tod.moon_ent = ent
						end)
					end
				end)
			end

			if LocalPlayer():IsValid() then
				tod.InitializeSky()
			end

			hook.Add("InitPostEntity", "tod_moon", function()
				tod.InitializeSky()
				hook.Remove("InitPostEntity", "tod_moon")
			end)
		end
	end

	local enable = CreateClientConVar("tod_pp", "0")
	local DrawColorModify = DrawColorModify

	hook.Add("RenderScreenspaceEffects", "tod_pp", function()

		if not enable:GetBool() then return end

		-- hack
		-- DrawColorModify may exist after this script is ran
		DrawColorModify = DrawColorModify or _G.DrawColorModify

		if
			C.sharpen_contrast ~= 0 or
			C.sharpen_distance ~= 0
		then
			DrawSharpen(
				C.sharpen_contrast,
				C.sharpen_distance
			)
		end

		if
			C.color_add ~= vector_origin or
			C.color_multiply ~= vector_origin or
			C.color_brightness ~= 0 or
			C.color_contrast ~= 1 or
			C.color_saturation ~= 1
		then
			local params = {}
				params["$pp_colour_addr"] = C.color_multiply.r
				params["$pp_colour_addg"] = C.color_multiply.g
				params["$pp_colour_addb"] = C.color_multiply.b
				params["$pp_colour_brightness"] = C.color_brightness
				params["$pp_colour_contrast"] = C.color_contrast
				params["$pp_colour_colour"] = C.color_saturation
				params["$pp_colour_mulr"] = C.color_add.r
				params["$pp_colour_mulg"] = C.color_add.g
				params["$pp_colour_mulb"] = C.color_add.b
			DrawColorModify(params)
		end

		if
			C.bloom_darken ~= 1 or
			C.bloom_multiply ~= 0
		then
			DrawBloom(
				C.bloom_darken,
				C.bloom_multiply,
				C.bloom_width,
				C.bloom_height,
				C.bloom_passes,
				C.bloom_saturation,
				C.bloom_color.r,
				C.bloom_color.g,
				C.bloom_color.b
			)
		end
	end)

	local function SetupFog()
		render.FogMode(1)
		render.FogStart(C.fog_start)
		render.FogEnd(C.fog_end)
		render.FogColor(C.fog_color.r * C.world_light_multiplier, C.fog_color.g * C.world_light_multiplier, C.fog_color.b * C.world_light_multiplier)
		render.FogMaxDensity(C.fog_max_density)

		return true
	end

	hook.Add("SetupWorldFog", "tod", SetupFog)
	hook.Add("SetupSkyboxFog", "tod", SetupFog)

	do -- sectors (to use with snow and such)
		-- initialize points
		local data = {}
		local max = 32000
		local grid_size = 768
		local range = max / grid_size

		local pos

		for x = -range, range do
			x = x * grid_size
			for y = -range, range do
				y = y * grid_size
				for z = -range, range do
					z = z * grid_size

					pos = Vector(x,y,z)
					local conents = util.PointContents(pos)

					if conents == CONTENTS_EMPTY or conents == CONTENTS_TESTFOGVOLUME then
						local up = util.QuickTrace(pos, vector_up * max * 2)
						up.HitTexture = up.HitTexture:lower()
						if up.HitTexture == "tools/toolsskybox" or up.HitTexture == "**empty**" then
							table.insert(data, pos)
						end
					end
				end
			end
		end

		-- show or hide points
		local function fastlen(point)
			return point.x * point.x + point.y * point.y + point.z * point.z
		end

		local draw_these = {}

		local iterations = math.min(math.ceil(#data/(1/0.1)), #data)
		local lastkey = 1
		local lastpos = nil
		local len = 3000 ^ 2
		local movelen = 100 ^ 2

		local eyepos = Vector()
		hook.Add("RenderScene", "tod_eyepos", function(pos, ang)
			eyepos = pos + LocalPlayer():GetVelocity()
		end)

		local function sector_think()
			if lastpos == nil or fastlen(lastpos - eyepos) > movelen then
				local c = #data
				local r = math.min(iterations, c)
				local completed = false

				for i = 1, r do
					local key = lastkey + 1
					if key > c then
						completed = true
						lastkey = 1
						break
					end

					local point = data[key]
					local dc = fastlen(point - eyepos) < len

					if dc and draw_these[key] == nil then
						draw_these[key] = point
					elseif not dc and draw_these[key] ~= nil then
						draw_these[key] = nil
					end

					lastkey = key
				end

				if completed then
					lastpos = eyepos
				end
			end
		end

		function tod.GetOutsideSectors()
			return draw_these
		end

		local last

		function tod.EnableSectorThink(b)
			if last ~= b then
				if b then
					timer.Create("tod_sector_think", 0.25, 0, sector_think)
				else
					timer.Remove("tod_sector_think")
				end
				last = b
			end
		end

	end

	-- todo!
	-- have an inside and outside config
	--[[
	local smooth_outside = 0

	function tod.IsOutside()
		return smooth_outside > 0.5
	end
	local cache = {}
	timer.Create("tod_outside", 0.2, 0, function()
		local outside = 0
		local ply = LocalPlayer()
		local a = ply:EyePos()
		a.x = math.Round(a.x/32)*32
		a.y = math.Round(a.y/32)*32
		a.z = math.Round(a.z/32)*32

		if cache[a.x..a.y..a.z] then
			outside = 1
		else
			local b = a + VectorRand() * 32000

			if util.TraceLine(
				{
					start = a,
					endpos = b,
					mask = MASK_OPAQUE,
				}
			).HitSky then
				outside = 4
				cache[a.x..a.y..a.z] = true
			end
		end

		smooth_outside = smooth_outside + ((outside - smooth_outside) * FrameTime() * 10)

		epoe.Print(tod.IsOutside())
	end)
	]]
end

-- keep hidden entities
-- light_environment won't update properly if the map didn't compile with it properly.
-- the light refreshes on full update (reconnecting for instance)
-- or when you spawn a light somewhere on the map it will update that sector of the map

-- so if you're using a realtime tod it shouldn't be that noticable
do
	tod.hidden_entities = {}

	hook.Add("EntityKeyValue", "hidden_entities", function(ent, key, val)
		local T = ent:GetClass():lower()

		if
			T == "shadow_control" or
			T == "light_environment" or
			T == "sky_camera" or
			T == "env_sun" or
			T == "env_fog_controller"
		then
			ent:SetKeyValue("targetname", T)
			tod.hidden_entities[T] = ent
		end
	end)
end

for key, val in pairs(tod.Params) do
	if type(val) ~= "function" then
		tod.CurrentParams[key] = val
	end
end

-- lerping
do
	function tod.Lerp(mult, a, b)
		local params = {}
		for key, val in pairs(a) do
			if type(val) == "number" then
				params[key] =  Lerp(mult, val, b[key] or val)
			elseif type(val) == "Vector" then
				params[key] = LerpVector(mult, val, b[key] or val)
			elseif type(val) == "Angle" then
				params[key] = LerpAngle(mult, val, b[key] or val)
			end
		end
		return params
	end

	local function lerp(mult, tbl)
		local out = {}

		for i = 1, #tbl - 1 do
			out[i] = tod.Lerp(mult, tbl[i], tbl[i + 1])
		end

		if #out > 1 then
			return lerp(mult, out)
		else
			return out[1]
		end
	end

	function tod.LerpConfigs(mult, ...)
		return lerp(mult, {...})
	end
end

function tod.GetWeatherChance(probability)
	if tod.force_weather ~= nil then return tod.force_weather end
	probability = probability or 0.5
	math.randomseed(math.floor(CurTime()/100))
	local b = math.random() < probability
	math.randomseed(RealTime())
	return b
end

function tod.SetParameter(key, val)
	if type(tod.Params[key]) == "function" then
		tod.Params[key](val)
	end
	tod.CurrentParams[key] = val
end

function tod.GetParameter(key)
	return tod.CurrentParams[key]
end

function tod.SetConfig(data)
	for key, val in pairs(data) do
		tod.SetParameter(key, val)
	end
end

function tod.GetCycle()
	if tod.mode == 2 then
		-- demo mode
		return (CurTime() / (20))%1
	end

	return tod.current_cycle or 0
end

if CLIENT then
	net.Receive("tod_setcycle", function()
		tod.current_cycle = net.ReadFloat() / 1000
	end)

	net.Receive("tod_setmode", function()
		tod.mode = net.ReadInt(4)
	end)
end

if SERVER then
	util.AddNetworkString("tod_setcycle")

	function tod.SetCycle(time)
		tod.current_cycle = time and (time%1) or -1
		net.Start("tod_setcycle")
			net.WriteFloat(tod.current_cycle * 1000)
		net.Send(player.GetAll())
	end

	util.AddNetworkString("tod_setmode")

	function tod.SetMode(mode, filter)
		tod.mode = mode
		net.Start("tod_setmode")
			net.WriteInt(tod.mode, 4)
		net.Send(filter or player.GetAll())
	end
end

tod.cvar = CreateConVar("sv_tod", "1", bit.bor(FCVAR_REPLICATED, FCVAR_NOTIFY),
	"0 = off\n1 = realtime\n2 = demo"
)

if SERVER then
	hook.Add("PlayerInitialSpawn", "tod_mode", function(ply)
		if not ply or not ply:IsValid() then return end

		tod.SetMode(tod.cvar:GetInt(), ply)
	end)
end

local cache = {}

function tod.SetConfigCycle(...)
	cache = {}
	tod.config_cycle = {...}
end

function tod.SetOverrideConfig(config, lerp)
	cache = {}
	tod.override_config = config
	tod.override_lerp =  lerp
end

tod.override_configs = {}

function tod.AddOverrideConfig(name, config, probability)
	tod.override_configs[name] = {config = config, probability = probability, lerp = 0}
end

hook.Add("Think", "tod", function()

	-- initialize tod
	if SERVER and not tod.mode then
		tod.SetMode(tod.cvar:GetInt())
	end

	local time

	if not tod.mode or tod.mode == 0 or tod.mode == 2 then -- manual
		time = tod.GetCycle()
	elseif tod.mode == 1 then -- realtime
		local H, M, S = os.date("%H"), os.date("%M"), os.date("%S")
		local fraction = (H*3600 + M*60 + S) / 86400

		time = fraction%1
	end

	for name, data in pairs(tod.override_configs) do
		if tod.GetWeatherChance(data.probability) then
			data.lerp = math.min(data.lerp + FrameTime(), 1)

			tod.SetOverrideConfig(data.config, data.lerp)
		else
			data.lerp = math.max(data.lerp - FrameTime(), -1)

			if data.lerp == -1 then
				tod.SetOverrideConfig()
			else
				tod.SetOverrideConfig(data.config, data.lerp)
			end
		end
	end

	-- cache lerp results
	-- good for realtime
	time = math.Round(time, 3)

	local cfg

	if cache[time] then
		cfg = cache[time]
	else
		cfg = tod.LerpConfigs(
			time,

			unpack(tod.config_cycle)
		)

		-- for snow and such
		if tod.override_config then
			cfg = tod.LerpConfigs(tod.override_lerp, cfg, tod.override_config)
		end

		cache[time] = cfg
	end

	tod.SetConfig(cfg)
end)

include("notagain/tod/tod/default_cycle.lua")

if SERVER then
	AddCSLuaFile("notagain/tod/tod/default_cycle.lua")
end

do -- weather
	local month = tonumber(os.date("%m")) or -1

	if month >= 11 or month <= 2 then
		include("notagain/tod/tod/snow.lua")
		if SERVER then
			AddCSLuaFile("notagain/tod/tod/snow.lua")
		end
	end
end

return tod