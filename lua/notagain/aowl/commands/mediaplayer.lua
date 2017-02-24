local easylua = requirex("easylua")

if not MediaPlayer then return end

aowl.AddCommand("sub", function(ply, line, target)
	local ent = easylua.FindEntity(target)
	if ent and ent.GetMediaPlayer and ent:GetMediaPlayer() then
		local mp = ent:GetMediaPlayer()
		if mp:HasListener(ply) then
			ply:ChatPrint("You are already subscribed to this Mediaplayer!")
		else
			mp:AddListener(ply)
		end
	else
		ply:ChatPrint("Sure that is a valid mediaplayer")
	end

end)

aowl.AddCommand("unsub", function(ply, line, target)

	local ent = easylua.FindEntity(target)

	if ent and ent.GetMediaPlayer and ent:GetMediaPlayer() then
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