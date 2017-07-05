local function loadout(ply)
	ply:Give("potion_health")
	ply:Give("potion_mana")
	ply:Give("potion_stamina")
	ply:Give("weapon_shield_scanner")
end

local function set_rpg(ply, b, cheat)
	ply:SetNWBool("rpg", b)

	if ply:GetNWBool("rpg") then
		jattributes.SetTable(ply, {mana = 75, stamina = 25, health = 100})
		jlevel.LoadStats(ply)
		ply:SetHealth(ply:GetMaxHealth())
		jattributes.SetMana(ply, jattributes.GetMaxMana(ply))
		jattributes.SetStamina(ply, jattributes.GetMaxStamina(ply))

		loadout(ply)
		ply:SendLua([[if battlecam and not battlecam.IsEnabled() then battlecam.Enable() end]])
		ply:ChatPrint("rpg mode enabled")
	else
		jattributes.Disable(ply)
		ply:SendLua([[if battlecam and battlecam.IsEnabled() then battlecam.Disable() end]])
		ply:ChatPrint("rpg mode disabled")
	end

	ply.rpg_cheat = cheat
end

aowl.AddCommand("rpg", function(ply, _, cheat)
	set_rpg(ply, not ply:GetNWBool("rpg"), cheat == "1")
end)

aowl.AddCommand("level", function(ply, what)
	local res = jlevel.LevelAttribute(ply, what)
	if res == false then
		ply:ChatPrint("Valid attributes to upgrade:")
		for k,v in pairs(jattributes.types) do
			ply:ChatPrint(k)
		end	
		return false,"no such stat"
	elseif res == nil then
		return false,"not enough attribute points"
	end

	ply:ChatPrint(ply:GetNWInt("jlevel_attribute_points", 0) .. " attribute points left")
end)

aowl.AddCommand("element", function(ply, _, ...)
	local args = {...}
	if #args == 1 then
		wepstats.AddToWeapon(ply:GetActiveWeapon(), nil, nil, args[1])
	end
end)

hook.Add("PlayerSpawn", "rpg_loadout", function(ply)
	if not ply:GetNWBool("rpg") then return end
	timer.Simple(0.1, function()
		loadout(ply)
	end)
end)
