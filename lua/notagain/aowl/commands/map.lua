local easylua = requirex("easylua")

aowl.AddCommand("map", function(ply, line, map, time)
	if map and file.Exists("maps/"..map..".bsp", "GAME") then
		time = tonumber(time) or 10
		aowl.CountDown(time, "CHANGING MAP TO " .. map, function()
			game.ConsoleCommand("changelevel " .. map .. "\n")
		end)
	else
		return false, "map not found"
	end
end, "developers")

aowl.AddCommand("nextmap", function(ply, line, map)
	ply:ChatPrint("The next map is "..game.NextMap())
end, "players", true)

aowl.AddCommand("setnextmap", function(ply, line, map)
	if map and file.Exists("maps/"..map..".bsp", "GAME") then
		game.SetNextMap(map)
		ply:ChatPrint("The next map is now "..game.NextMap())
	else
		return false, "map not found"
	end
end, "developers")

aowl.AddCommand("maprand=string_trim,number[10]", function(player, line, map, time)
	local maps = file.Find("maps/*.bsp", "GAME")
	local candidates = {}

	for k, v in ipairs(maps) do
		if (not map or map=='') or v:find(map) then
			table.insert(candidates, v:match("^(.*)%.bsp$"):lower())
		end
	end

	if #candidates == 0 then
		return false, "map not found"
	end

	local map = table.Random(candidates)

	aowl.CountDown(time, "CHANGING MAP TO " .. map, function()
		game.ConsoleCommand("changelevel " .. map .. "\n")
	end)
end, "developers")

aowl.AddCommand("maps", function(ply, line)
	local files = file.Find("maps/" .. (line or ""):gsub("[^%w_]", "") .. "*.bsp", "MOD")
	for _, fn in pairs( files ) do
		ply:ChatPrint(fn:match("(.+)%.bsp"))
	end

	local msg="Total maps found: "..#files

	ply:ChatPrint(("="):rep(msg:len()))
	ply:ChatPrint(msg)
end)

aowl.AddCommand("resetall", function(player, line)
	aowl.CountDown(line, "RESETING SERVER", function()
		game.CleanUpMap()
		for k, v in ipairs(_G.player.GetAll()) do v:Spawn() end
	end)
end, "developers")

aowl.AddCommand("clearserver|cleanupserver|serverclear|cleanserver|resetmap=number[5]", function(player, line, time)
	aowl.CountDown(time, "CLEANING UP SERVER", function()
		game.CleanUpMap()
	end)
end,"developers")

aowl.AddCommand("cleanup=player|string", function(ply, line, ent)
	if ent == "disconnected" or ent == "#disconnected" then
		prop_owner.ResonanceCascade()
		return
	end

	if not ply:IsAdmin() then
		if ent == ply then
			if cleanup and cleanup.CC_Cleanup then
				cleanup.CC_Cleanup(ply, "gmod_cleanup", {})
			end
			hook.Run("AowlTargetCommand", ply, "cleanup", ply)
			return
		end

		return false, "You cannot cleanup anyone but yourself!"
	end

	if ent:IsPlayer() then
		if cleanup and cleanup.CC_Cleanup then
			cleanup.CC_Cleanup(ent, "gmod_cleanup", {})
		end
		hook.Run("AowlTargetCommand", ply, "cleanup", ent)
		return
	end

	if not line or line == "" then
		aowl.Execute(ply, "cleanupserver")
		return
	end
end)

aowl.AddCommand("restart=number[20],string_trim[no reason]", function(player, line, seconds, reason)
	aowl.CountDown(seconds, "RESTARTING SERVER " .. reason, function()
		game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n")
	end)
end, "developers")

aowl.AddCommand("reboot=number[20]", function(player, line, time)
	aowl.CountDown(time, "SERVER IS REBOOTING", function()
		BroadcastLua("LocalPlayer():ConCommand(\"disconnect; snd_restart; retry\")")

		timer.Simple(0.5, function()
			game.ConsoleCommand("shutdown\n")
			game.ConsoleCommand("_restart\n")
		end)
	end)
end, "developers")

aowl.AddCommand("uptime",function()
	PrintMessage(3,"Server uptime: "..string.NiceTime(SysTime())..' | Map uptime: '..string.NiceTime(CurTime()))
end)
