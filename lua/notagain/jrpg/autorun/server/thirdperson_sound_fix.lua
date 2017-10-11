timer.Create("thirdperson_sound_fix", 0.1, 0, function()
	for _, ply in pairs(player.GetAll()) do
		local tp = ply:GetInfo("battlecam_enabled")
		if tp == "1" then
			local ent = ply:GetViewEntity()

			if ent == ply then
				ply:SetViewEntity(ply:GetActiveWeapon())
				ply.thirdperson_sound_fix_set = true
			end
		else
			if ply.thirdperson_sound_fix_set then
				ply:SetViewEntity(ply)
				ply.thirdperson_sound_fix_set = nil
			end
		end
	end
end)