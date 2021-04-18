local msgpack = requirex("msgpack")
local common_audio = CLIENT and requirex("common_audio")
local unzip = CLIENT and requirex("unzip")

AddCSLuaFile()

local goluwa = {}

goluwa.notagain_autorun = false

local function dprint(...)
	print("goluwa: ", ...)
end

local delete_directory

local branch = CreateClientConVar("goluwa_branch", "release")

do
	function delete_directory(dir)
		local files, folders = file.Find(dir .. "*", "DATA")

		for k,v in ipairs(files) do
			file.Delete(dir .. v)
		end

		for k,v in ipairs(folders) do
			delete_directory(dir .. v .. "/")
		end

		if not file.Find(dir .. "*", "DATA")[0] then
			file.Delete(dir)
		end
	end

	local function redownload(tag, cb)
		tag = tag or "master"
		http.Fetch("https://gitlab.com/api/v4/projects/CapsAdmin%2Fgoluwa/repository/archive.zip?sha=" .. tag, function(data, _, _, code)
			if code ~= 200 then
				ErrorNoHalt("goluwa: " .. data)
				return
			end

			file.Write("goluwa_zip.dat", data)

			delete_directory("goluwa/goluwa/")

			local done = {}

			for i,v in ipairs(unzip("goluwa_zip.dat")) do
				local path = v.file_name:match(".-/(.+)")
				if path and path:EndsWith(".lua") then

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

					file.Write("goluwa/goluwa/" .. path:gsub("%.", "^") .. ".txt", v.file_content)
				end
			end

			file.Delete("goluwa_zip.dat")

			cb()
		end)
	end

	function goluwa.Update(cb)
		file.CreateDir("goluwa")

		if not GOLUWA_FORCE_DOWNLOAD and file.IsDir("addons/goluwa", "MOD") then
			goluwa.addon_directory = true
			cb()
			return
		end

		file.CreateDir("goluwa/goluwa")

		local function rolling()
			local branch = branch:GetString()

			http.Fetch("https://gitlab.com/api/v4/projects/CapsAdmin%2Fgoluwa/repository/commits/" .. branch, function(data, _, _, code)
				if code ~= 200 then
					ErrorNoHalt("goluwa: " .. data)
					return
				end

				local last_commit = util.JSONToTable(data)

				if file.Read("goluwa/update_id.txt") == last_commit.id then
					cb()
				else
					dprint("last commit is different, redownloading")
					redownload(branch, function()
						cb()
						file.Write("goluwa/update_id.txt", last_commit.id)
					end)
				end
			end)
		end

		if branch:GetString() == "release" then
			http.Fetch("https://gitlab.com/api/v4/projects/CapsAdmin%2Fgoluwa/repository/tags", function(data, _, _, code)
				if code ~= 200 then
					ErrorNoHalt("goluwa: " .. data)
					return
				end

				local tags = util.JSONToTable(data)
				local tag = tags and tags[1]

				if tag then
					if not file.IsDir("goluwa/goluwa", "DATA") or not file.IsDir("goluwa/goluwa/core", "DATA") then
						dprint("missing goluwa directory, redownloading")
						redownload(tag.commit.id, function()
							cb()
							file.Write("goluwa/update_id.txt", tag.commit.id)
						end)
					elseif file.Read("goluwa/update_id.txt", "DATA") == tag.commit.id then
						cb()
					else
						dprint("release tag id is different, redownloading")
						redownload(tag.commit.id, function()
							cb()
							file.Write("goluwa/update_id.txt", tag.commit.id)
						end)
					end
				else
					dprint("no release tag found, assume rolling release")
					rolling()
				end
			end)
		else
			rolling()
		end
	end
end

