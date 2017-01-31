aowl.AddCommand("settod", function(player, line, val)
	local val = val or "realtime"
	local time24 = tonumber(val)

	if time24 then
		RunConsoleCommand("sv_tod", "0")
		tod.SetCycle((time24 / 24)%1)
	elseif val == "demo" then
		RunConsoleCommand("sv_tod", "2")
	elseif val == "realtime" or time24 < 0 then
		RunConsoleCommand("sv_tod", "1")
	end

	timer.Simple(0.1, function()
		tod.SetMode(tod.cvar:GetInt())
	end)
end, "admin")
