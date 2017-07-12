if not MediaPlayer then return end

aowl.AddCommand("sub=entity", function(ply, line, ent)
	if not ent.GetMediaPlayer or not ent:GetMediaPlayer() then
		return false, "not a valid mediaplayer"
	end

	local mp = ent:GetMediaPlayer()

	if mp:HasListener(ply) then
		ply:ChatPrint("You are already subscribed to this Mediaplayer!")
	else
		mp:AddListener(ply)
	end
end)

aowl.AddCommand("unsub=entity", function(ply, line, ent)
	if ent then
		if not ent.GetMediaPlayer or not ent:GetMediaPlayer() then
			return false, "not a valid mediaplayer"
		end

		local mp = ent:GetMediaPlayer()
		if mp.HasListener and mp:HasListener(ply) then
			mp:RemoveListener(ply)
			ply:ChatPrint("Unsubscribed from the mediaplayer!")
		end
	else
		local msg = ""
		for k,v in pairs(MediaPlayer.GetAll()) do
			if v.HasListener and v:HasListener(ply) then
				v:RemoveListener(ply)
				if v.GetEntity then
					local ent = v:GetEntity()
					if msg ~= "" then msg = msg + "\n" end
					msg = msg .. "Unsubscribed from mediaplayer: "..tostring(ent)
				end
			end
		end
		if msg ~= "" then
			ply:ChatPrint(msg)
		end
	end
end)