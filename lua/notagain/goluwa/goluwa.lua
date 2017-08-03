local goluwa = _G.goluwa or {}
_G.goluwa = goluwa

goluwa.notagain_monitor_directories = {}

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

	table.insert(goluwa.notagain_monitor_directories, {
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
	return goluwa
end

function goluwa.Update(cb)
	http.Fetch("https://api.github.com/repos/CapsAdmin/goluwa/git/trees/master?recursive=1", function(body)
		file.CreateDir("goluwa/")

		local prev_paths = {}
		local prev_body = file.Read("goluwa/downloaded_lua_files.txt")

		if prev_body then
			for path, sha in prev_body:gmatch('"path":%s-"(src/lua/libraries/.-)".-"sha":%s-"(.-)"') do
				if path:EndsWith(".lua") then
					prev_paths[path] = sha
				end
			end
		else
			print("goluwa: downloading files for first time")
		end

		local paths = {}

		for path, sha in body:gmatch('"path":%s-"(src/lua/libraries/.-)".-"sha":%s-"(.-)"') do
			if path:EndsWith(".lua") then
				if prev_paths[path] ~= sha then
					paths[path] = sha
				end
			end
		end

		local count = table.Count(paths)

		if count == 0 then
			print("goluwa: everything is up to date")
			cb()
			return
		end

		file.Write("goluwa/downloaded_lua_files.txt", body)

		print("goluwa: downloading " .. count .. " files")

		local next_print = 0
		local left = count

		local done = {}

		for path in pairs(paths) do
			local dir = (path:match("(.+)/.-%.lua") or path)
			if not dir:EndsWith("/") then
				dir = dir .. "/"
			end
			if not done[dir] then
				local folder_path = ""
				for folder in dir:gmatch("(.-/)") do
					folder_path = folder_path .. folder
					if not done[folder_path] then
						file.CreateDir("goluwa/" .. folder_path)
						done[folder_path] = true
					end
				end
				done[dir] = true
			end
			http.Fetch("https://raw.githubusercontent.com/CapsAdmin/goluwa/master/" .. path, function(lua)
				file.Write("goluwa/" .. path:gsub("%.", "^") .. ".txt", lua)
				left = left - 1

				if left == 0 then
					print("goluwa: done!")
					cb()
				elseif next_print < RealTime() then
					print("goluwa: " .. left .. " files left")
					next_print = RealTime() + 1
				end
			end)
		end
	end)
end

function goluwa.CreateEnv()
	local env = {}
	goluwa.env = env

	env.e = {}

	local urlimage = requirex("urlimage")
	local msgpack = requirex("msgpack")
	local mp3duration = requirex("mp3duration")
	local prettytext = requirex("pretty_text")

	include("notagain/goluwa/std.lua")

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
		if path:EndsWith("*") then
			local dir = path:sub(0, -2)

			if not file.IsDir("goluwa/src/" .. dir, "DATA") then
				local relative = debug.getinfo(2).source:match("@(.+)")

				if relative then
					dir = relative:match("(.+/).-%.lua") .. dir
				end
			end

			local files = file.Find("goluwa/src/" .. dir .. "*", "DATA")

			for _, name in pairs(files) do
				env.runfile(dir .. name, ...)
			end
			return
		end

		local original_path = path

		if not path:EndsWith(".txt") then
			path = path:gsub("%.", "^") .. ".txt"
		end

		if file.Exists("goluwa/src/" .. path, "DATA") then
			local lua = file.Read("goluwa/src/" .. path, "DATA")
			local func = CompileString(lua, original_path, false)
			if type(func) == "function" then
				setfenv(func, env)
				return func(...)
			else
				MsgN(func)
			end
		else
			local relative = debug.getinfo(2).source:match("@(.+)")

			if relative then
				local dir = relative:match("(.+/).-%.lua")
				local path = dir .. path
				if file.Exists("goluwa/src/" .. path, "DATA") then
					return env.runfile(path, ...)
				end
			end
		end
	end

	env.runfile("lua/libraries/extensions/string.lua")
	env.runfile("lua/libraries/extensions/globals.lua")
	env.runfile("lua/libraries/extensions/debug.lua")
	env.runfile("lua/libraries/extensions/os.lua")
	env.runfile("lua/libraries/extensions/table.lua")
	env.runfile("lua/libraries/extensions/math.lua")
	env.utf8 = env.runfile("lua/libraries/utf8.lua")

	for k,v in pairs(env.string) do _G.string[k] = _G.string[k] or v end -- :(

	env.prototype = env.runfile("lua/libraries/prototype/prototype.lua")
	env.serializer = env.runfile("lua/libraries/serializer.lua")
	env.structs = env.runfile("lua/libraries/structs.lua")

	env.utility = env.runfile("lua/libraries/utilities/utility.lua")
	env.vfs = env.runfile("lua/libraries/filesystem/vfs.lua")
	env.vfs.Mount("os:/", "os:")
	env.vfs.Mount("os:/data/goluwa/data/", "os:data/")
	env.vfs.Mount("os:/data/goluwa/userdata/", "os:data/")
	env.R = env.vfs.GetAbsolutePath -- a nice global for loading resources externally from current dir
	env.crypto = env.runfile("lua/libraries/crypto.lua")

	env.commands = env.runfile("lua/libraries/commands.lua")

	concommand.Add("goluwa", function(ply, cmd, args, line) env.commands.RunString(line, false, false, true) end)

	env.profiler = env.runfile("lua/libraries/profiler.lua")
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

	env.event = env.runfile("lua/libraries/event.lua")

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

	env.expression = env.runfile("lua/libraries/expression.lua")

	env.sockets = {}
	env.SOCKETS = true
	env.runfile("lua/libraries/network/sockets/http.lua", env.sockets)

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

	env.resource = env.runfile("lua/libraries/network/resource.lua")

	do
		local backend = CreateClientConVar("goluwa_audio_backend", "webaudio")
		local common_audio = requirex("common_audio")

		local audio = {}

		audio.player_object = NULL

		function audio.CreateSource(path)
			local snd = common_audio.CreateSoundFromInterface(backend:GetString())
			snd:SetEntity(audio.player_object)

			env.resource.Download(path, function(path)
				path = env.GoluwaToGmodPath(path)
				snd:SetPath(path)
			end)

			return snd
		end

		function audio.Panic()
			common_audio.Panic()
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

		env.runfile("lua/libraries/graphics/gfx/markup.lua", env.gfx)
	end

	do
		local steam = {}

		function steam.MountSourceGame()

		end

		env.steam = steam
	end

	env.autocomplete = env.runfile("lua/libraries/autocomplete.lua")
	env.chatsounds = env.runfile("lua/libraries/audio/chatsounds/chatsounds.lua")

	return env
end

goluwa.notagain_autorun = false

function goluwa.Initialize()
	goluwa.env = goluwa.CreateEnv()
	notagain.loaded_libraries.goluwa = goluwa
	notagain.AutorunDirectory("goluwa")
end

goluwa.Update(goluwa.Initialize)

return goluwa
