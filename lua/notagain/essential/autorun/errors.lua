-- epoe api functions --
-- function api.Msg(...)
-- function api.MsgC(...)
-- function api.MsgN(...)
-- function api.print(...)
-- function api.MsgAll(...)
-- function api.ClientLuaError(str)
-- function api.ErrorNoHalt(...)
-- function api.error(...)

local github = {
	["pac3"] = {
		["url"] = "https://github.com/CapsAdmin/pac3/tree/master/"
	},
	["notagain"] = {
		["url"] = "https://github.com/PAC3-Server/notagain/tree/master/"
	},
	["easychat"] = {
		["url"] = "https://github.com/PAC3-Server/EasyChat/tree/master/"
	},
	["gm-http-discordrelay"] = {
		["url"] = "https://github.com/PAC3-Server/gm-http-discordrelay/tree/master/"
	},
	["includes"] = { -- garry stuff
		["url"] = "https://github.com/Facepunch/garrysmod/tree/master/garrysmod/"
	}
}
github["vgui"] = github["includes"]
github["weapons"] = github["includes"]
github["entities"] = github["includes"]
github["derma"] = github["includes"]
github["menu"] = github["includes"]
github["vgui"] = github["includes"]
github["weapons"] = github["includes"]

local function tostringsafe(obj)
	local ok, str = pcall(tostring, obj)

	if not ok then
		return "tostring error: " .. str
	end

	return str
end

local offset = 3
local max_stack = 2

local function hook_error(cb)
	_G.old_glua_error = _G.old_glua_error or debug.getregistry()[1]
	debug.getregistry()[1] = function(error_message)
		_G.old_glua_error(error_message)

		local ok, err = pcall(function()

			local stack = {}

			for stack_depth = offset, math.huge do
				local info = debug.getinfo(stack_depth)
				if not info then break end

				info.func = nil

				local locals = {}
				for i = 1, math.huge do
					local k, v = debug.getlocal(stack_depth, i)
					if not k then break end
					table.insert(locals, k .. " = " .. tostringsafe(v) .. "\n")
				end
				info.locals = table.concat(locals)

				table.insert(stack, info)

				if stack_depth == offset + max_stack then
					break
				end
			end

			cb(debug.traceback(error_message, 4), stack)
		end)

		if not ok then
			print(err)
		end
	end
end

if CLIENT then

	hook.Add("EPOEAddLinkPatterns", "Clickable Errors", function(t)
		table.insert(t,"(lua/.-):(%d+):?")
	end)

	hook.Add("EPOEOpenLink", "Clickable Errors", function(l)
		if not l then return end
		local yes = false
		l = l:gsub("(lua/.-):(%d+):?", function(l, n)
			local n = n or ""
			local addon = l:match("lua/(.-)/")
			if addon and github[addon] then
				yes = true
				return github[addon].url .. l .. "#L" .. n
			end
			return "???"
		end)
		if yes then
			gui.OpenURL(l)
		end
		return true
	end)

	hook_error(function(error_msg, stack)
		net.Start("ClientError")
			net.WriteString(error_msg)
			net.WriteTable(stack)
		net.SendToServer()
	end)
end

if SERVER then
	util.AddNetworkString("ClientError")
	--local old_error = debug.getregistry()[1]

	hook_error(function(error_msg, stack)
		if epoe then
			local api = epoe.api
			api.MsgC(Color(255,0,0), "-- [ ERROR BY FUNCTION ")
			api.Msg(stack[1].name)
			api.MsgC(Color(255,0,0), " ] --")
			api.Msg("\n")
			api.MsgN(stack[1].locals)
			api.error(error_msg)
			api.MsgC(Color(255,0,0), "--   --")
			api.Msg("\n")

		else
			print(fname, "\n", src, "\n", stack[1].locals, "\n", error_msg) -- fallback????
		end

		hook.Run("LuaError", error_msg, stack)
	end)

	local errored = {}

	net.Receive("ClientError", function(len, ply)
		local msg = net.ReadString()
		local stack = net.ReadTable()

		if errored[msg] then return end
		errored[msg] = true

		if epoe then
			local api = epoe.api
			api.MsgC(Color(255,0,0), "-- [ CLIENT ERROR BY FUNCTION ")
			api.Msg(stack[1].name or "???")
			api.MsgC(Color(255,0,0), " FROM ")
			api.Msg(ply:Nick() .. "/" .. ply:SteamID())
			api.MsgC(Color(255,0,0), " ] --")
			api.Msg("\n")
			api.MsgN(stack[1].locals or "???")
			api.error(msg)
			api.MsgC(Color(255,0,0), "--   --")
			api.Msg("\n")

		else
			print(fname, "\n", stack[1].locals, "\n", msg) -- fallback????
		end
		hook.Run("ClientLuaError", msg, stack, ply)
	end)
end