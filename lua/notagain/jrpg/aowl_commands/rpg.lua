aowl.AddCommand("rpg", function(ply)
	ply:SetNWBool("rpg", not ply:GetNWBool("rpg"))

	if ply:GetNWBool("rpg") then
		jattributes.SetTable(ply, {mana = 75, stamina = 25, health = 100})
		jlevel.LoadStats(ply)
		jattributes.SetMana(ply, jattributes.GetMaxMana(ply))
		jattributes.SetStamina(ply, jattributes.GetMaxStamina(ply))
		ply:ChatPrint("rpg mode enabled")
	else
		jattributes.Disable(ply)
		ply:ChatPrint("rpg mode disabled")
	end
end)

aowl.AddCommand("level", function(ply, what)
	local res = jlevel.LevelAttribute(ply, what)
	if res == false then
		return false, "no such stat"
	elseif res == nil then
		return false, 	"not enough attribute points"
	end

	ply:ChatPrint(ply:GetNWInt("jlevel_attribute_points", 0) .. " attribute points left")
end)