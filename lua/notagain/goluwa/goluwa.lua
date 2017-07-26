local env = {}
_G.goluwa = env

env.e = {}
env.notagain_monitor_directories = {}

local function add(dir)
	local files, directories = file.Find(dir .. "/*", "LUA")

	for _, file_name in ipairs(files) do
		if SERVER then
			AddCSLuaFile(dir .. "/" .. file_name)
		end
	end

	for _, dir_name in ipairs(directories) do
		add(dir .. "/" .. dir_name)
	end

	table.insert(env.notagain_monitor_directories, {
		dir = dir .. "/",
		what = "clients",
		lib = dir ~= "notagain/goluwa/goluwa" and function(code)
			return "setfenv(1, requirex('goluwa'));" .. code
		end,
	})
end

AddCSLuaFile()
add("notagain/goluwa/goluwa")

if SERVER then
	return env
end

local urlimage = requirex("urlimage")
local msgpack = requirex("msgpack")
local mp3duration = requirex("mp3duration")
local prettytext = requirex("pretty_text")

include("notagain/goluwa/goluwa/std.lua")

do
	env._OLD_G = {}
	local done = {[env._G] = true}

	local function scan(tbl, store)
		for key, val in pairs(tbl) do
			local t = type(val)

			if t == "table" and not done[val] and val ~= store then
				store[key] = store[key] or {}
				done[val] = true
				scan(val, store[key])
			else
				store[key] = val
			end
		end
	end
	scan(env._G, env._OLD_G)
end

env.check = function() end

do
	env.ffi = false
	env.archive = false
	env.opengl = false
	env["table.new"] = false
	env["table.clear"] = false
	env["deflatelua"] = false
	env["lunajson"] = false

	env.msgpack = {encode = msgpack.pack, decode = msgpack.unpack}
	env.msgpack2 = false
	env.von = false
end

function env.runfile(path, ...)
	if path:StartWith("lua/") then
		path = "notagain/goluwa/goluwa/" .. path:sub(5)
	end

	if path:EndsWith("*") then
		local dir = path:sub(2)
		if not file.IsDir(path, "LUA") then
			local folder_name = path:match(".+/(.-/)%*") or path:match("(.+/)%*")
			local info = debug.getinfo(2)
			dir = info.source:match("^.+lua/(notagain/goluwa/.+)")
			dir = dir:match("(.+/)") .. folder_name
			path = dir .. "*"
		end
		local files = file.Find(path, "LUA")
		for _, name in pairs(files) do
			env.runfile(dir .. name, ...)
		end
		if not files[1] then
			ErrorNoHalt("no files in " .. path)
		end
		return
	end

	if file.Exists(path, "LUA") then
		local func = CompileFile(path)
		if isfunction(func) then
			setfenv(func, env)
			return func(...)
		else
			ErrorNoHalt(func)
		end
	else
		local info = debug.getinfo(2)
		if info and info.source then
			local dir = info.source:match("^.+lua/(notagain/goluwa/.+)")
			if dir then
				dir = dir:match("(.+/)")
				if file.Exists(dir .. path, "LUA") then
					local func = CompileFile(dir .. path)
					if isfunction(func) then
						setfenv(func, env)
						return func(...)
					else
						ErrorNoHalt(func)
					end
				else
					ErrorNoHalt("file not found " .. dir .. path)
					ErrorNoHalt("file not found " .. path)
				end
			end
		end
	end
end

