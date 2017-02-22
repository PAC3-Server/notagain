AddCSLuaFile()

local Tag="console"

if SERVER then
	util.AddNetworkString(Tag)
	
	aowl.AddCommand({"cmd","console"}, function( player , line , cmd )
		if cmd then
			net.Start(Tag)
			net.WriteString(cmd)
			net.Send(player)
		end
	end)
end

if CLIENT then
	net.Receive(Tag,function()
		LocalPlayer():ConCommand(net.ReadString())
	end)
end
