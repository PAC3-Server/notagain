aowl.AddCommand("rpg", function(ply)
	ply:SetNWBool("rpg", not ply:GetNWBool("rpg"))

	if ply:GetNWBool("rpg") then
		jattributes.SetTable(ply, {mana = 2, stamina = 1, health = 2})
		jattributes.SetMana(ply, jattributes.GetMaxMana(ply))
		jattributes.SetStamina(ply, jattributes.GetMaxStamina(ply))
		ply:ChatPrint("rpg mode enabled")
	else
		jattributes.Disable(ply)
		ply:ChatPrint("rpg mode disabled")
	end
end)