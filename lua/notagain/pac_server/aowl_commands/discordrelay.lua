if SERVER then
    if discordrelay then
        aowl.AddCommand({"relay","discordrelay"}, function(ply,_,com)
            if com == "reload" then
                discordrelay.reload()
            end
            -- todo: add more commands?
		end)
	end
end