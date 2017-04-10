hook.Add("HUDShouldDraw", "hide_hud", function(element)
	local ply = LocalPlayer()
	if not ply:IsValid() then return end
	
	if (element == "CHudHealth" and ply:Health() == ply:GetMaxHealth()) or (element == "CHudBattery" and ply:Armor() == 100) then
		return false
	end
	
	if element == "CHudAmmo" or element == "CHudSecondaryAmmo" then
		local wep = ply:GetActiveWeapon()

		if wep:IsValid() then
			if element == "CHudAmmo" and wep:Clip1() == wep:GetMaxClip1() then
				return false
			end
			
			if element == "CHudSecondaryAmmo" and wep:Clip2() == wep:GetMaxClip2() then
				return false
			end
		end
	end
end)