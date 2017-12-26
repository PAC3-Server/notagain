local msgpack = requirex("msgpack")
local prettytext = CLIENT and requirex("pretty_text")
local common_audio = CLIENT and requirex("common_audio")

AddCSLuaFile()

local goluwa = {}

goluwa.notagain_autorun = false

local function dprint(...)
	print("goluwa: ", ...)
end

local next_print = 0

local function download_path(path, cb)
	do -- create directories
		local done = {}
		local dir = (path:match("(.+)/.-%.lua") or path)
		if not dir:EndsWith("/") then
			dir = dir .. "/"
		end
		if not done[dir] then
			local folder_path = ""
			for folder in dir:gmatch("(.-/)") do
				folder_path = folder_path .. folder
				if not done[folder_path] then
					file.CreateDir("goluwa/goluwa/" .. folder_path)
					done[folder_path] = true
				end
			end
			done[dir] = true
		end
	end

	local function download(lua, _,_, code)
		if code == 200 then
			file.Write("goluwa/goluwa/" .. path:gsub("%.", "^") .. ".txt", lua)
			cb()
		else
			dprint(lua)
			dprint(path .. " failed to download with error code: " .. code)

			if code == 503 then
				dprint("trying " .. path .. " again because it timed out")
				http.Fetch("https://raw.githubusercontent.com/CapsAdmin/goluwa/master/" .. path, download)
			end
		end
	end

	http.Fetch("https://raw.githubusercontent.com/CapsAdmin/goluwa/master/" .. path, download)
end

