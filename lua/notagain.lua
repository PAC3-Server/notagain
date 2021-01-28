AddCSLuaFile()

local root_dir = "notagain"
notagain = notagain or {}
notagain.loaded_libraries = notagain.loaded_libraries or {}
notagain.autorun_results = notagain.autorun_results or {}
notagain.directories = notagain.directories or {}
notagain.hasloaded = false
notagain.included_files = notagain.included_files or {}
notagain.addcslua_files = notagain.addcslua_files or {}

local OLD_include = _G.include
function includex(path, ...)
	local dir = debug.getinfo(2).source:match("@.-lua/(.+/)")
	if file.Exists(dir .. path, "LUA") then
		path = dir .. path
	end

	notagain.included_files[path] = true

	return OLD_include(path, ...)
end

local OLD_AddCSLuaFile = _G.AddCSLuaFile
function AddCSLuaFileX(path, ...)
	local dir = debug.getinfo(2).source:match("@.-lua/(.+/)")

	if path then
		if dir and file.Exists(dir .. path, "LUA") then
			path = dir .. path
		end
	else
		path = debug.getinfo(2).source:match("@.-lua/(.+)") or path
	end

	notagain.addcslua_files[path] = true

	return OLD_AddCSLuaFile(path, ...)
end

do
	notagain.addon_dir = "addons/notagain/"

	local _, dirs = file.Find("addons/*", "MOD")

	for _, dir in ipairs(dirs) do
		if file.Exists("addons/" .. dir .. "/lua/notagain.lua", "MOD") then
			notagain.addon_dir = "addons/" .. dir .. "/"
			break
		end
	end
end

local function load_path(path)
	if file.Exists(path, "LUA") then
		local var = CompileFile(path)

		if type(var) ~= "string" then
			return var
		end

		return nil, var
	end

	if file.Exists(notagain.addon_dir .. "lua/" .. path, "MOD") then
		local str = file.Read(notagain.addon_dir .. "lua/" .. path, "MOD")
		local var = CompileString(str, "lua/" .. path)

		if type(var) ~= "string" then
			return var
		end

		return nil, var
	end

	return nil, "unable to find " .. path
end

local call_level = 0

local function run_func(path, func, ...)
	_G.AddCSLuaFile = AddCSLuaFileX
	_G.include = includex

	call_level = call_level + 1
	local err
	local res = {xpcall(func, function(msg) err = msg .. "\n" .. debug.traceback() end, ...)}
	call_level = call_level - 1

	if call_level == 0 then
		_G.AddCSLuaFile = OLD_AddCSLuaFile
		_G.include = OLD_include
	end

	if err then
		res[2] = err
	end

	notagain.included_files[path] = true

	return unpack(res)
end

do
	local function find_library(tries, name, dir)
		local errors = "\n"

		for _, try in ipairs(tries) do
			local path = dir .. try:format(name)
			local func, err = load_path(path)

			if func then
				return func, path
			end

			errors = errors .. "\t" .. err .. "\n"
		end

		return nil, errors
	end

	function notagain.GetLibrary(name, ...)
		--print("REQUIRE: ", name)

		if notagain.loaded_libraries[name] then
			return notagain.loaded_libraries[name]
		end

		local func
		local errors = ""

		local path

		if not func then
			local addon_tries = {
				"libraries/%s.lua",
				"libraries/client/%s.lua",
				"libraries/server/%s.lua",
				"%s.lua",
			}

			for addon_name, addon_dir in pairs(notagain.directories) do
				local found, err = find_library(addon_tries, name, addon_dir .. "/")

				if found then
					path = err
					func = found
					break
				else
					errors = errors .. err
				end
			end
		end

		-- foo/init.lua
		if not func then
			path = root_dir .. "/" .. name .. "/init.lua"
			local res, msg = load_path(path)
			if res then
				func = res
			else
				errors = errors .. msg
			end
		end

		if func == nil then
			return nil, errors
		end

		local ok, lib = run_func(path, func, ...)

		if ok == false then
			return nil, lib
		end

		if lib == nil then
			return nil, "library " .. name .. " returns nil"
		end

		notagain.loaded_libraries[name] = lib

		return lib
	end
end

function notagain.UnloadLibrary(name)
	notagain.loaded_libraries[name] = nil
end

function notagain.GetAutorunResults(addon_name)
	return notagain.autorun_results[addon_name]
end

local function msg(color, str)
	MsgC(Color(100, 255, 100, 255), "[notagain]")

	if SERVER then
		MsgC(Color(100, 100, 255, 255), "[SERVER]")
	end

	if CLIENT then
		MsgC(Color(255, 255, 100, 255), "[CLIENT]")
	end

	if color == "error" then
		MsgC(Color(255, 100, 100, 255), str)
	else
		MsgC(color, str)
	end
end

