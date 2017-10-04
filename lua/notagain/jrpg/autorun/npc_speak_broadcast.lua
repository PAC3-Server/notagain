hook.Add("EntityEmitSound", "npc_speak_broadcast", function(data)
	if not data.Entity:IsNPC() or data.Channel ~= 2 then return end

	if SERVER then
		net.Start("npc_speak_broadcast")
			net.WriteEntity(data.Entity)
			net.WriteString(data.OriginalSoundName)
		net.Broadcast()
	else
		hook.Run("NPCSpeak", data.Entity, data.OriginalSoundName)
	end
end)

if SERVER then
	util.AddNetworkString("npc_speak_broadcast")
end

if CLIENT then
	net.Receive("npc_speak_broadcast", function()
		local ent = net.ReadEntity()
		local str = net.ReadString()

		if ent:IsValid() then
			hook.Run("NPCSpeak", ent, str)
		end
	end)
end