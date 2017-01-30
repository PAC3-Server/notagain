timer.Simple(0, function()
	RunConsoleCommand("r_radiosity", "4") -- this is gonna be default in the next update
end)

-- Hostnamefix
function GetHostName()
	return GetGlobalString("ServerName")
end
