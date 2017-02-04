AddCSLuaFile()

local Tag="jalert"

if SERVER then
	util.AddNetworkString(Tag)
	
	aowl.AddCommand({"alert", "jalert", "psa"}, function( player , line , message , delay)
		if message then
			net.Start(Tag)
			net.WriteString(message)
			if delay then
				net.WriteString(delay)
			end
			net.Broadcast()
		end
	end, "developers")
end

if CLIENT then
	net.Receive(Tag,function()
		local message = net.ReadString()
		local delay = tonumber(net.ReadString()) or nil
		Alert(message,delay)
	end)
end
