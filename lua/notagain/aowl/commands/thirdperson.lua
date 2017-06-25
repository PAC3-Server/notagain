AddCSLuaFile()

local Tag="thirdperson"

if SERVER then
	util.AddNetworkString(Tag)
	
	aowl.AddCommand({"ctp","thirdperson","view","3p"}, function( player , line  )
		if IsValid(player) then
			net.Start(Tag)
			net.Send(player)
		end
	end)
end

if CLIENT then
	net.Receive(Tag,function()
		if ctp.Enabled then
			ctp.Disable()
		else
			ctp.Enable()
		end
	end)
end
