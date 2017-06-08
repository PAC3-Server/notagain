if SERVER then
    if discordrelay then
        aowl.AddCommand({"relay","discordrelay"}, function(ply,_,com,com2)
            if com == "reload" then
                discordrelay.reload()
            elseif com == "status" then
                local modulec = table.Count(discordrelay.modules)
                local extensionc = table.Count(discordrelay.extensions)
                local is_fetching = timer.Exists("DiscordRelayFetchMessages")
                discordrelay.log("Status:","fetching messages:",is_fetching and "yes" or "no")
                discordrelay.log("Status:",modulec,"modules and",extensionc,"extensions loaded.")
            elseif com == "modules" or com == "extensions" then
                if com2 == "list" then
                    local str = ""
                    for name,_ in pairs(discordrelay[com]) do
                        str = str..name..", "
                    end
                    discordrelay.log(com..":",str)
                end
            end
            -- todo: add more commands?
		end,"developers")
	end
end