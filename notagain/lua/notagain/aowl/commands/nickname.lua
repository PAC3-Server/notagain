AddCSLuaFile()

local META = FindMetaTable("Player")

function META:SetNick(nick)
	nick = nick or self:RealNick()
	if #string.Trim((string.gsub(nick,"%^%d",""))) == 0 then
		nick = self:RealNick()
	end
	for k, v in pairs(player.GetAll()) do
		if v:Nick() == nick and v ~= self and not self:IsAdmin() then
			return
		end
	end
	if SERVER and type(nick) == "string" or type(nick) == "nil" then
		--hook.Call("NickChange", nil, self, self:GetNWString("nick_override", self:RealName()), nick)
		self:SetNWString("nick_override", nick)
		if not isstring(nick) or nick == self:RealNick() then
			self:RemovePData("PlayerNick")
		else
			self:SetPData("PlayerNick", nick)
		end
	end
	self.nick_override = nick
end

do
	local cvar = CreateConVar("sh_playernick_enabled", "1")

	META.OldGetName = META.OldGetName or META.GetName

	function META:GetName(...)
		local ok = playernick and cvar:GetBool() and type(self) == "Player" and self.IsValid and self:IsValid()
		return ok and (hook.Call("PlayerNick", GAMEMODE, self, self:RealNick()) or self:RealNick()) or self:OldGetName(...) or "Invalid player!?!?"
	end

	META.Nick = META.GetName
	META.Name = META.GetName

	META.RealNick = META.OldGetName
	META.RealName = META.OldGetName
	META.GetRealName = META.OldGetName
end

do
	if SERVER then
		hook.Add("PlayerInitialSpawn", "PlayerNick", function(ply)
			timer.Simple(1,function()
				if IsValid(ply) then
					local nick = ply:GetPData("PlayerNick")
					if isstring(nick) then
						ply:SetNick(nick)
					end
				end
			end)
		end)
	end

	hook.Add("PlayerNick", "playernick_test_hook", function(ply, nick)
		return ply:GetNWString("nick_override", ply:RealNick())
	end)
end

aowl.AddCommand({"name","nick","setnick","setname","nickname"}, function(player, line)
	if line then
		line=line:Trim()
		if(line=="") or line:gsub(" ","")=="" then
			line = nil
		end
		if line and #line>40 then
			if not line.ulen or line:ulen()>40 then
				return false,"my god what are you doing"
			end
		end
	end
	timer.Create("setnick"..player:UserID(),1,1,function()
		if IsValid(player) then
			player:SetNick(line)
		end
	end)
end, "players", true)

