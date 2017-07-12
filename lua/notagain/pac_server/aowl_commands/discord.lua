aowl.AddCommand("discord", function(ply)
	ply:SendLua([[SetClipboardText("https://discord.gg/utpR3gJ")]])
	aowl.Message(ply, "Discord link copied to clipboard!")
end)