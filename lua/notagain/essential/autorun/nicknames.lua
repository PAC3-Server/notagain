local PLAYER = FindMetaTable("Player")
PLAYER.old_Nick = PLAYER.old_Nick or PLAYER.Nick

PLAYER.Nick = function(self)
	local nick = self:GetNWString("Nick")
	if nick and string.TrimLeft(nick) ~= "" then
		return nick
	end
	return self.old_Nick(self)
end

PLAYER.old_Name = PLAYER.old_Name or PLAYER.Name
PLAYER.old_GetName = PLAYER.old_GetName or PLAYER.GetName

PLAYER.Name = PLAYER.Nick
PLAYER.GetName = PLAYER.Nick

if SERVER then

	PLAYER.SetNick = function(self,nick)
		local proper,_ = string.gsub((nick or ""),"<.->","")
		if not nick or string.TrimLeft(proper) == "" then
			self:SetPData("Nick","")
		else
			self:SetPData("Nick", nick)
		end
		self:SetNWString("Nick", nick)
	end

	hook.Add("PlayerInitialSpawn", "nicknames", function(ply)
		if ply:GetPData("Nick") and string.TrimLeft(ply:GetPData("Nick")) ~= "" then
			ply:SetNick(ply:GetPData("Nick"))
		end
	end)

end
