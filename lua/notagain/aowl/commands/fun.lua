aowl.AddCommand("fov=number[90],number[0.3]",function(ply, line, fov, delay)
	fov = math.Clamp(fov, 1, 350)
	ply:SetFOV(fov, delay)
end)

aowl.AddCommand("bot=string_trim[create],string[]",function(ply, line, what, name)
	if what == "create" then
		game.ConsoleCommand("bot\n")
		hook.Add("OnEntityCreated", "botbring", function(bot)
			if not bot:IsPlayer() or not bot:IsBot() then return end
			hook.Remove("OnEntityCreated","botbring")

			timer.Simple(0, function()
				aowl.Execute(ply, "bring _" .. bot:EntIndex())
				if name ~= "" and bot.SetNick then
					bot:SetNick(name)
				end
			end)
		end)

	elseif what == "kick" then
		for k,v in pairs(player.GetBots()) do
			v:Kick"bot kick"
		end
	elseif what == "zombie" then
		game.ConsoleCommand("bot_zombie 1\n")
	elseif what == "zombie 0" or what == "nozombie" then
		game.ConsoleCommand("bot_zombie 0\n")
	elseif what == "follow" or what == "mimic" then
		game.ConsoleCommand("bot_mimic "..ply:EntIndex().."\n")
	elseif what == "nofollow" or what == "nomimic" or what == "follow 0" or what == "mimic 0" then
		game.ConsoleCommand("bot_mimic 0\n")
	end
end, "developers")

aowl.AddCommand("nextbot=string_trim[mingebag]",function(ply, line, name)
	aowl.Execute(me, "bring _" .. player.CreateNextBot(name):EntIndex())
end, "developers")

