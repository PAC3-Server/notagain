local debug_traceback2 = requirex("debug_traceback2")

local function hook_error(cb)
	_G.old_glua_error = _G.old_glua_error or debug.getregistry()[1]
	debug.getregistry()[1] = function(msg, ...)
		
		local ok, err = pcall(function()
			local stack = {}
			for i = 0, math.huge do
				local info = debug.getinfo(i)
				if not info then break end

				info.func_info = debug.getinfo(info.func)
				info.func_info.func = nil
				info.func = nil

				stack[i + 1] = info
			end

			cb(msg, debug_traceback2(5), stack)
		end)

		if not ok then
			ErrorNoHalt("error in error handling: " .. err)
		end

		return _G.old_glua_error(msg, ...)
	end
end

if CLIENT then
	local last_error = setmetatable({}, {__mode = "kv"})

	hook_error(function(msg, traceback, stack)
		local hash = msg .. traceback:gsub(" = .-\n", "")

		if last_error[hash] and last_error[hash] > SysTime() then return end
		last_error[hash] = SysTime() + 1

		net.Start("client_lua_error", true)
			net.WriteString(msg)
			net.WriteString(traceback)
			net.WriteTable(stack)
		net.SendToServer()
	end)
end

if SERVER then
	util.AddNetworkString("client_lua_error")

	hook_error(function(msg, traceback, stack)
		hook.Run("LuaError", msg, traceback, stack)
	end)

	net.Receive("client_lua_error", function(len, ply)
		local msg = net.ReadString()
		local traceback = net.ReadString()
		local stack = net.ReadTable()

		hook.Run("LuaError", msg, traceback, stack, ply)
	end)
end