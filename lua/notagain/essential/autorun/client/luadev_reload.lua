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
				local code = file.Read(path, "MOD")
				if lib then
					code = "notagain.loaded_libraries." .. name .. "=(function()" .. code .. ";end)()"
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

concommand.Add("luadev_monitor_notagain", function(_,_,_,b)
	if b == "1" then
		timer.Create("luadev_monitor_notagain", 0.1, 0, function()
			if system.HasFocus() then return end
			for _, dir in pairs(notagain.directories) do
				check_dir("addons/notagain/lua/"..dir.."/autorun/", callback, "shared")
				check_dir("addons/notagain/lua/"..dir.."/autorun/client/", callback, "clients")
				check_dir("addons/notagain/lua/"..dir.."/autorun/server/", callback, "server")
			end

			for _, dir in pairs(notagain.directories) do
				check_dir("addons/notagain/lua/"..dir.."/libraries/", callback, "shared", true)
				check_dir("addons/notagain/lua/"..dir.."/libraries/client/", callback, "clients", true)
				check_dir("addons/notagain/lua/"..dir.."/libraries/server/", callback, "server", true)
			end
		end)
	else
		table.Empty(find_cache)
		timer.Remove("luadev_monitor_notagain")
	end
end)

concommand.Add("luadev_monitor_last_send", function(ply,_,_,b)
	local last_time
	if b == "1" then
		timer.Create("luadev_monitor_last_send", 0.1, 0, function()
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

	end
end)