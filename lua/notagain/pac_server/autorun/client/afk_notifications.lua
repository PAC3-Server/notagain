hook.Add("OnPlayerAFK", "afk_notifications", function(ply, afk, time)
	if ply:GetFriendStatus() == "friend" then
		if afk then
			chat.AddText(Color(209,62,57),"⮞ ",Color(200,200,200),ply:GetName().." is now ",Color(209,62,57),"away")
		else
			chat.AddText(Color(92,184,92),"⮞ ",Color(200,200,200),ply:GetName().." is now ",Color(92,184,92),"back",Color(175,175,175)," (away for "..string.NiceTime(time)..")")
		end
	elseif ply == LocalPlayer() then
		if afk then
			chat.AddText(Color(209,62,57),"⮞ ",Color(200,200,200),"You are now ",Color(209,62,57),"away")
		else
			chat.AddText(Color(92,184,92),"⮞ Welcome Back!",Color(200,200,200)," You were away for ",Color(175,175,175),string.NiceTime(time))
		end
	end
end)