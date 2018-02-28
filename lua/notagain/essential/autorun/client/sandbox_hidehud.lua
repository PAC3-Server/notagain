local hide_these = {
	CHudDamageIndicator = true,
}

timer.Create("sandbox_hide_hud", 0.1, 0, function()
	local ply = LocalPlayer()
	if not ply:IsValid() then return end

	hide_these.CHudHealth = ply:Health() == ply:GetMaxHealth()
	hide_these.CHudBattery = ply:Armor() == 100

	local wep = ply:GetActiveWeapon()

	if wep:IsValid() then
		hide_these.CHudAmmo = wep:Clip1() == wep:GetMaxClip1()
		hide_these.CHudSecondaryAmmo = wep:Clip2() == wep:GetMaxClip2()
	end
end)

hook.Add("HUDShouldDraw", "sandbox_hide_hud", function(element)
	if hide_these[element] == true then
		return false
	end
end)