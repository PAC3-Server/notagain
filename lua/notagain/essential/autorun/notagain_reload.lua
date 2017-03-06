local luadev = requirex("luadev")
local last = {}

local function check_dir(dir, cb, what, lib)
	for _, path in ipairs((file.Find(dir .. "*", "MOD"))) do
		local name = path:match("(.+)%.lua")
		path = dir .. path

		local time = file.Time(path, "MOD")

		if last[path] ~= time then
			if last[path] then
				local code = file.Read(path, "MOD")
				if lib then
					code = "notagain.loaded_libraries." .. name .. "=nil;" .. code
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

concommand.Add("notagain_monitor_lua", function(_,_,_,b)
	if b == "1" then
		timer.Create("notagain_monitor_lua", 0.1, 0, function()
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
		timer.Remove("notagain_monitor_lua")
	end
end)