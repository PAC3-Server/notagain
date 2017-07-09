local function loadout(ply)
	ply:Give("weapon_shield_scanner")
	ply:Give("magic")
end

local function set_rpg(ply, b, cheat)
	ply:SetNWBool("rpg", b)
	if b then
		hook.Run("OnRPGEnabled",ply,cheat)
	else
		hook.Run("OnRPGDisabled",ply)
	end
	if ply:GetNWBool("rpg") then
		jattributes.SetTable(ply, {mana = 75, stamina = 25, health = 100})
		jlevel.LoadStats(ply)
		ply:SetHealth(ply:GetMaxHealth())
		jattributes.SetMana(ply, jattributes.GetMaxMana(ply))
		jattributes.SetStamina(ply, jattributes.GetMaxStamina(ply))

		loadout(ply)
		ply:SendLua([[if battlecam and not battlecam.IsEnabled() then battlecam.Enable() end]])
		ply:ChatPrint("RPG: Enabled")
	else
		jattributes.Disable(ply)
		ply:SendLua([[if battlecam and battlecam.IsEnabled() then battlecam.Disable() end]])
		ply:ChatPrint("RPG: Disabled")
	end

	ply.rpg_cheat = cheat
end

aowl.AddCommand("rpg", function(ply, _, cheat)
	set_rpg(ply, not ply:GetNWBool("rpg",false), cheat == "1")
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
	if #args < 1 then
		ply:ChatPrint("Valid types of magic:")
		for k,v in pairs(jdmg.types) do
			ply:ChatPrint(k)
		end
	end
	if #args == 1 and jdmg.types[args[1]] then
		wepstats.AddToWeapon(ply:GetActiveWeapon(),_,_,args[1])
		hook.Run("OnRPGElementChange",ply,args[1])
	else
		local doit = true
		for k,v in pairs(args) do
			if not jdmg.types[v] then 
				doit = false
				break
			end
		end
		if doit then
			wepstats.AddToWeapon(ply:GetActiveWeapon(),_,_,unpack(args))
			hook.Run("OnRPGElementChange",ply,unpack(args))
		end
	end
end)

hook.Add("PlayerSpawn", "rpg_loadout", function(ply)
	if not ply:GetNWBool("rpg") then return end
	timer.Simple(0.1, function()
		loadout(ply)
	end)
end)
