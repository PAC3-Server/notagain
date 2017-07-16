local env = {}

if SERVER then -- wip

	local function add(dir)
		local files, directories = file.Find(dir .. "/*", "LUA")

		for _, file_name in ipairs(files) do
			print(dir .. "/" .. file_name, "!!!!!")
			AddCSLuaFile(dir .. "/" .. file_name)
		end

		for _, d in ipairs(directories) do
			add(dir .. "/" .. d)
		end
	end

	AddCSLuaFile()
	add("notagain/goluwa/goluwa")

	return env
end

local urlimage = requirex("urlimage")
local msgpack = requirex("msgpack")
local mp3duration = requirex("mp3duration")
local prettytext = requirex("pretty_text")

local function print(...)
	if env.DEBUG then
		_G.print(...)
	end
end

function env.runfile(path, ...)
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

function env.desire()

end

do -- lua env
	local handle_path = function(path, plain)
		file.CreateDir("stdlua") -- hhh

		path = "stdlua/" .. path

		if not plain then
			path = (path):gsub("%.", "_") .. ".txt"
		end

		return path
	end

	do -- _G
		function env.loadstring(str, env)
			local var = CompileString(str, env or "loadstring", false)
			if type(var) == "string" then
				return nil, var, 2
			end
			return setfenv(var, getfenv(1))
		end

		function env.loadfile(str)
			if not file.Exists(handle_path(str, true), "DATA") then
				return nil, str .. ": No such file", 2
			end
			local lua = file.Read(handle_path(str, true), "DATA")
			return loadstring(lua, str)
		end

		function env.dofile(filename)
			local f = assert(loadfile(filename))
			return f()
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
			print("os.setlocale: ", ...)
		end

		function os.execute(...)
			print("os.execute: ", ...)
		end

		function os.exit(...)
			print("os.exit: ", ...)
		end

		function os.remove(filename)
			if file.Exists(handle_path(filename), "DATA") then
				file.Delete(handle_path(filename), "DATA")
				return true
			end

			return nil, "data/" .. filename .. ": No such file or directory", 2
		end

		function os.rename(a, b)
			if file.Exists(handle_path(filename), "DATA") then
				local str = file.Read(handle_path(a), "DATA")
				file.Delete(handle_path(b), "DATA")
				file.Write(handle_path(b), str, "DATA")
				return true
			end

			return nil, "data/" .. a .. ": No such file or directory", 2
		end

		function os.tmpname()
			return "data/temp/" .. util.CRC(RealTime()) .. ".txt"
		end

		os.clock = _G.os.clock
		os.date = _G.os.date
		os.difftime = _G.os.difftime
		os.time = _G.os.time

		env.os = os
	end

	do -- io
		local io = {}

		local META = {}
		META.__index = META

		function META:__tostring()
			return ("file (%p)"):format(self)
		end

		function META:write(...)

			local str = ""

			for i = 1, select("#", ...) do
				str = str .. tostring(select(i, ...))
			end

			self.__data = str

			if self.__path:sub(0, 5) == "data/" then
				file.Write(handle_path(self.__path:sub(6)), self.__data, "DATA")
			else
				file.Write(handle_path(self.__path), self.__data, "DATA")
			end
		end

		local function read(self, format)
			format = format or "*line"

			self.__seekpos = self.__seekpos or 0

			if type(format) == "number" then
				return self.__data:sub(0, format)
			elseif format:sub(1, 2) == "*a" then
				return self.__data:sub(self.__seekpos)
			elseif format:sub(1, 2) == "*l" then
				if not self.__data:find("\n", nil, true) then
					if self.__data == "" then return nil end

					local str = self.__data
					self.__data = ""

					return str
				else
					local val = self.__data:match("(.-)\n")
					self.__data = self.__data:match(".-\n(.+)")

					return val
				end
			elseif format:sub(1, 2) == "*n" then
				local str = read("*line")
				if str then
					local numbers = {}
					str:gsub("(%S+)", function(str) table.insert(numbers, tonumber(str)) end)
					return unpack(numbers)
				end
			end
		end

		function META:read(...)
			local args = {...}

			for k, v in pairs(args) do
				args[k] = read(self, v) or nil
			end

			return unpack(args) or nil
		end

		function META:close()

		end

		function META:flush()

		end

		function META:seek(whence, offset)
			whence = whence or "cur"
			offset = offset or 0

			self.__seekpos = self.__seekpos or 0

			if whence == "set" then
				self.__seekpos = offset
			elseif whence == "end" then
				self.__seekpos = #self.__data
			elseif whence == "cur" then
				self.__seekpos = self.__seekpos + offset
			end

			return math.Clamp(self.__seekpos, 0, #self.__data)
		end

		function META:lines()
			return self.__data:gmatch("(.-)\n")
		end

		function META:setvbuf()

		end

		function io.open(filename, mode)
			mode = mode or "r"

			if not file.Exists(handle_path(filename), "DATA") and mode == "w" then
				error("No such file or directory", 2)
			end

			local self = setmetatable({}, META)

			self.__data = file.Read(handle_path(filename), "DATA")
			self.__path = filename
			self.__mode = mode

			return self
		end

		io.stdin = setmetatable({}, META)
		io.stdin.__data = ""

		io.stdout = setmetatable({}, META)
		io.stdout.__data = ""

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
				return file
			end

			return nil
		end

		function io.read(...) return current_file:read(...) end

		function io.lines(...) return current_file:lines(...) end

		function io.flush(...) return current_file:flush(...) end

		function io.popen(...) print("io.popen: ", ...) end

		function io.close(...) return current_file:close(...) end

		function io.tmpfile(...) return current_file:flush(...)  end

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

		function env.require(str, ...)
			local args = {pcall(old_gmod_require, str, ...)}

			if args[1] == false then
				error(args[2],  2)
			else
				table.remove(args, 1)

				if args[1] == nil then
					return stdlibs[str]
				end

				return unpack(args)
			end
		end
	end

	do -- std lua env
		local _G = env

		_G._G = _G
		_G._VERSION = _VERSION

		_G.assert = assert
		_G.collectgarbage = collectgarbage
		_G.dofile = dofile
		_G.error = error
		_G.getfenv = getfenv
		_G.getmetatable = getmetatable
		_G.ipairs = ipairs
		_G.load = load
		_G.loadfile = loadfile
		_G.loadstring = loadstring
		_G.module = module
		_G.next = next
		_G.pairs = pairs
		_G.pcall = pcall
		_G.print = _G.print
		_G.rawequal = rawequal
		_G.rawget = rawget
		_G.rawset = rawset
		_G.require = require
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

env.runfile("goluwa/libraries/extensions/string.lua")
env.runfile("goluwa/libraries/extensions/table.lua")
env.runfile("goluwa/libraries/extensions/math.lua")
env.utf8 = env.runfile("goluwa/libraries/utf8.lua")

local http = table.Copy(http)
local sound = table.Copy(sound)

do
	-- just to debug any http requests
	function http.Fetch(url, ...)
		--print("http.Fetch: " .. url)
		_G.http.Fetch(url, ...)
	end
end

if system.IsLinux() then -- sound.PlayFile fix
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

function env.loadstring(str, env)
	local var = CompileString(str, env or "loadstring", false)
	if type(var) == "string" then
		return nil, var, 2
	end
	return setfenv(var, getfenv(1))
end

function env.typex(val)
	if IsColor(val) then
		return "color"
	end

	return type(val)
end

do
	local utility = {}

	function utility.CreateWeakTable()
		return setmetatable({}, {__mode = "kv"})
	end

	function utility.MakePushPopFunction(lib, name, func_set, func_get, reset)
		func_set = func_set or lib["Set" .. name]
		func_get = func_get or lib["Get" .. name]

		local stack = {}
		local i = 1

		lib["Push" .. name] = function(...)
			stack[i] = stack[i] or {}
			stack[i][1], stack[i][2], stack[i][3], stack[i][4] = func_get()

			func_set(...)

			i = i + 1
		end

		lib["Pop" .. name] = function()
			i = i - 1

			if i < 1 then
				error("stack underflow", 2)
			end

			if i == 1 and reset then
				reset()
			end

			func_set(stack[i][1], stack[i][2], stack[i][3], stack[i][4])
		end
	end
	env.utility = utility
end


do
	local prototype = {}

	function prototype.CreateObject(META, o)
		local self = setmetatable(o or {}, META)

		return self
	end

	function prototype.CreateTemplate()
		local META = {}
		META.__index = META

		function META:GetSet(key, def)
			local t = type(def)
			local force

			if t == "number" then
				force = FORCE_NUMBER
			elseif t == "string" then
				force = FORCE_STRING
			elseif t == "boolean" then
				force = FORCE_BOOLEAN
			end

			AccessorFunc(META, key, key, force)

			META[key] = def
		end

		function META:IsSet(key, def)
			self:GetSet(key, def)
			local func = self["Get" .. key]
			self["Is" .. key] = func

			META[key] = def
		end

		function META:Register()

		end

		return META
	end

	env.prototype = prototype
end

do -- texture
	local render = {}

	function render.CreateTextureFromPath(path)
		if path:StartWith("materials/") then
			path = path:sub(#"materials/" + 1)
			print(path)
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

do -- commands
	local commands = {}

	function commands.RunString(str)
		LocalPlayer():ConCommand(str)
	end

	env.commands = commands
end

do -- log
	function env.logf(str, ...)
		MsgN("goluwa: " .. string.format(str, ...))
	end

	function env.logn(...)
		local str = ""

		for i = 1, select("#", ...) do
			str = str .. tostring(select(i, ...))
		end

		MsgN("goluwa: " .. str)
	end

	function env.wlog(...)
		env.logf(...)
	end

	function env.llog(...)
		env.logf(...)
	end

	function env.log(...)
		local str = ""

		for i = 1, select("#", ...) do
			str = str .. tostring(select(i, ...))
		end

		Msg("goluwa: " .. str)
	end
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
	local event = {}

	function event.Delay(time, cb)
		timer.Simple(time, cb)
	end

	function event.AddListener(event, id, cb)
		if event == "Update" then
			event = "Think"
		end

		hook.Add(event, id, cb)
	end

	function event.RemoveListener(event, id)
		if event == "Update" then
			event = "Think"
		end

		hook.Remove(event, id)
	end

	env.event = event
end

do
	local system = {}

	function system.GetElapsedTime()
		return SysTime()
	end

	function system.GetFrameTime()
		return FrameTime()
	end

	function system.OpenURL(url)
		gui.OpenURL(url)
	end

	env.system = system
end

do -- serializer
	local serializer = {}

	function serializer.ReadFile(lib, path)
		return msgpack.unpack(env.vfs.Read(path))
	end

	env.serializer = serializer
end

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

do
	local vfs = {}

	local illegal_characters = {
		[":"] = "_semicolon_",
		["*"] = "_star_",
		["?"] = "_questionmark_",
		["<"] = "_less_than_",
		[">"] = "_greater_than_",
		["|"] = "_line_",
	}

	function vfs.FixIllegalCharactersInPath(path)
		for k,v in pairs(illegal_characters) do
			path = path:gsub("%"..k, v)
		end
		return path
	end

	function vfs.Find(path)
		if path:EndsWith("/") then
			path = path .. "*"
		end

		local where = "GAME"

		if path:StartWith("data/") then
			path = path:gsub("data/", "goluwa/")
			where = "DATA"
		end

		local tbl = table.Merge(file.Find(path, where))

		if not tbl[1] then
			tbl = table.Merge(file.Find(path, "DATA"))
		end

		return tbl
	end

	function vfs.Read(path)
		if path:StartWith("data/") then
			path = path:gsub("(.+)%..+", "%1.txt")
			path = path:gsub("data/", "goluwa/")

			if not file.Exists(path, "DATA") then
				print("vfs.Read data: file does not exist", path)
			end

			return file.Read(path, "DATA")
		end

		if not file.Exists(path, "GAME") then
			print("vfs.Read game: file does not exist", path)
		end

		return file.Read(path, "GAME")
	end

	function vfs.Exists(path)
		if path:StartWith("data/") then
			local path = path:gsub("(.+)%..+", "%1.txt")
			path = path:gsub("^data/", "goluwa/")

			if not file.Exists(path, "DATA") then
				print("vfs.Exists data: file does not exist", path)
			end

			if file.Exists(path, "DATA") then
				return true
			end
		end

		if file.Exists(path, "GAME") then
			return true
		end

		return false
	end

	vfs.IsFile = vfs.Exists

	env.vfs = vfs
end

do
	local resource = {}

	function resource.Download(path, cb)
		if path:StartWith("http") then
			local cache_path = "goluwa/downloads/" .. util.CRC(path) .. ".txt"

			if file.Exists(cache_path, "DATA") then
				cache_path = cache_path:gsub("^goluwa/downloads/", "data/downloads/")
				cb(cache_path)
			else
				path = path:gsub(" ", "%%20")
				http.Fetch(path, function(data)
					file.CreateDir("goluwa")
					file.CreateDir("goluwa/downloads")
					file.Write(cache_path, data)

					cache_path = cache_path:gsub("^goluwa/downloads/", "data/downloads/")
					cb(cache_path)
				end)
			end
		else
			if path:StartWith("data/") then
				path = path:gsub("(.+)%..+", "%1.txt")
				path = path:gsub("data/", "goluwa/")

				if not file.Exists(path, "DATA") then
					print("resource.Download data: file does not exist", path)
				end

				if file.Exists(path, "DATA") then
					local path = path:gsub("^goluwa/", "data/")
					cb(path)
					return
				end
			end

			if file.Exists(path, "GAME") then
				cb(path)
			end
		end
	end
	env.resource = resource
end

do
	local audio = {}

	audio.player_object = NULL

	function audio.CreateSource(path)
		if path:StartWith("http") then
			local url = path
			local snd
			local dbg_str
			local self = {}

			local ply = audio.player_object

			env.resource.Download(path, function(path)
				path = path:gsub("data/", "../data/goluwa/")
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

										snd:SetVolume((self.gain or 1) * f)
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

_G.goluwa = env

for k,v in pairs(env.string) do
	_G.string[k] = _G.string[k] or v
end

return env