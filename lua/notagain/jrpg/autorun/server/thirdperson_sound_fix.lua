timer.Create("thirdperson_sound_fix", 0.1, 0, function()
	for _, ply in pairs(player.GetAll()) do
		local tp = ply:GetInfo("battlecam_enabled")
		if tp == "1" then
			local ent = ply:GetViewEntity()

			if ent == ply then
				SafeRemoveEntity(ply.tp_soundfix_dummy)

				ply.tp_soundfix_dummy = ents.Create("prop_dynamic")
				ply.tp_soundfix_dummy:SetPos(ply:GetPos())
				ply.tp_soundfix_dummy:SetParent(ply)
				ply.tp_soundfix_dummy:SetOwner(ply)
				ply.tp_soundfix_dummy:SetModel("models/error.mdl")
				ply.tp_soundfix_dummy:SetNoDraw(true)
				ply.tp_soundfix_dummy:Spawn()

				ply:SetViewEntity(ply.tp_soundfix_dummy)
				ply.thirdperson_sound_fix_set = true
			end
		else
			if ply.thirdperson_sound_fix_set then
				SafeRemoveEntity(ply.tp_soundfix_dummy)
				ply:SetViewEntity(ply)
				ply.thirdperson_sound_fix_set = nil
			end
		end
	end
end)