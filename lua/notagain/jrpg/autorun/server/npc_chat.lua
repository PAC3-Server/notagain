hook.Add("PlayerSay", "npc_chat", function(ply, txt)
	local ent = ply:GetEyeTrace().Entity
	if ent:IsNPC() then
		txt = txt:lower()
		if
			txt:find("hello", nil, true) or
			txt:find("hey", nil, true) or
			txt:find("hi", nil, true)
		then
			ent:Fire("SpeakResponseConcept", "TLK_HELLO", 1)
		else
			if math.random() > 0.5 then
				ent:Fire("SpeakResponseConcept", "TLK_IDLE", 1)
			else
				ent:Fire("SpeakResponseConcept", "TLK_STARE", 1)
			end
		end
	end
end)