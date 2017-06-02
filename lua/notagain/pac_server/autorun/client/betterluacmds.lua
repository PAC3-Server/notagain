----lua chat beautify---
local LuaChat = {}

LuaChat.Cmds = {
	["l"]      = "Server",
	["lm"]     = "Self",
	["ls"]     = "Shared",
	["lb"]     = "Both",
	["lc"]     = "Clients",
	["print"]  = "Server Print",
	["table"]  = "Server Table",
	["keys"]   = "Server Keys",
	["printm"] = "Self Print",
	["printb"] = "Both Print",
	["printc"] = "Clients Print",
}

LuaChat.OnClientCmds = { --add commands ran on specific client here
	["lsc"]    = "",
}

LuaChat.IsCommand = function(str)
	local s = string.lower(str)
	local _,replaced = string.gsub(s,"^[!|%.|/]","")

	return replaced >= 1 and true or false
end

local get = function(str)
	if not str then return "" end

	if player.FindByName then
		return player.FindByName(str):GetName()
	else
		return str 
	end
end

LuaChat.DoLuaCommand = function(ply,str)

	if LuaChat.IsCommand(str) and IsValid(ply) then
		local str,_ = string.gsub(str,"^[!|%.|/]","")
		local args = string.Explode(" ",str)
		local cmd = string.lower(args[1])

		if LuaChat.Cmds[cmd] then
			
			chat.AddText(team.GetColor(ply:Team()),ply,Color(61,61,61)," -> ",Color(244,66,66),LuaChat.Cmds[cmd],Color(175,175,175),": "..table.concat(args," ",2,#args))
			
			return true
			
		elseif LuaChat.OnClientCmds[cmd] then
			
			local a = string.Explode(",",args[2])
			

			chat.AddText(team.GetColor(ply:Team()),ply,Color(61,61,61)," -> ",Color(244,66,66),get(a[1]),(LuaChat.OnClientCmds[cmd] ~= "" and " "..LuaChat.OnClientCmds[cmd] or ""),Color(175,175,175),": "..a[2].." "..table.concat(args," ",3,#args))

			
			return true 
		
		end

	end

end

hook.Add("OnPlayerChat","LuaChatCommands",LuaChat.DoLuaCommand)

return LuaChat
