AddCSLuaFile()

if SERVER then
	util.AddNetworkString("jalert")

	aowl.AddCommand("alert|jalert|psa=string,number[0]", function(ply, line, message, delay)
		net.Start("jalert")
			net.WriteString(message)
			net.WriteDouble(delay)
		net.Broadcast()
	end, "developers")
end

if CLIENT then
	net.Receive("jalert",function()
		local message = net.ReadString()
		local delay = net.ReadDouble()
		JAlert.DoAlert(message, delay)
	end)
end
