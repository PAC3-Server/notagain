local remove_me = {}

hook.Add("DoPlayerDeath", "drop_weapon_on_death", function(ply)
	if remove_me[ply] and remove_me[ply]:IsValid() and not remove_me[ply]:GetOwner():IsValid() then
		if remove_me[ply].death_drop_pos then
			remove_me[ply]:SetPos(remove_me[ply].death_drop_pos)
			remove_me[ply]:SetAngles(remove_me[ply].death_drop_ang)
		end
	end

	local wep = ply:GetActiveWeapon()
	if wep:IsValid() then
		ply:DropWeapon(wep)
		timer.Simple(0, function()
			wep.death_drop_pos = wep:GetPos()
			wep.death_drop_ang = wep:GetAngles()
		end)
		remove_me[ply] = wep
	end
end)

hook.Add("PlayerSpawn", "drop_weapon_on_death", function(ply)
	if remove_me[ply] and remove_me[ply]:IsValid() and not remove_me[ply]:GetOwner():IsValid() then
		remove_me[ply]:Remove()
	end

	remove_me[ply] = nil
end)

