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
	local nick

    aowl.AddCommand("name|nick=string[ ]", function(caller, line)
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

end
