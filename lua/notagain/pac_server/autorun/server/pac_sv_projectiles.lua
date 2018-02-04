if engine.ActiveGamemode() ~= "sandbox" then
	timer.Simple(0, function() RunConsoleCommand("pac_sv_projectiles", "0") end)
else
	timer.Simple(0, function() RunConsoleCommand("pac_sv_projectiles", "1") end)
end