local function run(path)
	local func, err = load_path(path)
	if not func then
		msg("error", "⮞ Couldn't compile " .. path .. "\n\t" .. err .. "\n")
		return {
			ok = false,
			compile_error = true,
			error = err,
		}
	end

	local args = {run_func(path, func)}
	local ok = table.remove(args, 1)

	if not ok then
		local err = args[1]
		msg("error", "⮞ Couldn't run " .. path .. "\n\t" .. err .. "\n")
		return {
			ok = false,
			runtime_error = true,
			error = err,
		}
	end

	return {
		ok = true,
		path = path,
		func = func,
		ret = args,
	}
end

local function run_dir(addon_name, dir, addcsluafile_only)

	local map_dir = dir .. "map_" .. game.GetMap():lower() .. "/"
	if file.IsDir(map_dir, "LUA") then
		run_dir(addon_name, map_dir, addcslua_files)
	end

	notagain.autorun_results[addon_name] = notagain.autorun_results[addon_name] or {}

	for _, name in pairs((file.Find(dir .. "*.lua", "LUA"))) do
		local path = dir .. name

		if not addcsluafile_only then
			notagain.autorun_results[addon_name][path] = run(path)
		end

		if SERVER then
			AddCSLuaFile(path)
		end
	end

	for _, name in pairs((file.Find(dir .. "client/*.lua", "LUA"))) do
		local path = dir .. "client/" .. name

		if CLIENT then
			if not addcsluafile_only then
				notagain.autorun_results[addon_name][path] = run(path)
			end
		end

		if SERVER then
			AddCSLuaFile(path)
		end
	end

	if SERVER then
		if not addcsluafile_only then
			for _, name in pairs((file.Find(dir .. "server/*.lua", "LUA"))) do
				local path = dir .. "server/" .. name
				notagain.autorun_results[addon_name][path] = run(path)
			end
		end
	end
end

function notagain.AutorunDirectory(addon_name)
	run_dir(addon_name, notagain.directories[addon_name] .. "/prerun/")
	run_dir(addon_name, notagain.directories[addon_name] .. "/autorun/")

	return notagain.autorun_results[addon_name]
end

function notagain.Initialize()
	
	-- load foo/foo.lua
	for addon_name, addon_dir in pairs(notagain.directories) do
		if not notagain.loaded_libraries[addon_name] then
			local path = addon_dir .. "/" .. addon_name .. ".lua"
			if file.Exists(path, "LUA") then
				local info = run(path)
				if info.ok then
					local lib = info.ret[1]

					if lib == nil then
						msg("error", "library " .. addon_name .. " returns nil")
					else
						notagain.loaded_libraries[addon_name] = lib
					end
				end
			end
		end
	end

end
function notagain.Autorun()
	--If external stuff needs to be called before notagain
	hook.Run("NotagainPreLoad")

	--local include = function(path) print("INCLUDE: ", path) return _G.include(path) end
	--local AddCSLuaFile = function(path) print("AddCSLuaFile: ", path) return AddCSLuaFile(path) end

	-- pre autorun
	for addon_name, addon_dir in pairs(notagain.directories) do
		local lib = notagain.loaded_libraries[addon_name]
		run_dir(addon_name, addon_dir .. "/prerun/", lib and lib.notagain_autorun == false)
	end

	-- autorun
	for addon_name, addon_dir in pairs(notagain.directories) do
		local lib = notagain.loaded_libraries[addon_name]
		run_dir(addon_name, addon_dir .. "/autorun/", lib and lib.notagain_autorun == false)
	end

	notagain.hasloaded = true

	--If external stuff need that notagain has fully loaded
	hook.Run("NotagainPostLoad")
end

function notagain.PreInit()
	for addon_name, addon_dir in pairs(notagain.directories) do
		run_dir(addon_name, addon_dir .. "/preinit/")
	end
end

function notagain.PostInit()
	for addon_name, addon_dir in pairs(notagain.directories) do
		run_dir(addon_name, addon_dir .. "/postinit/")
	end
end

do
	local dirs = {}

	for i, addon_dir in ipairs(select(2, file.Find(root_dir .. "/*", "LUA"))) do
		dirs[addon_dir] = root_dir .. "/" .. addon_dir
	end

	for i, addon_dir in ipairs(select(2, file.Find(notagain.addon_dir .. "lua/" .. root_dir .. "/*", "MOD"))) do
		dirs[addon_dir] = root_dir .. "/" .. addon_dir
	end

	notagain.directories = dirs

	for addon_name, addon_dir in pairs(notagain.directories) do
		if SERVER then -- libraries
			local dir = addon_dir .. "/libraries/"

			for _, name in pairs((file.Find(dir .. "*.lua", "LUA"))) do
				AddCSLuaFile(dir .. name)
			end

			local path = dir .. "client/"
			for _, name in pairs((file.Find(path .. "*.lua", "LUA"))) do
				AddCSLuaFile(path .. name)
			end
		end
	end
end

function _G.requirex(name, ...)
	local res, err = notagain.GetLibrary(name, ...)
	if res == nil then error(err, 2) end
	return res
end
