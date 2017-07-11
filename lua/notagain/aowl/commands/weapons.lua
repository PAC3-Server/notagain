aowl.AddCommand("drop",function(ply)
	if GAMEMODE.DropWeapon then
		GAMEMODE:DropWeapon(ply)
	else
		if ply:GetActiveWeapon():IsValid() then
			ply:DropWeapon(ply:GetActiveWeapon())
		end
	end
end)

do -- give weapon
	local prefixes = {
		"",
		"weapon_",
		"weapon_fwp_",
		"weapon_cs_",
		"tf_weapon_",
	}

	local weapons_engine = {
		weapon_357 = true,
		weapon_ar2 = true,
		weapon_bugbait = true,
		weapon_crossbow = true,
		weapon_crowbar = true,
		weapon_frag = true,
		weapon_physcannon = true,
		weapon_pistol = true,
		weapon_rpg = true,
		weapon_shotgun = true,
		weapon_slam = true,
		weapon_smg1 = true,
		weapon_stunstick = true,
		weapon_physgun = true
	}

	aowl.AddCommand("give=player,nil|string[wep],number[0],number[0]", function(ply, line, ent, class, ammo1, ammo2)
		if class == "wep" then
			local wep = ply:GetActiveWeapon()

			if not IsValid(wep) then
				return false, "invalid weapon"
			end

			class = wep:GetClass()
		end

		for _, prefix in ipairs(prefixes) do
			local class = prefix .. weapon

			if weapons.GetStored(class) == nil and not weapons_engine[class] then continue end
			if ent:HasWeapon(class) then ent:StripWeapon(class) end
			local wep = ent:Give(class)

			if IsValid(wep) then
				wep.Owner = wep.Owner or ent
				ent:SelectWeapon(class)
				if wep.GetPrimaryAmmoType then
					ent:GiveAmmo(ammo1,wep:GetPrimaryAmmoType())
				end
				if wep.GetSecondaryAmmoType then
					ent:GiveAmmo(ammo2,wep:GetSecondaryAmmoType())
				end
				return
			end
		end

		return false, "couldn't find " .. weapon
	end, "developers")
end

aowl.AddCommand("giveammo=number[500],string|nil",function(ply, line, ammo, ammotype)
	if not ply:Alive() or not IsValid(ply:GetActiveWeapon()) then return end

	local wep = ply:GetActiveWeapon()

	if ammotype then
		ply:GiveAmmo(ammo, ammotype)
	elseif wep.GetPrimaryAmmoType and wep:GetPrimaryAmmoType() ~= "none" then
		ply:GiveAmmo(ammo, wep:GetPrimaryAmmoType())
	end
end)