local function download_paths(paths, cb)
	local count = table.Count(paths)

	if count == 0 then
		cb()
		return
	end

	local left = count

	dprint("downloading " .. count .. " files")

	if count < 10 then
		for path in pairs(paths) do
			print(path)
		end
	end

	for path in pairs(paths) do
		download_path(path, function()
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
end
function goluwa.Update(cb)
	local prev_commit = file.Read("goluwa/prev_commit.txt", "DATA")

	if
		not prev_commit or
		not file.IsDir("goluwa/", "DATA") or
		not file.IsDir("goluwa/goluwa", "DATA") or
		not file.IsDir("goluwa/goluwa/core", "DATA") or
		not file.Exists("goluwa/goluwa/github_recursive.txt", "DATA")
	then
		http.Fetch("https://api.github.com/repos/CapsAdmin/goluwa/git/trees/master?recursive=1", function(body, _,_, code)
			if code ~= 200 then
				ErrorNoHalt("goluwa: " .. body)
				return
			end

			file.CreateDir("goluwa/")
			file.CreateDir("goluwa/goluwa/")

			file.Write("goluwa/goluwa/github_recursive.txt", body)

			dprint("downloading files for first time")

			http.Fetch("https://api.github.com/repos/CapsAdmin/goluwa/commits", function(body, _,_, code)
				if code ~= 200 then
					ErrorNoHalt("goluwa: " .. body)
					return
				end

				local head = body:match('^.-"sha":%s-"(.-)"')
				dprint("last commit is: " .. head)
				file.Write("goluwa/prev_commit.txt", head)
			end)

			local paths = {}

			for path in body:gmatch('"path":%s-"(.-/lua/libraries/.-)"') do
				if path:EndsWith(".lua") then
					paths[path] = path
				end
			end

			download_paths(paths, cb)
		end)
	else
		local tbl = util.JSONToTable(file.Read("goluwa/goluwa/github_recursive.txt", "DATA"))
		local paths = {}

		for _, info in pairs(tbl.tree) do
			if info.path:find("lua/libraries/", nil, true) then
				if info.path:EndsWith(".lua") and not file.Exists("goluwa/goluwa/" .. info.path:gsub("%.", "^") .. ".txt", "DATA") then
					paths[info.path] = info.path
					dprint("downloading " .. info.path .. " becasue it's missing")
				end
			end
		end

		download_paths(paths, function()
			local head = ""
			http.Fetch("https://api.github.com/repos/CapsAdmin/goluwa/commits/HEAD", function(body, _,_, code)
				if code ~= 200 then
					dprint(body)
					cb()
					return
				end

				head = body:match('^.-"sha":%s-"(.-)"')
				file.Write("goluwa/prev_commit.txt", head)

				if head == prev_commit then
					dprint("everything is already up to date")
					cb()
					return
				end


				http.Fetch("https://api.github.com/repos/CapsAdmin/goluwa/compare/" .. prev_commit .. "..." .. head, function(body, _,_, code)
					if code ~= 200 then
						dprint(body)
						cb()
						return
					end

					local tbl = util.JSONToTable(body)

					local paths = {}

					for _, info in pairs(tbl.files) do
						if info.filename:find("lua/libraries/", nil, true) then
							if info.status == "modified" or info.status == "added" then
								paths[info.filename] = info.filename
								dprint(info.filename .. " was modified")
							elseif info.status == "renamed" then
								dprint(info.previous_filename .. " was renamed to " .. info.filename)

								file.Delete("goluwa/goluwa/" .. info.previous_filename:gsub("%.", "^") .. ".txt")
							end
						end
					end

					download_paths(paths, cb)
				end)
			end)
		end)
	end
end

function goluwa.CreateEnv()
	local env = {}
	env._G = env

	env.e = {}

	do
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

				local function uncache(path)
					dprint("uncaching " .. path)
					env.fs.find_cache[path:match("(.+/)")] = nil
					env.fs.get_attributes_cache[path] = nil
				end

				local allowed = {
					[".txt"] = true,
					[".jpg"] = true,
					[".png"] = true,
					[".vtf"] = true,
					[".dat"] = true,
				}

				function env.GoluwaToGmodPath(path)
					if path:StartWith("/") then
						path = path:sub(2)
					end

					local where = "GAME"

					if path:StartWith("data/") then
						path = path:sub(6)
						where = "DATA"

						if not file.IsDir(path, where) then
							local dir, file_name = path:match("(.+/)(.+)")

							if not dir then
								dir = ""
								file_name = path
							end

							if not allowed[path:sub(-4)] then
								file_name = file_name:gsub("%.", "%^")
								file_name = file_name .. ".dat"
							end

							return dir .. file_name, where
						end
					end

					return path, where
				end

				local fs = {}

				fs.find_cache = {}
				fs.get_attributes_cache = {}

				function fs.find(path)
					dprint("fs.find: ", path)

					if path:startswith("/") then
						path = path:sub(2)
					end

					local original_path = path

					dprint("fs.find: is " .. path .. " cached?")

					if fs.find_cache[path] then
						dprint("yes!")
						return fs.find_cache[path]
					end

					if path:endswith("/") then
						path = path .. "*"
					end

					local where = "GAME"

					if path:StartWith("data/") then
						path = path:sub(6)
						where = "DATA"
					end

					local out

					local files, dirs = file.Find(path, where)

					if files then
						if where == "DATA" then
							for i, name in ipairs(files) do
								local new_name, count = name:gsub("%^", "%.")

								if count > 0 then
									files[i] = new_name:sub(0, -5)
								end
							end
						end

						out = table.Add(files, dirs)
					end

					fs.find_cache[original_path] = out
					dprint("fs.find: caching results for dir " .. path)

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

					local path, where = env.GoluwaToGmodPath(path)

					file.CreateDir(path, where)
				end

				function fs.getattributes(path)
					dprint("fs.getattributes: ", path)
					local original_path = path

					if fs.get_attributes_cache[path] ~= nil then
						return fs.get_attributes_cache[path]
					end

					local path, where = env.GoluwaToGmodPath(path)

					if file.Exists(path, where) then
						local size = file.Size(path, where)
						local time = file.Time(path, where)
						local type = file.IsDir(path, where) and "directory" or "file"

						dprint("\t", size)
						dprint("\t", time)
						dprint("\t", type)

						local res = {
							creation_time = time,
							last_accessed = time,
							last_modified = time,
							last_changed = time,
							size = size,
							type = type,
						}

						fs.get_attributes_cache[original_path] = res

						return res
					else
						dprint("\t" .. path .. " " .. where .. " does not exist")
					end

					fs.get_attributes_cache[original_path] = false

					return false
				end

				env.fs = fs

				fs.createdir("data/goluwa")
				fs.createdir("data/goluwa/goluwa")

				function env.os.remove(path)
					uncache(path)

					local path, where = env.GoluwaToGmodPath(path)

					if file.Exists(path, where) then
						file.Delete(path, where)
						return true
					end

					return nil, filename .. ": No such file or directory", 2
				end

				function env.os.rename(a, b)
					uncache(a)
					uncache(b)

					local a, where_a = env.GoluwaToGmodPath(a)
					local b, where_b = env.GoluwaToGmodPath(b)


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

					if self.uncache_on_write then
						uncache(self.uncache_on_write)
					end
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

					local original_path = path

					local self = setmetatable({}, META)

					local path, where = env.GoluwaToGmodPath(path)

					local f = file.Open(path, mode, where)
					dprint("file.Open: ", f, path, mode, where)

					if not f then
						return nil, path .. " " .. mode .. " " .. where .. ": No such file", 2
					end

					if mode:find("w") then
						self.uncache_on_write = original_path
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
			env._VERSION = _VERSION

			env.assert = assert
			env.collectgarbage = collectgarbage
			env.error = error
			env.getfenv = getfenv
			env.getmetatable = getmetatable
			env.ipairs = ipairs
			env.load = load
			env.module = module
			env.next = next
			env.pairs = pairs
			env.pcall = pcall
			env.print = print
			env.rawequal = rawequal
			env.rawget = rawget
			env.rawset = rawset
			env.select = select
			env.setfenv = setfenv
			env.setmetatable = setmetatable
			env.tonumber = tonumber
			env.tostring = tostring
			env.type = type
			env.unpack = unpack
			env.xpcall = xpcall

			env.coroutine = {}
			env.coroutine.create = coroutine.create
			env.coroutine.resume = coroutine.resume
			env.coroutine.running = coroutine.running
			env.coroutine.status = coroutine.status
			env.coroutine.wrap = coroutine.wrap
			env.coroutine.yield = coroutine.yield

			env.debug = {}
			env.debug.debug = debug.debug
			env.debug.getfenv = debug.getfenv
			env.debug.gethook = debug.gethook
			env.debug.getinfo = debug.getinfo
			env.debug.getlocal = debug.getlocal
			env.debug.getmetatable = debug.getmetatable
			env.debug.getregistry = debug.getregistry
			env.debug.getupvalue = debug.getupvalue
			env.debug.setfenv = debug.setfenv
			env.debug.sethook = debug.sethook
			env.debug.setlocal = debug.setlocal
			env.debug.setmetatable = debug.setmetatable
			env.debug.setupvalue = debug.setupvalue
			env.debug.traceback = debug.traceback

			env.math = {}
			env.math.abs = math.abs
			env.math.acos = math.acos
			env.math.asin = math.asin
			env.math.atan = math.atan
			env.math.atan2 = math.atan2
			env.math.ceil = math.ceil
			env.math.cos = math.cos
			env.math.cosh = math.cosh
			env.math.deg = math.deg
			env.math.exp = math.exp
			env.math.floor = math.floor
			env.math.fmod = math.fmod
			env.math.frexp = math.frexp
			env.math.huge = math.huge
			env.math.ldexp = math.ldexp
			env.math.log = math.log
			env.math.log10 = math.log10
			env.math.max = math.max
			env.math.min = math.min
			env.math.modf = math.modf
			env.math.pi = math.pi
			env.math.pow = math.pow
			env.math.rad = math.rad
			env.math.random = math.random
			env.math.randomseed = math.randomseed
			env.math.sin = math.sin
			env.math.sinh = math.sinh
			env.math.sqrt = math.sqrt
			env.math.tan = math.tan
			env.math.tanh = math.tanh

			env.package = {}
			env.package.cpath = package.cpath
			env.package.loaded = package.loaded
			env.package.loaders = package.loaders
			env.package.loadlib = package.loadlib
			env.package.path = package.path
			env.package.preload = package.preload
			env.package.seeall = package.seeall

			env.string = {}
			env.string.byte = string.byte
			env.string.char = string.char
			env.string.dump = string.dump
			env.string.find = string.find
			env.string.format = string.format
			env.string.gmatch = string.gmatch
			env.string.gsub = string.gsub
			env.string.len = string.len
			env.string.lower = string.lower
			env.string.match = string.match
			env.string.rep = string.rep
			env.string.reverse = string.reverse
			env.string.sub = string.sub
			env.string.upper = string.upper

			env.table = {}
			env.table.concat = table.concat
			env.table.insert = table.insert
			env.table.maxn = table.maxn
			env.table.remove = table.remove
			env.table.sort = table.sort

			env.bit = {}
			env.bit.tobit = bit.tobit
			env.bit.tohex = bit.tohex
			env.bit.bnot = bit.bnot
			env.bit.band = bit.band
			env.bit.bor = bit.bor
			env.bit.bxor = bit.bxor
			env.bit.lshift = bit.lshift
			env.bit.rshift = bit.rshift
			env.bit.arshift = bit.arshift
			env.bit.rol = bit.rol
			env.bit.ror = bit.ror
			env.bit.bswap = bit.bswap

			env.jit = {}
			env.jit.arch = jit.arch
			env.jit.version = jit.version
			env.jit.version_num = jit.version_num
			env.jit.status = jit.status
			env.jit.on = jit.on
			env.jit.os = jit.os
			env.jit.off = jit.off
			env.jit.flush = jit.flush
			env.jit.attach = jit.attach
			env.jit.util = jit.util
			env.jit.opt = jit.opt

			env.newproxy = _G.newproxy
		end
	end

	do
		env._OLD_G = {}
		local done = {[env._G] = true, [env.package.loaded] = true}
		local indent = 0
		local function scan(tbl, store)
			for key, val in pairs(tbl) do
				local t = type(val)
				if t == "table" and not done[val] and val ~= store then
					store[key] = store[key] or {}
					done[val] = true
					indent = indent + 1
					scan(val, store[key])
					indent = indent - 1
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
		env.freeimage = false
		env.opengl = false
		env["table.new"] = false
		env["table.clear"] = false
		env["deflatelua"] = false
		env["lunajson"] = false

		env.msgpack = {encode = msgpack.pack, decode = msgpack.unpack}
		env.msgpack2 = false
		env.von = false
	end

	local function execute(full_path, chunk_name, ...)
		if chunk_name:EndsWith(".txt") then debug.Trace() end
		local lua = file.Read(full_path, "DATA")
		local func = CompileString(lua, chunk_name, false)
		if type(func) == "function" then
			setfenv(func, env)
			return func(...)
		else
			MsgN(func)
		end
	end

	function env.runfile(path, ...)
		local original_path = path

		if path:EndsWith("*") then
			if env.dont_include_multiple_files then return end

			local dir = path:sub(0, -2)

			if not file.IsDir("goluwa/goluwa/" .. dir, "DATA") then
				local relative = debug.getinfo(2).source:match("@(.+)")

				if relative then
					dir = relative:match("(.+/).-%.lua") .. dir
				end
			end

			local files = file.Find("goluwa/goluwa/" .. dir .. "*", "DATA")

			for _, name in pairs(files) do
				execute("goluwa/goluwa/" .. dir .. name, dir .. name:gsub("%^lua%.txt", ".lua"),  ...)
			end

			return
		end

		if not path:EndsWith(".txt") then
			path = path:gsub("%.", "^") .. ".txt"
		end
		if file.Exists("goluwa/goluwa/" .. path, "DATA") then
			return execute("goluwa/goluwa/" .. path, original_path,  ...)
		else
			local relative = debug.getinfo(2).source:match("@(.+)")

			if relative then
				local dir = relative:match("(.+/).-%.lua")

				if file.Exists("goluwa/goluwa/" .. dir .. path, "DATA") then
					return execute("goluwa/goluwa/" .. dir .. path, dir .. original_path, ...)
				end
			end
		end
	end

	local commands_add_buffer = {}
	env.commands = {Add = function(...) table.insert(commands_add_buffer, {...}) end}

	env.runfile("core/lua/libraries/extensions/string.lua")
	env.runfile("core/lua/libraries/extensions/globals.lua")
	env.runfile("core/lua/libraries/extensions/debug.lua")
	env.runfile("core/lua/libraries/extensions/os.lua")
	env.runfile("core/lua/libraries/extensions/table.lua")
	env.runfile("core/lua/libraries/extensions/math.lua")
	env.utf8 = env.runfile("core/lua/libraries/utf8.lua")

	for k,v in pairs(env.string) do _G.string[k] = _G.string[k] or v end -- :(

	env.prototype = env.runfile("core/lua/libraries/prototype/prototype.lua")
	env.serializer = env.runfile("core/lua/libraries/serializer.lua")
	env.structs = env.runfile("framework/lua/libraries/structs.lua")

	env.utility = env.runfile("core/lua/libraries/utility.lua")

	env.vfs = env.runfile("core/lua/libraries/filesystem/vfs.lua")
	env.vfs.Mount("os:/data/goluwa/data/", "os:data/")
	env.vfs.Mount("os:/data/goluwa/data/", "os:")
	env.vfs.Mount("os:/data/goluwa/userdata/", "os:data/")
	env.vfs.Mount("os:/", "os:")
	env.R = env.vfs.GetAbsolutePath -- a nice global for loading resources externally from current dir
	env.crypto = env.runfile("core/lua/libraries/crypto.lua")

	env.pvars = env.runfile("engine/lua/libraries/pvars.lua")
	env.commands = env.runfile("engine/lua/libraries/commands.lua")
	for i, args in ipairs(commands_add_buffer) do env.commands.Add(unpack(args)) end

	do
		local window = {}

		function window.SetClipboard(str)
			SetClipboardText(str)
		end

		function window.GetClipboard()
			ErrorNoHalt("NYI")
		end

		function window.GetMousePosition()
			return env.Vec2(gui.MousePos())
		end

		function window.GetMouseTrapped()
			return false
		end

		function window.SetMouseTrapped(b)
			gui.EnableScreenClicker(not b)
		end

		function window.SetCursor(cursor)

		end

		function window.GetCursor()
			return "normal"
		end

		function window.GetSize()
			return env.Vec2(ScrW(), ScrH())
		end

		env.window = window

		local wnd = {}
		for k,v in pairs(env.window) do
			wnd[k] = function(self, ...) return v(...) end
		end
		goluwa.window = wnd
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

		function system.pcall(func, ...)
			return xpcall(func, system.OnError, ...)
		end

		env.system = system
	end

	env.profiler = env.runfile("engine/lua/libraries/profiler.lua")
	env.P = env.profiler.ToggleTimer
	env.I = env.profiler.ToggleInstrumental
	env.S = env.profiler.ToggleStatistical

	env.event = env.runfile("core/lua/libraries/event.lua")
	env.runfile("framework/lua/libraries/extensions/event_timers.lua")

	env.event.AddListener("EventAdded", "gmod", function(info)
	--	print("goluwa event added: ", info.event_type, info.id)
	end)

	env.event.AddListener("EventRemoved", "gmod", function(info)
	--	print("goluwa event removed: ", info.event_type, info.id)
	end)

	hook.Add("Think", "goluwa", function()
		env.event.UpdateTimers()
		env.event.Call("Update", FrameTime())
	end)

	env.expression = env.runfile("engine/lua/libraries/expression.lua")
	env.autocomplete = env.runfile("engine/lua/libraries/autocomplete.lua")

	do
		local sockets = {}
		env.SOCKETS = true
		env.runfile("framework/lua/libraries/sockets/http.lua", sockets)

		function sockets.Request(tbl)
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

		env.sockets = sockets
	end

	env.resource = env.runfile("framework/lua/libraries/sockets/resource.lua")

	do
		local backend = CreateClientConVar("goluwa_audio_backend", "webaudio")

		local audio = {}

		audio.player_object = NULL

		function audio.CreateSource(path)
			local snd = common_audio.CreateSoundFromInterface(backend:GetString())
			snd:SetEntity(audio.player_object)
			env.resource.Download(path, function(path)
				local path, where = env.GoluwaToGmodPath(path)
				snd:SetPath(path, where)
			end)

			return snd
		end

		function audio.Panic()
			common_audio.Panic()
		end

		env.audio = audio
	end

	env.chatsounds = env.runfile("game/lua/libraries/audio/chatsounds/chatsounds.lua")

	do
		local steam = {}

		function steam.MountSourceGame()

		end

		env.steam = steam
	end

	do -- rendering
		local cam_PushModelMatrix = cam.PushModelMatrix
		local cam_PopModelMatrix = cam.PopModelMatrix

		local get_world_matrix

		do
			local temp = {{}, {}, {}, {}}
			get_world_matrix = function()
				local m = env.render2d.GetWorldMatrix()

				temp[1][1] = m.m00
				temp[1][2] = m.m10
				temp[1][3] = m.m20
				temp[1][4] = m.m30

				temp[2][1] = m.m01
				temp[2][2] = m.m11
				temp[2][3] = m.m21
				temp[2][4] = m.m31

				temp[3][1] = m.m02
				temp[3][2] = m.m12
				temp[3][3] = m.m22
				temp[3][4] = m.m32

				temp[4][1] = m.m03
				temp[4][2] = m.m13
				temp[4][3] = m.m23
				temp[4][4] = m.m33

				return Matrix(temp)
			end
		end

		do
			local render = {}

			local loading_material = Material("gui/progress_cog.png")

			function render.CreateTextureFromPath(path, gmod_path)
				local tex = {}
				tex.mat = loading_material
				tex.loading = true

				function tex:IsValid()
					return true
				end

				function tex:IsLoading()
					return self.loading
				end

				function tex:GetSize()
					if self:IsLoading() then
						return env.Vec2(16, 16)
					end

					return env.Vec2(self.width, self.height)
				end

				function tex:SetMinFilter() end
				function tex:SetMagFilter() end

				function tex:GetPixelColor(x,y)
					local c = self.tex:GetColor(x,y)
					return env.Color(c.r/255, c.g/255, c.b/255, c.a/255)
				end

				if gmod_path then
					tex.mat = Material(path)

					tex.tex = tex.mat:GetTexture("$basetexture")

					tex.width = tex.mat:GetInt("$realwidth") or tex.tex:GetMappingWidth()
					tex.height = tex.mat:GetInt("$realheight") or tex.tex:GetMappingHeight()
					tex.Size = env.Vec2(tex.width, tex.height)

					tex.loading = false
				else
					env.resource.Download(path, function(path)
						local path, where = env.GoluwaToGmodPath(path)

						if where == "DATA" then
							path = "../data/" .. path
						elseif path:StartWith("materials/") then
							path = path:sub(#"materials/" + 1)
						end

						if path:endswith(".vtf") then
							tex.mat = CreateMaterial("goluwa_" .. path, "UnlitGeneric", {
								["$basetexture"] = path:sub(0, -5),
								["$translucent"] = 1,
								["$vertexcolor"] = 1,
								["$vertexalpha"] = 1,
							})
						else
							tex.mat = Material(path, "unlitgeneric mips noclamp")
						end

						tex.tex = tex.mat:GetTexture("$basetexture")

						tex.width = tex.mat:GetInt("$realwidth") or tex.tex:GetMappingWidth()
						tex.height = tex.mat:GetInt("$realheight") or tex.tex:GetMappingHeight()
						tex.Size = env.Vec2(tex.width, tex.height)

						tex.loading = false
					end)
				end

				return tex
			end

			function render.SetPresetBlendMode()

			end

			function render.SetBlendMode()

			end

			function render.SetStencil() end
			function render.GetStencil() end
			function render.StencilFunction() end
			function render.StencilOperation() end
			function render.StencilMask() end

			render.white_texture = render.CreateTextureFromPath("vgui/white", true)
			render.loading_texture = render.CreateTextureFromPath("gui/progress_cog.png", true)
			render.error_texture = render.CreateTextureFromPath("error", true)

			function render.GetLoadingTexture()
				return render.loading_texture
			end

			function render.GetWhiteTexture()
				return render.white_texture
			end

			function render.GetErrorTexture()
				return render.error_texture
			end

			function render.GetWindow()
				return goluwa.window
			end

			function render.CreateBlankTexture()
			end

			function render.IsExtensionSupported()
				return false
			end

			function render.CreateFrameBuffer(size, textures, id_override)
				local fb = {}
				function fb:Begin()

				end

				function fb:End()

				end

				function fb:GetTexture()

				end

				function fb:SetTexture()

				end
				function fb:Clear() end
				function fb:ClearStencil() end
				return fb
			end

			function render.GetFrameBuffer()
				return render.CreateFrameBuffer()
			end

			do
				local META = env.prototype.CreateTemplate("index_buffer")

				META:StartStorable()
					META:GetSet("UpdateIndices", true)
					META:GetSet("IndicesType", "uint16_t")
					META:GetSet("DrawHint", "dynamic")
					META:GetSet("Indices")
				META:EndStorable()

				function render.CreateIndexBuffer()
					local self = META:CreateObject()

					return self
				end

				function META:SetIndices(indices)
				end

				function META:UnreferenceMesh()
				end

				function META:SetIndex(idx, idx2)
				end

				function META:GetIndex(idx)
				end

				function META:LoadIndices(val)
				end

				function META:UpdateBuffer()
				end

				META:Register()
			end

			do
				local META = env.prototype.CreateTemplate("vertex_buffer")

				META:StartStorable()
					META:GetSet("UpdateIndices", true)
					META:GetSet("Mode", "triangles")
					META:GetSet("IndicesType", "uint16_t")
					META:GetSet("DrawHint", "dynamic")
					META:GetSet("Vertices")
				META:EndStorable()

				META:Register()

				function render.CreateVertexBuffer(mesh_layout, vertices, indices, is_valid_table)
					local self = META:CreateObject()
					self.Vertices = {Pointer = {}}

					return self
				end

				function META:LoadVertices(vertices, indices, is_valid_table)
					if type(vertices) == "number" then
						for i = 1, vertices do
							self.Vertices.Pointer[i-1] = {
								pos = {
									[0] = 0,
									[1] = 0,
								},
								uv = {
									[0] = 0,
									[1] = 0,
								},
								color = {
									[0] = 0,
									[1] = 0,
									[2] = 0,
									[3] = 0,
								}
							}
						end
						self.vertices_length = vertices
					else
						for i, vertex in ipairs(vertices) do
							self.Vertices.Pointer[i-1] = {
								pos = {
									[0] = vertex.pos[1],
									[1] = vertex.pos[2],
								},
								uv = {
									[0] = vertex.uv[1],
									[1] = vertex.uv[2],
								},
								color = {
									[0] = vertex.color[1],
									[1] = vertex.color[2],
									[2] = vertex.color[3],
									[3] = vertex.color[4],
								}
							}
						end
						self.vertices_length = #vertices
					end
				end

				local max_vertices = 32768

				function META:UpdateBuffer()
					if self.vertices_length == 0 then return end
					local chunks = {}

					for chunk_i = 1, math.ceil(self.vertices_length/max_vertices) do
						local vertices = {}
						for i = 0, max_vertices - 1 do
							local vertex = self.Vertices.Pointer[i + ((chunk_i - 1) * max_vertices)]
							if not vertex then break end
							i = i + 1
							vertices[i] = vertices[i] or {}

							vertices[i].x = vertex.pos[0]
							vertices[i].y = vertex.pos[1]

							vertices[i].u = vertex.uv[0]
							vertices[i].v = -vertex.uv[1]+1

							vertices[i].r = vertex.color[0] or 1
							vertices[i].g = vertex.color[1] or 1
							vertices[i].b = vertex.color[2] or 1
							vertices[i].a = vertex.color[3] or 1
						end
						chunks[chunk_i] = vertices
					end
					self.chunks = chunks
				end

				local MATERIAL_TRIANGLES = MATERIAL_TRIANGLES
				local mesh_Begin = mesh.Begin
				local mesh_End = mesh.End
				local mesh_TexCoord = mesh.TexCoord
				local mesh_Color = mesh.Color
				local mesh_AdvanceVertex = mesh.AdvanceVertex
				local mesh_Position = mesh.Position
				local temp_vector = Vector(0,0,0)

				function META:Draw()
					if self.vertices_length == 0 then return end

					cam_PushModelMatrix(get_world_matrix())
						for i, vertices in ipairs(self.chunks) do
							mesh_Begin(MATERIAL_TRIANGLES, #vertices / 3)
							for i, vertex in ipairs(vertices) do

								temp_vector.x = vertex.x
								temp_vector.y = vertex.y
								mesh_Position(temp_vector)
								mesh_TexCoord(0, vertex.u, vertex.v)

								local r,g,b,a = vertex.r, vertex.g, vertex.b, vertex.a

								r = r * env.render2d.shader.global_color.r
								g = g * env.render2d.shader.global_color.g
								b = b * env.render2d.shader.global_color.b
								a = a * env.render2d.shader.global_color.a * env.render2d.shader.alpha_multiplier

								r = r * 255
								g = g * 255
								b = b * 255
								a = a * 255

								mesh_Color(r,g,b,a)

								mesh_AdvanceVertex()
							end
							mesh_End()
						end
					cam_PopModelMatrix()
				end
			end

			local ScrW = ScrW
			function render.GetWidth()
				return ScrW()
			end

			local ScrH = ScrH
			function render.GetHeight()
				return ScrH()
			end

			function render.GetScreenSize()
				return env.Vec2(ScrW(), ScrH())
			end

			env.render = render
		end

		env.camera = env.runfile("framework/lua/libraries/graphics/camera.lua")

		do
			local render2d = env.runfile("framework/lua/libraries/graphics/render2d/render2d.lua")

			render2d.shader = {
				global_color = env.Color(1,1,1,1),
				color_override = env.Color(1,1,1,1),
				alpha_multiplier = 1,
				hsv_mult = env.Vec3(1,1,1),
			}

			function render2d.shader:GetMeshLayout() end

			local surface_SetDrawColor = surface.SetDrawColor
			local render_SetColorModulation = render.SetColorModulation
			local render_SetBlend = render.SetBlend
			local render_SetMaterial = render.SetMaterial
			local surface_SetMaterial = surface.SetMaterial
			local surface_SetAlphaMultiplier = surface.SetAlphaMultiplier

			function render2d.shader:Bind()
				--surface_SetDrawColor(self.global_color.r*255,self.global_color.g*255,self.global_color.b*255,self.global_color.a*255)
				--if env.VERTEX_BUFFER_TYPE == "poly" then
					--surface_SetMaterial(self.tex.mat)
				--else
					--render_SetColorModulation(self.global_color.r, self.global_color.g, self.global_color.b)
					--render_SetBlend(self.global_color.a * self.alpha_multiplier)
					render_SetMaterial(self.tex.mat)
				--end
			--	surface_SetAlphaMultiplier(self.alpha_multiplier)
			end


			env.render2d = render2d

			render2d.rectangle = render2d.CreateMesh()
			render2d.rectangle:LoadVertices({
				{pos = {0, 1, 0}, uv = {0, 0}, color = {1,1,1,1}},
				{pos = {0, 0, 0}, uv = {0, 1}, color = {1,1,1,1}},
				{pos = {1, 1, 0}, uv = {1, 0}, color = {1,1,1,1}},

				{pos = {1, 0, 0}, uv = {1, 1}, color = {1,1,1,1}},
				{pos = {1, 1, 0}, uv = {1, 0}, color = {1,1,1,1}},
				{pos = {0, 0, 0}, uv = {0, 1}, color = {1,1,1,1}},
			})

			render2d.SetRectUV()
			render2d.SetRectColors()

		end

		do
			local fonts = {}

			function fonts.CreateFont(options)
				local obj = {}

				local temp_color = Color(255, 255, 255, 255)

				function obj:DrawString(str, x, y, w)
					local r,g,b,a = env.render2d.GetColor()

					cam_PushModelMatrix(get_world_matrix())
						temp_color.r = r * 255
						temp_color.g = g * 255
						temp_color.b = b * 255
						temp_color.a = a * 255 * env.render2d.GetAlphaMultiplier()

						prettytext.DrawText({
							text = str,
							x = x,
							y = y,
							font = options.font,
							size = options.size,
							weight = options.weight,
							blur_size = options.blur_size,
							foreground_color = temp_color,
							background_color = options.background_color,
							blur_overdraw = options.blur_overdraw,
							shadow_x = options.shadow_x or options.shadow,
							shadow_y = options.shadow_y,
						})
					cam_PopModelMatrix()
				end

				function obj:GetTextSize(str)
					return prettytext.GetTextSize(str, options.font, options.size, options.weight, options.blur_size)
				end

				function obj:IsReady()
					return true
				end

				function obj:CompileString(data)
					local str = ""
					for i = 3, #data, 3 do
						str = str .. data[i]
					end

					local obj = {}

					function obj.Draw()
						self:DrawString(str)
					end

					return obj, self:GetTextSize(str)
				end

				return obj
			end

			fonts.default_font = fonts.CreateFont({
				font = name,
				size = 16,
				weight = 600,
				blur_size = 2,
				background_color = Color(25,50,100,255),
				blur_overdraw = 10,
			})

			function fonts.GetDefaultFont()
				return fonts.default_font
			end

			function fonts.FindFont()
				return fonts.default_font
			end

			env.fonts = fonts
		end

		env.gfx = env.runfile("framework/lua/libraries/graphics/gfx/gfx.lua")
		env.runfile("engine/lua/libraries/graphics/gfx/markup.lua")
		env.gfx.ninepatch_poly = env.gfx.CreatePolygon2D(9 * 6)
		env.gfx.ninepatch_poly.vertex_buffer:SetDrawHint("dynamic")
	end

	return env
end


function goluwa.InitializeGUI()
	local env = goluwa.env

	env.input = env.runfile("framework/lua/libraries/input.lua")
	env.language = env.runfile("engine/lua/libraries/language.lua")
	env.L = env.language.LanguageString

	env.gui = env.runfile("engine/lua/libraries/graphics/gui/gui.lua")
	env.resource.AddProvider("https://github.com/CapsAdmin/goluwa-assets/raw/master/base/")
	env.resource.AddProvider("https://github.com/CapsAdmin/goluwa-assets/raw/master/extras/")
	env.gui.Initialize()

	local keys = {}
	local key_trigger = env.input.SetupInputEvent("Key")
	local function key_input(key, press)
		env.event.Call("WindowKeyInput", goluwa.window, key, press)
		if key_trigger(key, press) ~= false then
			env.event.Call("KeyInput", key, press)
		end

		if press then
			local char = key

			-- etc
			if system.GetCountry() == "NO" then
				if key == "`" then
					char = "|"
				elseif key == "SEMICOLON" then
					char = "ø"
				elseif key == "'" then
					char = "æ"
				elseif key == "[" then
					char = "å"
				end
			end

			if input.IsShiftDown() then
				char = env.utf8.upper(char)
			end

			if env.utf8.length(char) == 1 then
				env.event.Call("WindowCharInput", goluwa.window, char)
				env.event.Call("CharInput", char)
			end
		end
	end

	local buttons = {}
	local mouse_trigger = env.input.SetupInputEvent("Mouse")

	local translate = {
		MOUSE1 = "button_1",
		MOUSE2 = "button_2",
		MOUSE3 = "button_3",
		MOUSE4 = "button_4",
	}

	local function mouse_input(btn, press)
		btn = translate[btn] or btn

		env.event.Call("WindowMouseInput", goluwa.window, btn, press)
		if mouse_trigger(btn, press) ~= false then
			env.event.Call("MouseInput", btn, press)
		end
	end

	hook.Add("Think", "goluwa_keys", function()
		for i = KEY_FIRST, KEY_LAST do
			if input.IsKeyDown(i) then
				if not keys[i] then
					key_input(input.GetKeyName(i), true)
				end
				keys[i] = true
			else
				if keys[i] then
					key_input(input.GetKeyName(i), false)
				end
				keys[i] = false
			end
		end

		for i = MOUSE_FIRST, MOUSE_LAST do
			if input.IsMouseDown(i) then
				if not buttons[i] then
					mouse_input(input.GetKeyName(i), true)
				end
				buttons[i] = true
			else
				if buttons[i] then
					mouse_input(input.GetKeyName(i), false)
				end
				buttons[i] = false
			end
		end
	end)

	hook.Add("HUDPaint", "goluwa_2d", function()
		local dt = FrameTime()
		env.event.Call("PreDrawGUI", dt)
		env.event.Call("DrawGUI", dt)
		env.event.Call("PostDrawGUI", dt)
	end)
end

function goluwa.Initialize()
	hook.Add("Think", "goluwa_init", function()
		if not LocalPlayer():IsValid() then return end

		dprint("initializing goluwa ...")
		local time = SysTime()
		goluwa.env = goluwa.CreateEnv()
		_G.goluwa = goluwa

		notagain.loaded_libraries.goluwa = goluwa

		notagain.AutorunDirectory("goluwa")
		dprint("initializing goluwa took " .. (SysTime() - time) .. " seconds")

		concommand.Add("goluwa", function(ply, cmd, args, line)
			if GetConVar("sv_allowcslua"):GetBool() or LocalPlayer():IsAdmin() then
				goluwa.env.commands.RunString(line, false, false, true)
			end
		end)

		if file.Exists("addons/zerobrane_bridge/lua/autorun/zerobrane_bridge.lua", "MOD") and not render3d then
			RunString(file.Read("addons/zerobrane_bridge/lua/autorun/zerobrane_bridge.lua", "MOD"))
		end

		hook.Remove("Think", "goluwa_init")
	end)
end

function goluwa.SetEnv()
	setfenv(2, goluwa.env)
end

if CLIENT then
	goluwa.Update(goluwa.Initialize)
end

if game.IsDedicated() or CLIENT then
	concommand.Add("goluwa_reload", function()
		local str = file.Read(notagain.addon_dir .. "lua/notagain/goluwa/goluwa.lua", "MOD")
		if str then
			notagain.loaded_libraries.goluwa = CompileString(str, "lua/notagain/goluwa/goluwa.lua")()
		else
			include("notagain/goluwa/goluwa.lua")
		end
	end)
end

if me then
	notagain.loaded_libraries.goluwa = goluwa
end

return goluwa