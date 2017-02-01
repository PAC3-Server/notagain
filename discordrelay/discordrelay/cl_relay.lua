net.Receive( "DiscordMessage", function()
	local nick = net.ReadString()
	local message = net.ReadString()

	chat.AddText(Color(114,137,218), "Discord ", Color(255,255,255), "| ",nick,": ",message);
end )