local notify = function(ply, afk, time)
	if not IsValid(ply) then return end
	if ply:GetFriendStatus() == "friend" then
		if afk then
			chat.AddText(Color(255,127,127),"⮞ ",Color(200,200,200),ply:GetProperName().." is now ",Color(255,127,127),"away")
		else
			chat.AddText(Color(127,255,127),"⮞ ",Color(200,200,200),ply:GetProperName().." is now ",Color(127,255,127),"back",Color(175,175,175)," (away for "..string.NiceTime(time)..")")
		end
	elseif ply == LocalPlayer() then
		if afk then
			chat.AddText(Color(255,127,127),"⮞ ",Color(200,200,200),"You are now ",Color(255,127,127),"away")
		else
			chat.AddText(Color(127,255,127),"⮞ Welcome Back!",Color(200,200,200)," You were away for ",Color(175,175,175),string.NiceTime(time))
		end
	end
end

hook.Add("InitPostEntity","afk_notifications",function()
	hook.Add("OnPlayerAFK", "afk_notifications",notify)
end)