env.runfile("goluwa/libraries/extensions/string.lua")
for k,v in pairs(env.string) do _G.string[k] = _G.string[k] or v end -- :(

env.runfile("goluwa/libraries/extensions/globals.lua")
env.runfile("goluwa/libraries/extensions/debug.lua")
env.runfile("goluwa/libraries/extensions/os.lua")
env.runfile("goluwa/libraries/extensions/table.lua")
env.runfile("goluwa/libraries/extensions/math.lua")
env.utf8 = env.runfile("goluwa/libraries/utf8.lua")

local http = table.Copy(http)

do
	-- just to debug any http requests
	function http.Fetch(url, ...)
		--print("http.Fetch: " .. url)
		_G.http.Fetch(url, ...)
	end
end

local sound = table.Copy(sound)

if system.IsLinux() then -- sound.PlayFile fix
	local print = function() end
	sound.active = {}
	sound.queue = {}
	sound.requests = {}

	GOLUWA_SOUND_FIX = sound

	local counter = 0
	function sound.PlayFile(url, flags, cb)
		print("sound.Play: " .. url)
		print("COUNTER: " .. counter)

		if #sound.requests >= 16 then
			table.insert(sound.queue, {url, flags, cb})
			print("queuing " .. url)
			return
		end

		print(#sound.requests .. " requests in queue")

		table.insert(sound.requests, cb)

		counter = counter + 1
		_G.sound.PlayFile(url, flags, function(snd, ...)
			for i, v in ipairs(sound.requests) do
				if v == cb then
					table.remove(sound.requests, i)
					print(#sound.requests .. " requests in queue")
				end
			end

			if IsValid(snd) then
				table.insert(sound.active, snd)
				print(#sound.active .. " active sounds")
			end
			cb(snd, ...)
		end)
	end

	hook.Add("Think", "soundplay_queue", function()
		for i = #sound.active, 1, -1 do
			local snd = sound.active[i]

			if not snd:IsValid() then
				table.remove(sound.active, i)
				print("remove invalid sound " .. i)
				print(#sound.active .. " active sounds")
			end
		end

		if #sound.requests < 16 then
			for i = #sound.queue, 1, -1 do
				local args = sound.queue[i]
				table.remove(sound.queue, i)
				print("playing sound from queue")
				sound.PlayFile(unpack(args))
				if #sound.requests >= 16 then
					break
				end
			end
		end
	end)
end

function env.typex(val)
	if IsColor(val) then
		return "color"
	end

	return type(val)
end

do -- color
	local color_unpack = function(s) return s.r, s.g, s.b, s.a end

	function env.Color(r,g,b,a)
		local c = Color(r,g,b,a)
		c.Unpack = color_unpack
		return c
	end

	function env.ColorHSV(h,s,v)
		local self = HSVToColor(h*360,s,v)
		self.Unpack = color_unpack
		return self
	end
end

do -- vec2
	function env.Vec2(x, y)
		return Vector(x, y, 0)
	end

	local META = FindMetaTable("Vector")

	function META:Unpack()
		return self.x, self.y, self.z
	end
end

env.prototype = env.runfile("goluwa/libraries/prototype/prototype.lua")
env.utility = env.runfile("goluwa/libraries/utilities/utility.lua")
env.vfs = env.runfile("goluwa/libraries/filesystem/vfs.lua")
env.vfs.Mount("os:/", "os:")
env.vfs.Mount("os:/data/goluwa/data/", "os:data/")
env.vfs.Mount("os:/data/goluwa/userdata/", "os:data/")
env.R = env.vfs.GetAbsolutePath -- a nice global for loading resources externally from current dir
env.crypto = env.runfile("goluwa/libraries/crypto.lua")

env.commands = env.runfile("goluwa/libraries/commands.lua")

concommand.Add("goluwa", function(ply, cmd, args, line) env.commands.RunString(line, false, false, true) end)

env.profiler = env.runfile("goluwa/libraries/profiler.lua")
env.P = env.profiler.ToggleTimer
env.I = env.profiler.ToggleInstrumental
env.S = env.profiler.ToggleStatistical

do -- texture
	local render = {}

	function render.CreateTextureFromPath(path)
		if path:StartWith("materials/") then
			path = path:sub(#"materials/" + 1)
		end

		local tex = {}

		if path:StartWith("http") then
			tex.mat = urlimage.URLMaterial(path)
			tex.urlimage = true
		else
			tex.mat = Material(path)
		end
		tex.IsValid = function()return true end
		tex.IsLoading = function() return false end
		tex.GetSize = function()
			if tex.urlimage then
				local w, h = tex.mat()
				if w then
					return Vector(w, h)
				end

				return Vector(16, 16)
			end
			return Vector(tex.mat:Width(), tex.mat:Height())
		end
		return tex
	end

	env.render = render
end

do
	local window = {}

	function window.SetClipboard(str)
		SetClipboardText(str)
	end

	function window.GetClipboard()
		ErrorNoHalt("NYI")
	end

	env.window = window
end

do
	local system = {}

	function system.GetFrameNumber()
		return FrameNumber()
	end

	function system.GetElapsedTime()
		return RealTime()
	end

	function system.GetFrameTime()
		return FrameTime()
	end

	function system.GetTime()
		return SysTime()
	end

	function system.OpenURL(url)
		gui.OpenURL(url)
	end

	function system.OnError(...)
		print(...)
		debug.Trace()
	end

	system.pcall = pcall

	env.system = system
end

env.event = env.runfile("goluwa/libraries/event.lua")

env.event.AddListener("EventAdded", "gmod", function(info)
--	print("goluwa event added: ", info.event_type, info.id)
end)

env.event.AddListener("EventRemoved", "gmod", function(info)
--	print("goluwa event removed: ", info.event_type, info.id)
end)

hook.Add("Think", "goluwa_timers", function()
	env.event.UpdateTimers()
	env.event.Call("Update", FrameTime())
end)

env.serializer = env.runfile("goluwa/libraries/serializer.lua")

do -- render2d
	local render2d = {}

	do
		local R,G,B,A = 1,1,1,1

		function render2d.SetColor(r,g,b,a)
			R = r
			G = g
			B = b
			A = a or 1

			--surface.SetDrawColor(R*255,G*255,B*255,A*255)
			--surface.SetTextColor(R*255,G*255,B*255,A*255)
		end

		function render2d.GetColor()
			return R, G, B, A
		end

		env.utility.MakePushPopFunction(render2d, "Color")
	end

	do
		local TEX
		function render2d.SetTexture(tex)
			if tex then
				if tex.urlimage then
					local w,h, mat = tex.mat()
					if mat then
						surface.SetMaterial(mat)
					else
						draw.NoTexture()
					end
				else
					surface.SetMaterial(tex.mat)
				end
			else
				draw.NoTexture()
			end
		end

		function render2d.GetTexture()
			return TEX
		end

		env.utility.MakePushPopFunction(render2d, "Texture")
	end

	function render2d.SetAlphaMultiplier(m)
		render2d.alpha_multiplier = m
		--surface.SetAlphaMultiplier(m)
	end

	do
		local matrix_stack_i = 1
		local matrix_stack = {}

		render2d.world_matrix = Matrix()

		function render2d.PushMatrix(x,y, w,h, a, dont_multiply)
			local old = matrix_stack[matrix_stack_i]
			matrix_stack[matrix_stack_i] = render2d.world_matrix

			if dont_multiply then
				render2d.world_matrix = Matrix()
			else
				render2d.world_matrix = Matrix()
				if old then render2d.world_matrix:Set(old) end
			end

			matrix_stack_i = matrix_stack_i + 1

			if x and y then render2d.Translate(x, y) end
			if w and h then render2d.Scale(w, h) end
			if a then render2d.Rotate(a) end
		end

		function render2d.PopMatrix()
			matrix_stack_i = matrix_stack_i - 1

			render2d.world_matrix = matrix_stack[matrix_stack_i]
		end

		function render2d.Translate(x, y)
			render2d.world_matrix:Translate(Vector(x,y,0))
		end

		function render2d.Scale(w, h)
			render2d.world_matrix:Scale(Vector(w,h,1))
		end

		function render2d.Rotate(ang)
			render2d.world_matrix:Rotate(Angle(0,math.deg(ang),0))
		end
	end

	function render2d.DrawRect(x,y,w,h)
		cam.PushModelMatrix(render2d.world_matrix)
		local r,g,b,a = render2d.GetColor()
		surface.SetDrawColor(r*255,g*255,b*255,(a*255)*render2d.alpha_multiplier)
		surface.DrawTexturedRect(x,y,w,h)
		cam.PopModelMatrix()
	end

	env.render2d = render2d
end

env.expression = env.runfile("goluwa/libraries/expression.lua")

env.sockets = {}
env.SOCKETS = true
env.runfile("goluwa/libraries/network/sockets/http.lua", env.sockets)

function env.sockets.Request(tbl)
	tbl.callback = tbl.callback or env.table.print
	tbl.method = tbl.method or "GET"

	local ok = false

	if tbl.timeout and tbl.timedout_callback then
		env.event.Delay(tbl.timeout, function()
			if not ok then
				tbl.timedout_callback()
			end
		end)
	end

	tbl.url = tbl.url:gsub(" ", "%%20")

	--print("HTTP: " .. tbl.url)

	HTTP({
		failed = tbl.error_callback,
		success = function(code, body, header)
			ok = true

			if not tbl.code_callback or tbl.code_callback(code) ~= false then

				local copy = {}
				for k,v in pairs(header) do
					copy[k:lower()] = v
				end

				if not tbl.header_callback or tbl.header_callback(copy) ~= false then
					if tbl.on_chunks then
						tbl.on_chunks(body)
					end

					tbl.callback({content = body, header = copy, code = code})
				end
			end
		end,
		method = tbl.method,
		url = tbl.url,

		header = tbl.parameters,
		headers = tbl.headers,
		post_data = tbl.body,
		type = tbl.type or "text/plain; charset=utf-8" ,
	})
end

env.resource = env.runfile("goluwa/libraries/network/resource.lua")

do
	local audio = {}

	audio.player_object = NULL

	function audio.CreateSource(path)
		--print("audio.CreateSource: " .. path)
		if path:StartWith("http") then
			local url = path
			local snd
			local dbg_str
			local self = {}

			local ply = audio.player_object

			env.resource.Download(path, function(path)
				path = env.GoluwaToGmodPath(path)

				sound.PlayFile("../" .. path, "noplay noblock 3d", function(snd_, _, err)
					if not IsValid(snd_) then
						if err == "BASS_ERROR_EMPTY" or err == "BASS_ERROR_UNKNOWN" then
							sound.PlayFile("../" .. path, "noplay noblock", function(snd_, _, err)
								if not IsValid(snd_) then
									print("audio.CreateSource(\"" .. url .. "\"): " .. err)
									print(path)
									return
								end
								snd = snd_
								dbg_str = tostring(snd)

								if self.play_me == true then
									self:Play()
								elseif self.play_me == false then
									self:Stop()
								end

								if self.pitch_me then
									self:SetPitch(self.pitch_me)
								end

								if self.volume_me then
									self:SetPitch(self.volume_me)
								end

								if ply:IsValid() then
									local id = ply:UniqueID() .. "_goluwa_audio_createsource_" .. tostring(self)

									hook.Add("RenderScene", id, function()

										if not ply:IsValid() or not snd:IsValid() then
											hook.Remove("RenderScene", id)
											return
										end

										snd:SetPos(ply:EyePos(), ply:GetAimVector())

										local dist = ply:EyePos():Distance(LocalPlayer():EyePos())

										local f = math.Clamp(1 - dist / 500, 0, 1) ^ 1.5

										if system.HasFocus() then
											snd:SetVolume((self.gain or 1) * f)
										else
											snd:SetVolume(0)
										end
									end)
								end
							end)
						else
							print("audio.CreateSource(\"" .. url .. "\"): " .. err)
							print(path)
						end
						return
					end

					snd = snd_
					dbg_str = tostring(snd)

					if self.play_me == true then
						self:Play()
					elseif self.play_me == false then
						self:Stop()
					end

					if self.pitch_me then
						self:SetPitch(self.pitch_me)
					end

					if self.volume_me then
						self:SetPitch(self.volume_me)
					end

					if ply:IsValid() then
						local id = ply:UniqueID() .. "_goluwa_audio_createsource_" .. tostring(self)

						hook.Add("RenderScene", id, function()

							if not ply:IsValid() or not snd:IsValid() then
								hook.Remove("RenderScene", id)
								return
							end

							snd:SetPos(ply:EyePos(), ply:GetAimVector())

							snd:SetVolume(system.HasFocus() and 1 or 0)
						end)
					end
				end)
			end)

			function self:IsReady()
				return snd ~= nil and snd:IsValid()
			end

			function self:Play()
				if not snd then self.play_me = true return end
				if not snd:IsValid() then return end
				snd:Play()
			end

			function self:SetDSP(val)
				LocalPlayer():SetDSP(val)
			end

			function self:Stop()
				if not snd then self.play_me = false return end
				if not snd:IsValid() then return end
				--snd:Pause()snd:SetTime(0)
				snd:Stop()
			end

			function self:GetDuration()
				if not snd then return 1 end
				return snd:GetLength()
			end

			function self:SetPitch(val)
				if not snd then self.pitch_me = val return end
				if not snd:IsValid() then return end
				snd:SetPlaybackRate(val)
			end

			function self:SetGain(val)
				self.gain = val
				if not snd then self.volume_me = val return end
				if not snd:IsValid() then return end
				snd:SetVolume(val)
			end

			return self
		end

		local exists = file.Exists(path, "GAME")

		if not exists then
			print("audio.CreateSource: file does not exist ", path)
		end

		if path:StartWith("sound/") then
			path = path:gsub("sound/", "")
		end

		local snd = CreateSound(audio.player_object:IsValid() and audio.player_object or LocalPlayer(), path)

		local self = {}

		function self:IsReady()
			return true
		end

		function self:Play()
			snd:Play()
		end

		function self:SetDSP(val)
			snd:SetDSP(val)
		end

		function self:Stop()
			snd:Stop()
		end

		function self:GetDuration()
			if not exists then return 0 end
			if path:EndsWith(".mp3") then
				return mp3duration(file.Read("sound/" .. path, "GAME"))
			else
				return SoundDuration(path)
			end
		end

		function self:SetPitch(val)
			snd:ChangePitch(val*100, 0)
		end

		function self:SetGain(val)
			snd:ChangeVolume(val, 0)
		end

		return self
	end

	env.audio = audio
end

do
	local fonts = {}

	function fonts.CreateFont(options)
		options.font = options.path
		local handle = {}
		handle.name = tostring(handle)
		surface.CreateFont(handle.name, options)
		return handle
	end

	function fonts.FindFont(name)
		return {
			font = name,
			size = 16,
			weight = 600,
			blur_size = 2,
			background_color = Color(25,50,100,255),
			blur_overdraw = 10,
		}
	end

	env.fonts = fonts
end

do
	local gfx = {}

	function gfx.GetMousePosition()
		return gui.MousePos()
	end

	function gfx.GetDefaultFont()
		return {name = "DermaDefault"}
	end

	function gfx.DrawLine(x1,y1,x2,y2)
		cam.PushModelMatrix(env.render2d.world_matrix)
		local r,g,b,a = env.render2d.GetColor()
		surface.SetDrawColor(r*255,g*255,b*255,(a*255)*env.render2d.alpha_multiplier)
		surface.DrawLine(x1,y1,x2,y2)
		cam.PopModelMatrix()
	end

	do
		local FONT = {}

		function gfx.SetFont(font)
			FONT = font or gfx.GetDefaultFont()
		end

		env.render2d.alpha_multiplier = 1

		function gfx.DrawText(str, x,y,w,h)
			cam.PushModelMatrix(env.render2d.world_matrix)
			local r,g,b,a = env.render2d.GetColor()

			prettytext.DrawText({
				text = str,
				x = x,
				y = y,
				font = FONT.font,
				size = FONT.size,
				weight = FONT.weight,
				blur_size = FONT.blur_size,
				foreground_color = Color(r*255,g*255,b*255,a*255*env.render2d.alpha_multiplier),
				background_color = FONT.background_color,
				blur_overdraw = FONT.blur_overdraw,
				shadow_x = FONT.shadow_x or FONT.shadow,
				shadow_y = FONT.shadow_y,
			})
			cam.PopModelMatrix()
		end

		function gfx.GetTextSize(str)
			return prettytext.GetTextSize(str, FONT.font, FONT.size, FONT.weight, FONT.blur_size)
		end
	end

	env.gfx = gfx

	env.runfile("goluwa/libraries/graphics/gfx/markup.lua", env.gfx)
end

do
	local steam = {}

	function steam.MountSourceGame()

	end

	env.steam = steam
end

env.autocomplete = env.runfile("goluwa/libraries/autocomplete.lua")
env.chatsounds = env.runfile("goluwa/libraries/audio/chatsounds/chatsounds.lua")

if LocalPlayer():IsValid() then
	notagain.loaded_libraries.goluwa = env
	notagain.AutorunDirectory("goluwa")
end

return env
