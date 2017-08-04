local urlimage = CLIENT and requirex("urlimage")
local msgpack = requirex("msgpack")
local prettytext = CLIENT and requirex("pretty_text")
local common_audio = CLIENT and requirex("common_audio")

AddCSLuaFile()

local goluwa = {}

goluwa.notagain_autorun = false

local function dprint(...)
	print("goluwa: ", ...)
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
			dprint("downloading files for first time")
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
			dprint("everything is already up to date")
			cb()
			return
		end

		file.Write("goluwa/downloaded_lua_files.txt", body)

		dprint("downloading " .. count .. " files")

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
					dprint("finished downloading all files")
					cb()
				elseif next_print < RealTime() then
					dprint(left .. " files left")
					next_print = RealTime() + 0.5
				end
			end)
		end
	end)
end

function goluwa.CreateEnv()
	local env = {}

	env.e = {}

	do
		env.bit = table.Copy(_G.bit)
		env.jit = table.Copy(_G.jit)
		env.newproxy = _G.newproxy

		do -- _G
			function env.loadstring(str, chunkname)
				local var = CompileString(str, chunkname or "loadstring", false)
				if type(var) == "string" then
					return nil, var, 2
				end
				return setfenv(var, env)
			end

			function env.loadfile(path)
				if not file.Exists(path, "LUA") then
					return nil, path .. ": No such file", 2
				end
				local lua = file.Read(path, "LUA")

				return env.loadstring(lua, path)
			end

			function env.dofile(filename)
				return assert(env.loadfile(filename))()
			end
		end

		do -- os
			local os = {}

			function os.getenv(var)
				var = tostring(var):lower()

				if var == "path" then
					return (util.RelativePathToFull("lua/includes/init.lua"):gsub("\\", "/"):gsub("lua/includes/init.lua", ""))
				end

				if var == "username" then
					return SERVER and "server" or LocalPlayer():Nick()
				end
			end

			function os.setlocale(...)
				dprint("os.setlocale: ", ...)
			end

			function os.execute(...)
				dprint("os.execute: ", ...)
			end

			function os.exit(...)
				dprint("os.exit: ", ...)
			end

			os.clock = _G.os.clock
			os.date = _G.os.date
			os.difftime = _G.os.difftime
			os.time = _G.os.time

			env.os = os
		end

		do -- io
			local io = {}

			do -- file
				env.e.DATA_FOLDER = "/data/goluwa/data/"
				env.e.USERDATA_FOLDER = "/data/goluwa/userdata/"
				env.e.ROOT_FOLDER = notagain.addon_dir .. "lua/notagain/goluwa/goluwa/"
				env.e.SRC_FOLDER = env.e.ROOT_FOLDER
				env.e.BIN_FOLDER = "bin/"

				local function dprint(...)
					if goluwa.debugfs then
						print(...)
					end
				end

				local allowed = {
					[".txt"] = true,
					[".jpg"] = true,
					[".png"] = true,
					[".vtf"] = true,
					[".dat"] = true,
				}
				local function get_path(path, is_dir, read_only)
					if path:StartWith("/") then
						path = path:sub(2)
					end

					local where = "GAME"

					if path:StartWith("data/") then
						path = path:sub(6)
						where = "DATA"

						if not is_dir and not file.IsDir(path, where) then
							if not allowed[path:sub(-4)] then
								path = path:gsub("%.", "^") .. ".dat"
							end
						end
					end

					return path, where
				end

				function env.GoluwaToGmodPath(path)
					if path:StartWith("/") then
						path = path:sub(2)
					end

					if path:StartWith("data/") then
						local dir, file_name = path:match("(.+/)(.+)")
						file_name = file_name:gsub("%.", "%^")

						if not allowed[path:sub(-4)] then
							file_name = file_name .. ".dat"
						end

						return dir .. file_name
					end

					return path
				end

				local fs = {}

				function fs.find(path, exclude_dot)
					dprint("fs.find: ", path)

					if path:startswith("/") then
						path = path:sub(2)
					end

					if path:endswith("/") then
						path = path .. "*"
					end

					local out

					local files, dirs = file.Find(path, "GAME")

					if files then
						if path:StartWith("data/") then
							for i, name in ipairs(files) do
								local new_name, count = name:gsub("%^", "%.")
								if count > 0 then
									files[i] = new_name:sub(-4)
								end
							end
						end

						out = table.Add(files, dirs)
					end

					return out or {}
				end

				function fs.getcd()
					dprint("fs.getcd")
					return ""
				end

				function fs.setcd(path)
					dprint("fs.setcd: ", path)
				end

				function fs.createdir(path)
					dprint("fs.createdir: ", path)

					local path, where = get_path(path, true)

					file.CreateDir(path, where)
				end

				function fs.getattributes(path)
					dprint("fs.getattributes: ", path)
					local path, where = get_path(path, false, true)

					if file.Exists(path, where) then
						local size = file.Size(path, where)
						local time = file.Time(path, where)
						local type = file.IsDir(path, where) and "directory" or "file"

						dprint("\t", size)
						dprint("\t", time)
						dprint("\t", type)

						return {
							creation_time = time,
							last_accessed = time,
							last_modified = time,
							last_changed = time,
							size = size,
							type = type,
						}
					else
						dprint("\t" .. path .. " " .. where .. " does not exist")
					end

					return false
				end

				env.fs = fs

				fs.createdir("data/goluwa")

				function env.os.remove(path)
					local path, where = get_path(path)

					if file.Exists(path, where) then
						file.Delete(path, where)
						return true
					end

					return nil, filename .. ": No such file or directory", 2
				end

				function env.os.rename(a, b)
					local a, where_a = get_path(a)
					local b, where_b = get_path(b)

					dprint("os.rename: " .. a .. " >> " .. b)

					if file.Exists(a, where_a) then
						local str = file.Read(a, where_a)
						dprint("file.Read", a, where_a, type(str), str and #str)

						if not str then return nil, a .. ": exists but file.Read returns nil" end

						dprint("file.Delete", a, where_a)
						file.Delete(a, where_a)

						dprint("file.Write", b, #str)
						file.Write(b, str)
						return true
					end

					return nil, a .. ": No such file or directory", 2
				end

				function env.os.tmpname()
					return "os_tmpname_" .. util.CRC(RealTime())
				end

				local META = {}
				META.__index = META

				function META:__tostring()
					return ("file (%p)"):format(self)
				end

				function META:write(...)

					local str = ""

					for i = 1, select("#", ...) do
						str = str .. tostring((select(i, ...)))
					end

					dprint("file " .. self.__path .. ":write: ", #str)

					self.__file:Write(str)
				end

				local function read(self, format)
					if type(format) == "number" then
						return self.__file:Read(format)
					elseif format:sub(1, 2) == "*a" then
						return self.__file:Read(self.__file:Size())
					elseif format:sub(1, 2) == "*l" then
						local str = ""
						for i = 1, self.__file:Size() do
							local char = self.__file:Read(1)
							if char == "\n" then break end
							str = str .. char
						end
						return str ~= "" and str or nil
					elseif format:sub(1, 2) == "*n" then
						local str = self.__file:Read(1)
						if tonumber(str) then
							return tonumber(str)
						end
					end
				end

				function META:read(...)
					dprint("file " .. self.__path .. ":read: ", ...)

					local args = {}

					for i = 1, select("#", ...) do
						args[i] = read(self, select(i, ...))
					end

					return unpack(args)
				end

				function META:close()
					self.__file:Close()
				end

				function META:flush()
					self.__file:Flush()
				end

				function META:seek(whence, offset)
					offset = offset or 0

					if whence == "set" then
						self.__file:Seek(offset)
					elseif whence == "end" then
						self.__file:Seek(self.__file:Size())
					elseif whence == "cur" then
						self.__file:Seek(self.__file:Tell() + offset)
					end

					return self.__file:Tell()
				end

				function META:lines()
					return function()
						return self:Read("*line")
					end
				end

				function META:setvbuf()

				end

				function io.open(path, mode)
					mode = mode or "r"

					local self = setmetatable({}, META)

					local path, where = get_path(path, false, not mode:find("w"))

					local f = file.Open(path, mode, where)
					dprint("file.Open: ", f, path, mode, where)

					if not f then
						return nil, path .. " " .. mode .. " " .. where .. ": No such file", 2
					end

					self.__file = f
					self.__path = path
					self.__mode = mode

					return self
				end
			end

			io.stdin = io.open("stdin", "r")
			io.stdout = io.open("stdout", "w")

			local current_file = io.stdin

			function io.input(var)
				if io.type(var) == "file" then
					current_file = var
				else
					current_file = io.open(var)
				end

				return current_file
			end

			function io.type(var)
				if getmetatable(var) == META then
					return "file"
				end

				return nil
			end

			function io.write(...)
				local str = ""

				for i = 1, select("#", ...) do
					str = str .. tostring(select(i, ...))
				end

				Msg(str)
			end

			function io.read(...) return current_file:read(...) end

			function io.lines(...) return current_file:lines(...) end

			function io.flush(...) return current_file:flush(...) end

			function io.popen(...) dprint("io.popen: ", ...) end

			function io.close(...) return current_file:close(...) end

			function io.tmpfile(...) return io.open(os.tmpname(), "w")  end

			env.io = io
		end

		do -- require
			local stdlibs =
			{
				table = table,
				math = math,
				string = string,
				debug = debug,
				io = io,
				table = table,
				os = os,
			}

			local special = {
				ffi = true,
				["table.gcnew"] = true,
				["table.clear"] = true,
				["table.new"] = true,
			}

			local old_gmod_require = _G.require

			function env.require(str, ...)
				if env[str] ~= nil then
					return env[str]
				end

				if stdlibs[str] then
					return stdlibs[str]
				end

				if special[str] then
					if type(special[str]) == "function" then
						return stdlibs[str](...)
					end

					error(str .. " not found", 2)
				end


				return old_gmod_require(str, ...)
			end
		end

		do -- std lua env
			local _G = env

			_G._G = _G
			_G._VERSION = _VERSION

			_G.assert = assert
			_G.collectgarbage = collectgarbage
			_G.error = error
			_G.getfenv = getfenv
			_G.getmetatable = getmetatable
			_G.ipairs = ipairs
			_G.load = load
			_G.module = module
			_G.next = next
			_G.pairs = pairs
			_G.pcall = pcall
			_G.print = print
			_G.rawequal = rawequal
			_G.rawget = rawget
			_G.rawset = rawset
			_G.select = select
			_G.setfenv = setfenv
			_G.setmetatable = setmetatable
			_G.tonumber = tonumber
			_G.tostring = tostring
			_G.type = type
			_G.unpack = unpack
			_G.xpcall = xpcall

			_G.coroutine = {}
			_G.coroutine.create = coroutine.create
			_G.coroutine.resume = coroutine.resume
			_G.coroutine.running = coroutine.running
			_G.coroutine.status = coroutine.status
			_G.coroutine.wrap = coroutine.wrap
			_G.coroutine.yield = coroutine.yield

			_G.debug = {}
			_G.debug.debug = debug.debug
			_G.debug.getfenv = debug.getfenv
			_G.debug.gethook = debug.gethook
			_G.debug.getinfo = debug.getinfo
			_G.debug.getlocal = debug.getlocal
			_G.debug.getmetatable = debug.getmetatable
			_G.debug.getregistry = debug.getregistry
			_G.debug.getupvalue = debug.getupvalue
			_G.debug.setfenv = debug.setfenv
			_G.debug.sethook = debug.sethook
			_G.debug.setlocal = debug.setlocal
			_G.debug.setmetatable = debug.setmetatable
			_G.debug.setupvalue = debug.setupvalue
			_G.debug.traceback = debug.traceback

			_G.math = {}
			_G.math.abs = math.abs
			_G.math.acos = math.acos
			_G.math.asin = math.asin
			_G.math.atan = math.atan
			_G.math.atan2 = math.atan2
			_G.math.ceil = math.ceil
			_G.math.cos = math.cos
			_G.math.cosh = math.cosh
			_G.math.deg = math.deg
			_G.math.exp = math.exp
			_G.math.floor = math.floor
			_G.math.fmod = math.fmod
			_G.math.frexp = math.frexp
			_G.math.huge = math.huge
			_G.math.ldexp = math.ldexp
			_G.math.log = math.log
			_G.math.log10 = math.log10
			_G.math.max = math.max
			_G.math.min = math.min
			_G.math.modf = math.modf
			_G.math.pi = math.pi
			_G.math.pow = math.pow
			_G.math.rad = math.rad
			_G.math.random = math.random
			_G.math.randomseed = math.randomseed
			_G.math.sin = math.sin
			_G.math.sinh = math.sinh
			_G.math.sqrt = math.sqrt
			_G.math.tan = math.tan
			_G.math.tanh = math.tanh

			_G.package = {}
			_G.package.cpath = package.cpath
			_G.package.loaded = package.loaded
			_G.package.loaders = package.loaders
			_G.package.loadlib = package.loadlib
			_G.package.path = package.path
			_G.package.preload = package.preload
			_G.package.seeall = package.seeall

			_G.string = {}
			_G.string.byte = string.byte
			_G.string.char = string.char
			_G.string.dump = string.dump
			_G.string.find = string.find
			_G.string.format = string.format
			_G.string.gmatch = string.gmatch
			_G.string.gsub = string.gsub
			_G.string.len = string.len
			_G.string.lower = string.lower
			_G.string.match = string.match
			_G.string.rep = string.rep
			_G.string.reverse = string.reverse
			_G.string.sub = string.sub
			_G.string.upper = string.upper

			_G.table = {}
			_G.table.concat = table.concat
			_G.table.insert = table.insert
			_G.table.maxn = table.maxn
			_G.table.remove = table.remove
			_G.table.sort = table.sort
		end
	end

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

	env.pvars = env.runfile("lua/libraries/pvars.lua")
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

function goluwa.Initialize()
	dprint("initializing goluwa ...")
	local time = SysTime()
	goluwa.env = goluwa.CreateEnv()
	_G.goluwa = goluwa

	notagain.AutorunDirectory("goluwa")
	dprint("initializing goluwa took " .. (SysTime() - time) .. " seconds")
end

function goluwa.SetEnv()
	setfenv(2, goluwa.env)
end

if CLIENT then
	goluwa.Update(goluwa.Initialize)
end

return goluwa
