hook.Add("NPCSpeak", "npc_chat", function(npc, text)
	if npc:EyePos():Distance(LocalPlayer():EyePos()) > 1500 then return end

	local color
	if jrpg.IsFriend(LocalPlayer(), npc) then
		color = team.GetColor(TEAM_FRIENDS)
	else
		color = team.GetColor(TEAM_PLAYERS)
	end

	local str = language.GetPhrase(text)
	if str and str ~= text then
		str = str:gsub("%b<>", ""):Trim()
		if str ~= "" and not str:find("^%p") then
			chat.AddText(color, jrpg.GetFriendlyName(npc), color_white, ": ", str)
		end
	end
end)