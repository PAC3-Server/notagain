local env = ... or _G.goluwa

env.jit = table.Copy(_G.jit)
env.newproxy = _G.newproxy

file.CreateDir("goluwa")

local function data_path(path)
	return "goluwa/" .. path:gsub("%.", "_") .. ".txt"
end

do -- _G
	function env.loadstring(str, env)
		local var = CompileString(str, env or "loadstring", false)
		if type(var) == "string" then
			return nil, var, 2
		end
		return setfenv(var, getfenv(1))
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
		print("os.setlocale: ", ...)
	end

	function os.execute(...)
		print("os.execute: ", ...)
	end

	function os.exit(...)
		print("os.exit: ", ...)
	end

	function os.remove(filename)
		filename = data_path(filename)

		if file.Exists(filename, "DATA") then
			file.Delete(filename, "DATA")
			return true
		end

		return nil, filename .. ": No such file or directory", 2
	end

	function os.rename(a, b)
		a = data_path(a)
		b = data_path(b)

		if file.Exists(a, "DATA") then
			local str = file.Read(a, "DATA")
			file.Delete(a, "DATA")
			file.Write(b, "DATA")
			return true
		end

		return nil, a .. ": No such file or directory", 2
	end

	function os.tmpname()
		return data_path(util.CRC(RealTime()))
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
			str = str .. tostring((select(i, ...)))
		end

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
		local args = {}

		for i = 1, select("#", ...) do
			args[k] = read(self, select(i, ...))
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

		local where = "GAME"

		if mode:find("w", nil, true) then
			path = data_path(path)
			where = "DATA"
		end

		local f = file.Open(path, mode, where)

		if not f then
			return nil, path .. " " .. mode .. " " .. where .. ": No such file", 2
		end

		self.__file = f
		self.__path = path
		self.__mode = mode

		return self
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