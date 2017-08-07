AddCSLuaFile()

if SERVER then
	util.AddNetworkString("jalert")

	aowl.AddCommand("alert|jalert|psa=string,number[0]", function(ply, line, message, delay)
		if not message then return end
		local delay = delay or 10
		net.Start("jalert")
			net.WriteString(message)
			net.WriteInt(delay,32)
		net.Broadcast()
	end, "developers",true)
end

if CLIENT then
	net.Receive("jalert",function()
		local message = net.ReadString()
		local delay = net.ReadInt(32)
		if JAlert then
			JAlert.DoAlert(message, delay)
		end
	end)
end
