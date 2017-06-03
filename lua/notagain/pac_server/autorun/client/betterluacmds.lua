----lua chat beautify---
local LuaChat = {}

CreateClientConVar("luachat_showtime", 0, true, false, "Show timestamp for Lua commands? (1 enables, 0 disables)")
CreateClientConVar("luachat_tagcolors", 0, true, false, "Show tag colours? (1 enables, 0 disables)")

LuaChat.Cmds = {
	["l"]      = {text = "Server",          color = Color(249, 38, 114)},
	["lm"]     = {text = "Self",            color = Color(102, 217, 239), onself = true},
	["ls"]     = {text = "Shared",          color = Color(253, 151, 31)},
	["lb"]     = {text = "Both",            color = Color(166, 226, 46)},
	["lc"]     = {text = "Clients",         color = Color(163, 126, 242)},
	["print"]  = {text = "Server Print",    color = Color(249, 38, 114)},
	["table"]  = {text = "Server Table",    color = Color(249, 38, 114)},
	["keys"]   = {text = "Server Keys",     color = Color(249, 38, 114)},
	["printm"] = {text = "Self Print",      color = Color(102, 217, 239), onself = true},
	["printb"] = {text = "Both Print",      color = Color(166, 226, 46)},
	["printc"] = {text = "Clients Print",   color = Color(163, 126, 242)},
	["cmd"]    = {text = "Console",         color = Color(102, 217, 239), onself = true},
	["rcon"]   = {text = "Server Console",  color = Color(249, 38, 114)},
}

LuaChat.OnClientCmds = { --add commands ran on specific client here
	["lsc"]    = "",
}

LuaChat.IsCommand = function(str)
	local s = string.lower(str)
	local _,replaced = string.gsub(s,"^[!|%.|/]","")

	return replaced >= 1 and true or false
end

local function get(str)
	if not str then return "" end

	if player.FindByName then
		return player.FindByName(str):GetName()
	else
		return str 
	end
end

local function chatText(team_color, ply, line, cmd, target_name, slot_b)
	local arrow = " >> "
	local time_tag = GetConVar("luachat_showtime"):GetBool() and "["..os.date("%H:%M:%S").."] " or ""
	local all_red = not GetConVar("luachat_tagcolors"):GetBool()

	cmd = istable(cmd) and cmd or {text = cmd}

	chat.AddText(Color(158, 158, 153), time_tag, team_color, ply, Color(175, 175, 155), arrow, all_red and Color(244, 66, 66) or cmd.color, target_name or "", cmd.text, Color(248, 248, 242), ": "..(slot_b and slot_b.." " or "")..line)
	-- Alternative: Color(158, 158, 153)
end

LuaChat.DoLuaCommand = function(ply,str)
	if LuaChat.IsCommand(str) and IsValid(ply) then
		local str,_ = string.gsub(str,"^[!|%.|/]","")
		local args = string.Explode(" ",str)
		local cmd = string.lower(args[1])

		local team_color = team.GetColor(ply:Team())
		local line = ""

		if LuaChat.Cmds[cmd] then

			line = table.concat(args," ",2)
			chatText(team_color, ply, line, LuaChat.Cmds[cmd])
			
			return true	

		elseif LuaChat.OnClientCmds[cmd] then
			
			local a = string.Explode(",",args[2])

			cmd = not istable(LuaChat.OnClientCmds[cmd]) and (LuaChat.OnClientCmds[cmd] ~= "" and " "..LuaChat.OnClientCmds[cmd] or "") or LuaChat.OnClientCmds[cmd]
			line = table.concat(args," ",3)

			chatText(team_color, ply, line, cmd, get(a[1]), a[2])
			
			return true 

		end
	end
end

hook.Add("OnPlayerChat","LuaChatCommands",LuaChat.DoLuaCommand)

return LuaChat
