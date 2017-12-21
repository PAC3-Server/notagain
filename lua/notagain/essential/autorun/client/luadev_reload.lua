local luadev = requirex("luadev")
local last = {}

local find_cache = {}
local function find(path)
	if not find_cache[path] then
		find_cache[path] = file.Find(path, "MOD")
	end

	return find_cache[path]
end

local function check_dir(dir, cb, what, lib)
	for _, path in ipairs(find(dir .. "*")) do
		local name = path:match("(.+)%.lua")
		path = dir .. path

		local time = file.Time(path, "MOD")

		if last[path] ~= time then
			if last[path] then
				print(path, " changed")
				local code = file.Read(path, "MOD")
				if lib then
					if isfunction(lib) then
						code = lib(code)
					else
						code = "notagain.loaded_libraries." .. name .. "=(function()" .. code .. ";end)()"
					end
				end
				cb(path, code, what)
			end
			last[path] = time
		end
	end
end

local function callback(path, code, what)
	if what == "self" then
		luadev.RunOnSelf(code, path)
	elseif what == "clients" then
		luadev.RunOnClients(code, path)
	elseif what == "server" then
		luadev.RunOnServer(code, path)
	elseif what == "shared" then
		luadev.RunOnShared(code, path)
	end
end

local function set_timer(id, cb)
	if cb then
		local next_run = 0
		hook.Add("RenderScene", "luadev_monitor_" .. id, function()
			if system.HasFocus() then return end
			local time = SysTime()
			if next_run > next_run then return end
			next_run = next_run + 0.1

			cb()
		end)
	else
		hook.Remove("RenderScene", "luadev_monitor_" .. id)
	end
end

local addon_dir = notagain.addon_dir .. "lua/"

local function dump_dir(dir)
	for _, path in ipairs(find(dir .. "*")) do
		print("\t" .. (dir .. path):match(".-lua/notagain/(.+)"))
	end
end

concommand.Add("luadev_monitor_notagain", function(_,_,_,b)
	if b == "1" then

		print("monitoring these files in lua/notagain/*")

		for _, dir in pairs(notagain.directories) do
			dump_dir(addon_dir .. dir .. "/autorun/")
			dump_dir(addon_dir .. dir .. "/autorun/client/")
			dump_dir(addon_dir .. dir .. "/autorun/server/")

			dump_dir(addon_dir .. dir .. "/libraries/")
			dump_dir(addon_dir .. dir .. "/libraries/client/")
			dump_dir(addon_dir .. dir .. "/libraries/server/")
		end

		set_timer("notagain", function()
			for _, dir in pairs(notagain.directories) do
				check_dir(addon_dir .. dir .. "/autorun/", callback, "shared")
				check_dir(addon_dir .. dir .. "/autorun/client/", callback, "clients")
				check_dir(addon_dir .. dir .. "/autorun/server/", callback, "server")

				check_dir(addon_dir .. dir .. "/prerun/", callback, "shared")
				check_dir(addon_dir .. dir .. "/prerun/client/", callback, "clients")
				check_dir(addon_dir .. dir .. "/prerun/server/", callback, "server")

				check_dir(addon_dir .. dir .. "/libraries/", callback, "shared", true)
				check_dir(addon_dir .. dir .. "/libraries/client/", callback, "clients", true)
				check_dir(addon_dir .. dir .. "/libraries/server/", callback, "server", true)
			end

			for _, lib in pairs(notagain.loaded_libraries) do
				if istable(lib) and lib.notagain_monitor_directories then
					for _, info in ipairs(lib.notagain_monitor_directories) do
						check_dir(addon_dir .. info.dir, callback, info.what, info.lib)
					end
				end
			end
		end)
	else
		print("stop monitoring files in lua/notagain/*")

		table.Empty(find_cache)
		set_timer("notagain")
	end
end)

concommand.Add("luadev_monitor_last_send", function(ply,_,_,b)
	local last_time
	if b == "1" then
		set_timer("last_send", function()
			local path, where = luadev.GetLastRunPath()
			if path then
				local time = file.Time(path, where)
				if time ~= last_time then
					luadev.RepeatLastCommand()
					print("luadev reload: ", path, " reloaded")
					last_time = time
				end
			end
		end)
	else
		set_timer("last_send")
	end
end)