function goluwa.CreateEnv()
	local env = {}
	env._G = env

	env.e = {}
	env.gmod = setmetatable({}, {
		__index = function(_, key)
			return _G[key]
		end
	})

	env.PLATFORM = "gmod"

	do
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

				if not file.IsDir(path, where) and path:sub(-1) ~= "/" then
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
	end

	do
		local function execute(full_path, chunk_name, ...)
			local lua = file.Read(full_path, goluwa.lua_dir_where)
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

				if dir:StartWith("lua/") then
					local relative = debug.getinfo(2).source:match("@(.+)")
					local addon_dir = relative:match("^(.-/)")

					if file.IsDir(goluwa.lua_dir .. addon_dir .. dir, goluwa.lua_dir_where) then
						dir = addon_dir .. dir
					end
				elseif not file.IsDir(goluwa.lua_dir .. dir, goluwa.lua_dir_where) then
					local relative = debug.getinfo(2).source:match("@(.+)")

					if relative then
						dir = relative:match("(.+/).-%.lua") .. dir
					end
				end

				local files = file.Find(goluwa.lua_dir .. dir .. "*", goluwa.lua_dir_where)

				for _, name in pairs(files) do
					local path = dir

					if goluwa.lua_dir_where == "DATA" then
						path = path .. name:gsub("%^lua%.txt", ".lua")
					else
						path = path .. name
					end

					execute(goluwa.lua_dir .. dir .. name, path,  ...)
				end

				return
			end

			if goluwa.lua_dir_where == "DATA" then
				if not path:EndsWith(".txt") then
					path = path:gsub("%.", "^") .. ".txt"
				end
			end

			if path:StartWith("lua/") then
				local relative = debug.getinfo(2).source:match("@(.+)")
				local addon_dir = relative:match("^(.-/)")

				if file.Exists(goluwa.lua_dir .. addon_dir .. path, goluwa.lua_dir_where) then
					return execute(goluwa.lua_dir .. addon_dir .. path, addon_dir .. original_path,  ...)
				end

				for k,v in ipairs({"core", "framework", "engine", "game"}) do
					if file.Exists(goluwa.lua_dir .. v .. "/" .. path, goluwa.lua_dir_where) then
						return execute(goluwa.lua_dir .. v .. "/" .. path, v .. "/" .. path, ...)
					end
				end
			end

			if file.Exists(goluwa.lua_dir .. path, goluwa.lua_dir_where) then
				return execute(goluwa.lua_dir .. path, original_path,  ...)
			else
				local relative = debug.getinfo(2).source:match("@(.+)")
				if relative then
					local dir = relative:match("(.+/).-%.lua")

					if file.Exists(goluwa.lua_dir .. dir .. path, goluwa.lua_dir_where) then
						return execute(goluwa.lua_dir .. dir .. path, dir .. original_path, ...)
					end
				end
			end

			print("[goluwa] runfile: unable to find " .. original_path)
		end
	end

	do

		env.e.STORAGE_FOLDER = "/data/goluwa/storage/"
		env.e.USERDATA_FOLDER = env.e.STORAGE_FOLDER.."userdata/"
		env.e.SHARED_FOLDER = env.e.STORAGE_FOLDER.."shared/"
		env.e.CACHE_FOLDER = env.e.STORAGE_FOLDER.."cache/"
		env.e.TEMP_FOLDER = env.e.STORAGE_FOLDER.."temp/"

		env.e.ROOT_FOLDER = notagain.addon_dir .. "lua/notagain/goluwa/goluwa/"
		env.e.SRC_FOLDER = env.e.ROOT_FOLDER
		env.e.BIN_FOLDER = "bin/"

		do -- require
			local stdlibs =
			{
				table = table,
				math = math,
				string = string,
				debug = debug,
				io = io,
				os = os,
			}

			local special = {
				ffi = true,
				["table.gcnew"] = true,
				["table.clear"] = true,
				["table.new"] = true,
				ffi = true,
				archive = true,
				freeimage = true,
				opengl = true,
				freetype = true,
				["table.new"] = true,
				["table.clear"] = true,
				["deflatelua"] = true,
				von = true,
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

			env.os = {}
			env.os.clock = _G.os.clock
			env.os.date = _G.os.date
			env.os.difftime = _G.os.difftime
			env.os.time = _G.os.time

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

	env.runfile("core/lua/libraries/platforms/gmod/globals.lua")
	env.fs = env.runfile("core/lua/libraries/platforms/gmod/filesystem.lua")

	env.fs.create_directory(env.e.STORAGE_FOLDER)
	env.fs.create_directory(env.e.STORAGE_FOLDER .. "/userdata/")
	env.fs.create_directory(env.e.USERDATA_FOLDER)
	env.fs.create_directory(env.e.CACHE_FOLDER)
	env.fs.create_directory(env.e.SHARED_FOLDER)
	env.fs.create_directory(env.e.TEMP_FOLDER)

	env.runfile("core/lua/libraries/platforms/gmod/os.lua", env.os)

	env.io = {}
	env.runfile("core/lua/libraries/platforms/gmod/io.lua", env.io)

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

	env["json"] = {encode = util.TableToJSON, decode = util.JSONToTable}
	env.msgpack_ffi = {encode = msgpack.pack, decode = msgpack.unpack}

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
	env.runfile("game/lua/libraries/utilities/line.lua", env.utility)

	env.vfs = env.runfile("core/lua/libraries/filesystem/vfs.lua")

	--env.vfs.Mount("os:/data/goluwa/data/", "os:data/")
	--env.vfs.Mount("os:/data/goluwa/data/", "os:")
	--env.vfs.Mount("os:/data/goluwa/userdata/", "os:data/")
	--env.vfs.Mount("os:/", "os:")

	env.vfs.Mount("os:" .. env.e.STORAGE_FOLDER) -- mount the storage folder to allow requiring files from bin/*
	env.vfs.Mount("os:" .. env.e.USERDATA_FOLDER, "os:data") -- mount "ROOT/data/users/*username*/" to "/data/"
	env.vfs.Mount("os:" .. env.e.CACHE_FOLDER, "os:cache")
	env.vfs.Mount("os:" .. env.e.SHARED_FOLDER, "os:shared")

	env.R = env.vfs.GetAbsolutePath -- a nice global for loading resources externally from current dir
	env.crypto = env.runfile("core/lua/libraries/crypto.lua")
	env.tasks = env.runfile("core/lua/libraries/tasks.lua")

	env.pvars = env.runfile("engine/lua/libraries/pvars.lua")
	env.commands = env.runfile("engine/lua/libraries/commands.lua")
	for i, args in ipairs(commands_add_buffer) do env.commands.Add(unpack(args)) end

	env.system = env.runfile("core/lua/libraries/system.lua")

	env.WINDOW_IMPLEMENTATION = "gmod"
	env.window = env.runfile("framework/lua/libraries/window/window.lua")
	env.profiler = env.runfile("core/lua/libraries/profiler.lua")
	env.runfile("engine/lua/libraries/extensions/profiler.lua")
	env.P = env.profiler.ToggleTimer
	env.I = env.profiler.ToggleInstrumental
	env.S = env.profiler.ToggleStatistical

	env.event = env.runfile("core/lua/libraries/event.lua")

	env.event.AddListener("EventAdded", "gmod", function(info)
	--	print("goluwa event added: ", info.event_type, info.id)
	end)

	env.event.AddListener("EventRemoved", "gmod", function(info)
	--	print("goluwa event removed: ", info.event_type, info.id)
	end)

	hook.Add("Think", "goluwa", function()
		env.event.UpdateTimers()
		env.event.Call("Update", env.system.GetFrameTime())
	end)

	hook.Add("PreRender", "goluwa", function()
		env.system.SetFrameNumber(FrameNumber())
		env.system.SetElapsedTime(RealTime())
		env.system.SetFrameTime(FrameTime())
	end)

	env.expression = env.runfile("engine/lua/libraries/expression.lua")
	env.autocomplete = env.runfile("engine/lua/libraries/autocomplete.lua")

	do
		local sockets = {}
		env.SOCKETS = true
		env.callback = env.runfile("core/lua/libraries/callback.lua", sockets)
		env.runfile("core/lua/libraries/sockets/download.lua", sockets)
		env.sockets = sockets
		env.http = env.runfile("core/lua/libraries/http.lua")

		function sockets.Request(tbl)
			--tbl.callback = tbl.callback or env.table.print
			tbl.method = tbl.method or "GET"

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
					if code >= 400 and code < 600 then
						if tbl.error_callback then
							tbl.error_callback(tostring(code))
						end
						return
					end

					if not tbl.code_callback or tbl.code_callback(code) ~= false then

						local copy = {}
						for k,v in pairs(header) do
							copy[k:lower()] = v
						end

						if not tbl.header_callback or tbl.header_callback(copy) ~= false then
							if tbl.on_chunks then
								tbl.on_chunks(body)
							end

							if tbl.callback then
								tbl.callback({content = body, header = copy, code = code})
							end
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

		function sockets.Download(url, on_finish, on_error, on_chunks, on_header, on_code)
			sockets.Request({
				url = url,
				error_callback = on_error,
				callback = function(data)
					if on_code then
						on_code(data.code)
					end
					if on_header then
						on_header(data.header)
					end
					if on_chunks then
						on_chunks(data.content)
					end
					if on_finish then
						on_finish(data.content)
					end
				end,
			})
		end
	end

	env.resource = env.runfile("core/lua/libraries/resource.lua")

	env.resource.AddProvider("https://gitlab.com/CapsAdmin/goluwa-assets/raw/master/base/", true)

	env.input = env.runfile("framework/lua/libraries/input.lua")
	env.language = env.runfile("engine/lua/libraries/language.lua")
	env.L = env.language.LanguageString

	do
		local backend = CreateClientConVar("goluwa_audio_backend", "webaudio")

		local audio = {}

		audio.player_object = NULL

		function audio.CreateSource(path)
			local snd = common_audio.CreateSoundFromInterface(backend:GetString())
			snd:SetEntity(audio.player_object)
			env.resource.Download(path):Then(function(path)
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

	do
		local network = {}

		function network.IsConnected()
			return true
		end

		function network.GetHostname()
			return GetHostName()
		end

		env.network = network
	end

	do -- rendering
		do
			local temp = {{}, {}, {}, {}}
			function env.GetGmodWorldMatrix()
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

		env.camera = env.runfile("framework/lua/libraries/graphics/camera.lua")
		env.render = env.runfile("framework/lua/libraries/graphics/render/render.lua")
		env.render.GenerateTextures = function()
			env.render.error_texture = env.render.CreateTextureFromPath("error", true)
			env.render.white_texture = env.render.CreateTextureFromPath("materials/color/white.vtf")
			env.render.loading_texture = env.render.CreateTextureFromPath("vgui/loading-rotate", true)
		end

		do
			local render2d = env.runfile("framework/lua/libraries/graphics/render2d/render2d.lua")

			render2d.shader = {
				global_color = env.Color(1,1,1,1),
				color_override = env.Color(1,1,1,1),
				alpha_multiplier = 1,
				hsv_mult = env.Vec3(1,1,1),
			}

			function render2d.shader:GetMeshLayout()
				return {}
			end

			local render_SetMaterial = render.SetMaterial

			do
				local temp = Vector()
				local mat = CreateMaterial("goluwa_unlit_shader_", "UnlitGeneric", {
					["$translucent"] = 1,
					["$vertexcolor"] = 1,
					["$vertexalpha"] = 1,
				})

				local last_tex
				local last_color_r
				local last_color_g
				local last_color_b
				local last_color_a

				function render2d.shader:Bind()
					if last_tex ~= self.tex.tex then
						mat:SetTexture("$basetexture", self.tex.tex)

						last_tex = self.tex.tex
					end

					if
						last_color_r ~= self.global_color.r or
						last_color_g ~= self.global_color.g or
						last_color_b ~= self.global_color.b
					then
						temp.x = self.global_color.r
						temp.y = self.global_color.g
						temp.z = self.global_color.b

						mat:SetVector("$color", temp)
						mat:SetVector("$color2", temp)

						last_color_r = self.global_color_r
						last_color_g = self.global_color_g
						last_color_b = self.global_color_b
					end

					local alpha = self.global_color.a * self.alpha_multiplier

					if last_color_a ~= alpha then
						mat:SetFloat("$alpha", alpha)

						last_color_a = alpha
					end

					render_SetMaterial(mat)
				end
			end

			env.render2d = render2d

			render2d.SetColor(1,1,1,1)
		end

		do
			env.fonts = env.runfile("framework/lua/libraries/graphics/fonts/fonts.lua")
			env.fonts.Initialize()
			env.fonts.default_font = env.fonts.CreateFont({
				size = 16,
				weight = 600,
				blur_size = 2,
				background_color = Color(25,50,100,255),
				blur_overdraw = 10,
			})

			function env.fonts.GetDefaultFont()
				return env.fonts.default_font
			end

			function env.fonts.FindFont()
				return env.fonts.default_font
			end
		end

		env.gfx = env.runfile("framework/lua/libraries/graphics/gfx/gfx.lua")
		env.runfile("engine/lua/libraries/graphics/gfx/markup.lua", env.gfx)

		env.window.Open()

		env.render2d.rectangle = env.render2d.CreateMesh({})
		env.render2d.rectangle:LoadVertices({
			{pos = {0, 1, 0}, uv = {0, 0}, color = {1,1,1,1}},
			{pos = {0, 0, 0}, uv = {0, 1}, color = {1,1,1,1}},
			{pos = {1, 1, 0}, uv = {1, 0}, color = {1,1,1,1}},

			{pos = {1, 0, 0}, uv = {1, 1}, color = {1,1,1,1}},
			{pos = {1, 1, 0}, uv = {1, 0}, color = {1,1,1,1}},
			{pos = {0, 0, 0}, uv = {0, 1}, color = {1,1,1,1}},
		})

		env.render2d.SetRectUV()
		env.render2d.SetRectColors()


		env.gfx.ninepatch_poly = env.gfx.CreatePolygon2D(9 * 6)
		env.gfx.ninepatch_poly.vertex_buffer:SetDrawHint("dynamic")
	end

	local META = FindMetaTable("Panel")

	function META:BeginGoluwaPaint()
		local x, y = self:LocalToScreen()
		env.render2d.PushMatrix(x, y)
		render.SetScissorRect(x, y, x + self:GetWide(), y + self:GetTall(), true)
	end

	function META:EndGoluwaPaint()
		env.render2d.PopMatrix()
		render.SetScissorRect(0,0,0,0, false)
	end

	if _G.TEST_GOLUWA_GUI then
		env.runfile("framework/lua/libraries/extensions/utility.lua", env.utility)
		env.runfile("engine/lua/libraries/graphics/gfx/particles.lua", env.gfx)
		--env.network = env.runfile("engine/lua/libraries/network/network.lua")
		--env.runfile("framework/lua/libraries/extensions/utility.lua", env.utility)

		env.packet = env.runfile("engine/lua/libraries/network/packet.lua")
		env.message = env.runfile("engine/lua/libraries/network/message.lua")
		env.nvars = env.runfile("engine/lua/libraries/network/nvars.lua")
		env.clients = env.runfile("engine/lua/libraries/network/clients.lua")
		env.chat = env.runfile("game/lua/libraries/network/chat.lua")

		env.runfile("game/lua/autorun/console_commands.lua")
		env.runfile("engine/lua/libraries/extensions/input.lua", env.input)
		env.gui = env.runfile("engine/lua/libraries/graphics/gui/gui.lua")
		env.resource.AddProvider("https://github.com/CapsAdmin/goluwa-assets/raw/master/base/")
		env.resource.AddProvider("https://github.com/CapsAdmin/goluwa-assets/raw/master/extras/")

		env.gui.Initialize()

		hook.Remove("Think", "goluwa")

		for _, gmod_pnl in ipairs(vgui.GetWorldPanel():GetChildren()) do
			if IsValid(gmod_pnl.goluwa_collision) then
				gmod_pnl.goluwa_collision:Remove()
			end
		end

		hook.Add("PostRenderVGUI", "goluwa_2d", function()
			env.event.UpdateTimers()
			env.event.Call("Update", env.system.GetFrameTime())

			local dt = FrameTime()
			env.event.Call("PreDrawGUI", dt)
			env.event.Call("DrawGUI", dt)
			env.event.Call("PostDrawGUI", dt)

			--[[

			for _, gmod_pnl in ipairs(vgui.GetWorldPanel():GetChildren()) do
				local goluwa_pnl = gmod_pnl.goluwa_collision
				if gmod_pnl:IsVisible() then
					if not goluwa_pnl then
						gmod_pnl.goluwa_collision = env.gui.CreatePanel("base")
						gmod_pnl.goluwa_collision.OnUpdate = function(s)
							if not gmod_pnl:IsValid() then
								goluwa_pnl:Remove()
							end
						end
						goluwa_pnl = gmod_pnl.goluwa_collision
					end
				end

				if goluwa_pnl then
					goluwa_pnl:SetVisible(gmod_pnl:IsVisible())
					goluwa_pnl:SetPosition(env.Vec2(gmod_pnl:LocalToScreen()))
					goluwa_pnl:SetSize(env.Vec2(gmod_pnl:GetSize()))
				end
			end

			]]
		end)

		for i,v in ipairs(player.GetAll()) do
			local c
			if v == LocalPlayer() then
				c = env.clients.Create(v:UniqueID())
				env.clients.local_client = c
			else
				c = env.clients.Create(v:UniqueID())
			end
			c:SetNick(v:Nick())
		end

		env.render2d.PushStencilRect = function() end
		env.render2d.PopStencilRect = function() end

		--env.runfile("game/lua/autorun/graphics/scoreboard.lua")
		--env.runfile("game/lua/autorun/graphics/chatbox.lua")

		-- for _, client in ipairs(env.clients.GetAll()) do
		-- 	env.scoreboard.AddClient(client)
		-- end

		env.render.SetFrameBuffer()
		env.goluwa = env.event.CreateRealm("goluwa")

		--env.runfile("game/lua/gui_panels/*")
		--for i = 1, 100 do env.gui.CreatePanel"sheep" end
		--env.runfile("game/lua/examples/2d/esheep.lua")
	end

	return env
end

function goluwa.Initialize()
	hook.Add("Think", "goluwa_init", function()
		if not LocalPlayer():IsValid() then return end

		hook.Remove("Think", "goluwa_init")

		if file.IsDir("addons/goluwa", "MOD") then
			goluwa.lua_dir = "addons/goluwa/"
			goluwa.lua_dir_where = "MOD"
		else
			goluwa.lua_dir = "goluwa/goluwa/"
			goluwa.lua_dir_where = "DATA"
		end

		dprint("initializing goluwa ...")
		local time = SysTime()
		goluwa.env = goluwa.CreateEnv()
		_G.goluwa = goluwa

		notagain.loaded_libraries.goluwa = goluwa

		notagain.AutorunDirectory("goluwa")
		dprint(("initializing goluwa took %.5f seconds"):format(SysTime() - time))

		concommand.Add("goluwa", function(ply, cmd, args, line)
			if GetConVar("sv_allowcslua"):GetBool() or LocalPlayer():IsAdmin() then
				goluwa.env.commands.RunString(line, false, false, true)
			end
		end)

		if file.Exists("addons/zerobrane_bridge/lua/autorun/zerobrane_bridge.lua", "MOD") and not render3d then
			RunString(file.Read("addons/zerobrane_bridge/lua/autorun/zerobrane_bridge.lua", "MOD"))
		end
	end)
end

function goluwa.SetEnv()
	setfenv(2, goluwa.env)
end

if CLIENT then
	goluwa.Update(goluwa.Initialize)
end

if SERVER then
	notagain.AutorunDirectory("goluwa")
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

	concommand.Add("goluwa_clear_cache", function()
		delete_directory("goluwa/")
	end)
end

if me then
	notagain.loaded_libraries.goluwa = goluwa
end

return goluwa
