local debug_traceback2 = requirex("debug_traceback2")

local function hook_error(cb)
	_G.old_glua_error = _G.old_glua_error or debug.getregistry()[1]
	debug.getregistry()[1] = function(error_message)
		_G.old_glua_error(error_message)

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

			cb(error_message, debug_traceback2(4), stack)
		end)

		if not ok then
			print(err)
		end
	end
end

if CLIENT then
	hook_error(function(msg, traceback, stack)
		net.Start("client_lua_error")
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