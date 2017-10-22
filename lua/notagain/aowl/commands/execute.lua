aowl.AddCommand("rcon", function(ply, line)
	game.ConsoleCommand(line .. "\n")
end, "developers")

aowl.AddCommand("cvar=string",function(pl, line, a, b)
	if b then
		local var = GetConVar(a)
		if var then
			local cur = var:GetString()
			RunConsoleCommand(a,b)
			timer.Simple(0.1,function()
				local new = var:GetString()
				pl:ChatPrint("ConVar: "..a..' '..cur..' -> '..new)
			end)
			return
		else
			return false,"ConVar "..a..' not found!'
		end
	end

	pcall(require,'cvar3')

	if not cvars.GetAllConVars then
		local var = GetConVar(a)
		if var then
			local val = var:GetString()
			if not tonumber(val) then val=string.format('%q',val) end

			pl:ChatPrint("ConVar: "..a..' '..tostring(val))
		else
			return false,"ConVar "..a..' not found!'
		end
	end
end,"developers")

aowl.AddCommand("cexec|exec=player_admin|player_alter|self,string_rest", function(ply, line, ent, str)
	ent:SendLua(string.format("LocalPlayer():ConCommand(%q,true)", str))
	Msg("[cexec] ") print("from ",ply," to ",ent) print(string.format("LocalPlayer():ConCommand(%q,true)", str))
	hook.Run("AowlTargetCommand", ply, "cexec", ent, {code = str})
end)

aowl.AddCommand("retry|rejoin=player_alter|self", function(ply, line, target)
	target:SendLua("LocalPlayer():ConCommand('retry')")
end)