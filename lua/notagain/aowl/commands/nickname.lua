AddCSLuaFile()
local PLAYER = FindMetaTable("Player")

PLAYER.SteamNick   = PLAYER.SteamNick or PLAYER.Nick
PLAYER.SteamName   = PLAYER.SteamNick or PLAYER.Nick
PLAYER.RealName    = PLAYER.SteamNick or PLAYER.Nick
PLAYER.RealNick    = PLAYER.SteamNick or PLAYER.Nick
PLAYER.GetRealName = PLAYER.SteamNick or PLAYER.Nick
PLAYER.GetRealNick = PLAYER.SteamNick or PLAYER.Nick

function PLAYER:Nick()
	local nick = self:GetNWString("Nick","")
	return nick:Trim() == "" and self:RealName() or nick
end
PLAYER.Name = PLAYER.Nick
PLAYER.GetNick = PLAYER.Nick
PLAYER.GetName = PLAYER.Nick

if CLIENT then

	net.Receive("aowl_nick_names", function()
		local ply = Player(net.ReadUInt(16))
		local oldNick = net.ReadString()
		local newNick = net.ReadString()

		chat.AddText(team.GetColor(ply:Team()), oldNick, Color(255, 255, 255, 255), " is now called ", team.GetColor(ply:Team()), newNick)
	end)

end

if SERVER then

    util.AddNetworkString("aowl_nick_names")

	function PLAYER:SetNick(nick)
		if not nick or nick:Trim() == "" then
			self:RemovePData("Nick")
		else
			self:SetPData("Nick", nick)
		end
		self:SetNWString("Nick", nick)
	end

	local nextChange = {}
	local nick

    aowl.AddCommand("name|nick=string[404 no name found]", function(caller, line)
		local cd = nextChange[caller:UserID()]
		if cd and cd > CurTime() then
			return false, "You're changing nicks too quickly!"
		end

		local oldNick = caller:Nick()
		caller:SetNick(line)
		net.Start("aowl_nick_names")
		net.WriteUInt(caller:UserID(), 16)
		net.WriteString(oldNick)
		net.WriteString(caller:Nick())
		net.Broadcast()
		nextChange[caller:UserID()] = CurTime() + 2
	end)

	hook.Add("PlayerInitialSpawn", "aowl_nick_names", function(caller)
		if caller:GetPData("Nick") and caller:GetPData("Nick"):Trim() ~= "" then
			caller:SetNick(caller:GetPData("Nick"))
		end
	end)
end
