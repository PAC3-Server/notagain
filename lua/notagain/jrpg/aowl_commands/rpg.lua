aowl.AddCommand("rpg=boolean", function(ply, cheat)
	local b = not jrpg.IsEnabled(ply)

	jrpg.SetRPG(ply, b, cheat)

	if b then
		ply:ChatPrint("JRPG: Enabled")
	else
		ply:ChatPrint("JRPG: Disabled")
	end
end)

aowl.AddCommand("level=string", function(ply, what)
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

aowl.AddCommand("status=string,number[1]", function(ply, _, what, num)
	jdmg.SetStatus(ply, what, num)
end)

aowl.AddCommand("wepstats=string,string", function(ply, _, rarity, multiplier, ...)
	local elements = {...}

	do
		local ok = false

		for _, name in ipairs(elements) do
			local _ok = false
			for k,v in pairs(wepstats.registered) do
				if v.ClassName == name then
					_ok = true
				end
			end
			if _ok then
				ok = true
			end
		end

		if elements[1] == nil then
			ok = true
		end

		if elements[1] == "all" then
			elements = {}
			ok = true
			for k,v in pairs(wepstats.registered) do
				if v.Elemental then
					table.insert(elements, v.ClassName)
				end
			end
		end

		if not ok then
			ply:ChatPrint("these modifiers are valid:")
			for k,v in pairs(wepstats.registered) do
				local name = v.ClassName
				if v.Elemental then
					name = name .. " (elemental)"
				end
				ply:ChatPrint(name)
			end
			return
		end
	end

	do
		local ok = false

		for k,v in pairs(wepstats.rarities) do
			if v.name == rarity then
				ok = true
			end
		end

		if not ok then
			ply:ChatPrint("invalid rarity " .. rarity)
			ply:ChatPrint("these rarities are valid:")
			for k,v in pairs(wepstats.rarities) do
				ply:ChatPrint(v.name)
			end
			return
		end
	end

	local wep = ply:GetActiveWeapon()

	if not elements[1] then
		for k,v in pairs(wepstats.GetTable(wep)) do
			wepstats.RemoveStatus(wep, k)
		end
		elements[1] = false
	end

	wepstats.AddToWeapon(wep, rarity, multiplier, unpack(elements))
end)
