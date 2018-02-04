if engine.ActiveGamemode() ~= "sandbox" then return end

timer.Create("unlimited_ammo", 0.25, 0, function()
	for _, ply in pairs(player.GetAll()) do
		if ply.infammo == nil or ply.infammo then
			local wep = ply:GetActiveWeapon()

			if wep:IsValid() then
				local max = wep:GetMaxClip1()
				if wep:Clip1() < max then
					wep:SetClip1(max)
				end

				local max = wep:GetMaxClip2()
				if wep:Clip2() < max then
					wep:SetClip2(max)
				end

				local id = wep:GetPrimaryAmmoType()
				local max = game.GetAmmoMax(id)
				if ply:GetAmmoCount(id) < max then
					ply:SetAmmo(max, id)
				end

				local id = wep:GetSecondaryAmmoType()
				local max = game.GetAmmoMax(id)
				if ply:GetAmmoCount(id) < max then
					ply:SetAmmo(max, id)
				end
			end
		end
	end
end)