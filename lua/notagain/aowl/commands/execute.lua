local easylua = requirex("easylua")

TRANSFER_ID=TRANSFER_ID or 0
aowl.AddCommand("getfile",function(pl,line,target,name)
	if not GetNetChannel then return end
	name=name:Trim()
	if file.Exists(name,'GAME') then return false,"File already exists on server" end
	local ent = easylua.FindEntity(target)

	if ent:IsValid() and ent:IsPlayer() then
		local chan = GetNetChannel(ent)
		if chan then
			TRANSFER_ID=TRANSFER_ID+1
			chan:RequestFile(name,TRANSFER_ID)
			return
		end
	end

	return false, aowl.TargetNotFound(target)
end,"developers")

aowl.AddCommand("sendfile",function(pl,line,target,name)
	if not GetNetChannel then return end
	name=name:Trim()
	if not file.Exists(name,'GAME') then return false,"File does not exist" end

	if target=="#all" or target == "@" then
		for k,v in next,player.GetHumans() do
			TRANSFER_ID=TRANSFER_ID+1
			local chan=GetNetChannel(v)
			chan:SendFile(name,TRANSFER_ID)
			chan:SetFileTransmissionMode(false)
		end
		return
	end

	local ent = easylua.FindEntity(target)

	if ent:IsValid() and ent:IsPlayer() then
		local chan = GetNetChannel(ent)
		if chan then
			TRANSFER_ID=TRANSFER_ID+1
			chan:SendFile(name,TRANSFER_ID)
			chan:SetFileTransmissionMode(false)
			return
		end

	end

	return false, aowl.TargetNotFound(target)
end,"developers")

aowl.AddCommand("rcon", function(ply, line)
	line = line or ""

	if false and ply:IsUserGroup("developers") then
		for key, value in pairs(rcon_whitelist) do
			if not str:find(value, nil, 0) then
				return false, "cmd not in whitelist"
			end
		end

		for key, value in pairs(rcon_blacklist) do
			if str:find(value, nil, 0) then
				return false, "cmd is in blacklist"
			end
		end
	end

	game.ConsoleCommand(line .. "\n")

end, "developers")

aowl.AddCommand("cvar",function(pl,line,a,b)

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

aowl.AddCommand("cexec", function(ply, line, target, str,extra)
	local ent = easylua.FindEntity(target)

	if extra then return false,"too many parameters" end

	if ent:IsPlayer() then
		ent:SendLua(string.format("LocalPlayer():ConCommand(%q,true)", str))
		Msg("[cexec] ") print("from ",ply," to ",ent) print(string.format("LocalPlayer():ConCommand(%q,true)", str))
		hook.Run("AowlTargetCommand", ply, "cexec", ent, str)
		return
	end

	return false, aowl.TargetNotFound(target)
end, "developers")

aowl.AddCommand({"retry", "rejoin"}, function(ply, line, target)
	target = target and easylua.FindEntity(target) or nil

	if not IsValid(target) or not target:IsPlayer() then
		target = ply
	end

	target:SendLua("LocalPlayer():ConCommand('retry')")
end)


aowl.AddCommand("god",function(ply, mode)
	if mode == "help" then
		ply:ChatPrint([[
			0 = godmode off
			1 = godmode on
			2 = only allow damage from world (fall damage, map damage, etc)
			3 = only allow damage from steam friends and world
		]])
	elseif not mode or mode == "" then
		local num = ply:GetInfoNum("cl_godmode",0)
		if num > 0 then
			ply:ConCommand("cl_godmode 0")
			ply:ChatPrint("godmode: off")
		else
			ply:ConCommand("cl_godmode 1")
			ply:ChatPrint("godmode: on")
		end
	elseif mode == "0" or mode == "off" then
		ply:ConCommand("cl_godmode 0")
		ply:ChatPrint("godmode: off")
	elseif mode == "1" or mode == "on" then
		ply:ConCommand("cl_godmode 1")
		ply:ChatPrint("godmode: on")
	elseif mode == "2" or mode == "world" then
		ply:ConCommand("cl_godmode 2")
		ply:ChatPrint("godmode: only allow damage from world (fall damage, map damage, etc)")
	elseif mode == "3" or mode == "world and friends" then
		ply:ConCommand("cl_godmode 3")
		ply:ChatPrint("godmode: only allow damage from steam friends and world (fall damage, map damage, etc)")
	end
end, "players", true)

aowl.AddCommand("ungod",function(ply) ply:ConCommand("cl_godmode 0") ply:ChatPrint("godmode: off") end,"players",true)
