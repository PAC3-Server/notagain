AddCSLuaFile()

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

	local nextChange = {}

	aowl.AddCommand("name|nick=string[]", function(caller, line)
		if not IsValid(caller) or not caller.SetNick then return end
		local cd = nextChange[caller:UserID()]
		if cd and cd > CurTime() then
			return false, "You're changing nicks too quickly!"
		end
		if string.len(string.gsub(line,"<.->","")) >= 15 then
			return false, "Your name is too long"
		end

		local oldNick = caller:Nick()
		caller:SetNick(line)
		net.Start("aowl_nick_names")
		net.WriteUInt(caller:UserID(), 16)
		net.WriteString(oldNick)
		net.WriteString(caller:Nick())
		net.Broadcast()
		nextChange[caller:UserID()] = CurTime() + 2
	end,"players",true)

end