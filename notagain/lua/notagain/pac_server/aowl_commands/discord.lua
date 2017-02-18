aowl.AddCommand("discord", function(ply)
	if IsValid(ply) then
		ply:SendLua([[SetClipboardText("https://discord.gg/utpR3gJ")]])
		aowl.Message(ply, "Discord link copied to clipboard!")
	end
end)
