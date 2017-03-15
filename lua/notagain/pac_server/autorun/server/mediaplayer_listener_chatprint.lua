hook.Add("MediaPlayerAddListener", "mediaplayer_listener_chatprint", function(mp, ply)
	for k, v in pairs(mp:GetListeners()) do
		if ply ~= v then
			v:ChatPrint(ply:Nick() .. " has subscribed to " .. tostring(mp))
			ply:ChatPrint(v:Nick() .. " is subscribed to " .. tostring(mp))
		end
	end
end)

hook.Add("MediaPlayerRemoveListener", "mediaplayer_listener_chatprint", function(mp, ply)
	for k, v in pairs(mp:GetListeners()) do
		v:ChatPrint(ply:Nick() .. " has unsubscribed from " .. tostring(mp))
	end
end)