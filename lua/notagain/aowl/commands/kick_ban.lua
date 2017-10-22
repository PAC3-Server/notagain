aowl.AddCommand("kick=player,string[bye]", function(ply, line, ent, reason)
	-- clean them up at least this well...
	if cleanup and cleanup.CC_Cleanup then
		cleanup.CC_Cleanup(ent,"gmod_cleanup",{})
	end

	aowlMsg("kick", tostring(ply).. " kicked " .. tostring(ent) .. " for " .. reason)

	hook.Run("AowlTargetCommand", ply, "kick", ent, {reason = reason})

	return ent:Kick(reason)

end, "developers")

local ok={d=true,m=true,y=true,s=true,h=true,w=true}
local function parselength_en(line) -- no months. There has to be a ready made version of this.

	local res={}

	line=line:Trim():lower()
	if tonumber(line)~=nil then
		res.m=tonumber(line)
	elseif #line>1 then
		line=line:gsub("%s","")
		for dat,what in line:gmatch'([%d]+)(.)' do

			if res[what] then return false,"bad format" end
			if not ok[what] then return false,("bad type: "..what) end
			res[what]=tonumber(dat) or -1

		end
	else
		return false,"empty string"
	end

	local len = 0
	local d=res
	local ok
	if d.y then	ok=true len = len + d.y*31556926 end
	if d.w then ok=true len = len + d.w*604800 end
	if d.d then	ok=true len = len + d.d*86400 end
	if d.h then	ok=true len = len + d.h*3600 end
	if d.m then	ok=true len = len + d.m*60 end
	if d.s then	ok=true len = len + d.s*1 end

	if not ok then return false,"nothing specified" end
	return len

end

aowl.AddCommand("ban=player|string,number[0],string[no reason]", function(ply, line, id, length, reason)
	local ip

	if not isstring(id) then
		ip = id:IPAddress():match("(.-):")
		id = id:SteamID()
	end

	hook.Run("AowlTargetCommand", ply, "ban", id, {reason = reason, time = length})

	local t = {"banid", length, id}
	game.ConsoleCommand(table.concat(t, " ") .. "\n")

	--if ip then RunConsoleCommand("addip", length or 0, ip) end -- unban ip??
	timer.Simple(0.1, function()
		local t = {"kickid", id, reason}
		game.ConsoleCommand(table.concat(t, " ") .. "\n")
		game.ConsoleCommand("writeid\n")
	end)
end, "developers")

aowl.AddCommand("unban=string,string[no reason]", function(ply, line, id, reason)
	local t = {"removeid", id}
	game.ConsoleCommand(table.concat(t, " ") .. "\n")
	game.ConsoleCommand("writeid\n")
	hook.Run("AowlTargetCommand", ply, "unban", id, {reason = reason})
end, "developers")

aowl.AddCommand("exit=player_alter,string[no reason]", function(ply, line, ent, reason)
	hook.Run("AowlTargetCommand", ply, "exit", ent, {reason = reason})

	ent:SendLua([[RunConsoleCommand("gamemenucommand","quitnoconfirm")]])

	timer.Simple(0.09+(ent:Ping()*0.001), function()
		if IsValid(ent) then
			ent:Kick("Exit: " .. reason)
		end
	end)
end)