jlevel = jlevel or {}

function jlevel.OnEntityDamaged(victim, attacker, dmg)
	victim.jlevel_attackers = victim.jlevel_attackers or {}

	victim.jlevel_attackers[attacker] = (victim.jlevel_attackers[attacker] or 0) + math.min(dmg, victim:GetMaxHealth())
end

function jlevel.AddXP(ent, xp)
	local level = ent:GetNWInt("jlevel_level", 0)
	local next_level = 500 * level ^ 1.5
--[[
	print("xp = " .. ent:GetNWInt("jlevel_xp"))
	print("attribute points = " .. ent:GetNWInt("jlevel_attribute_points"))
	print("level = " .. level)
	print("xp for next level = " .. next_level)
	]]

	ent:SetNWInt("jlevel_next_level", next_level)

	if ent:GetNWInt("jlevel_xp", 0) + xp >= next_level then
		ent:SetNWInt("jlevel_level", ent:GetNWInt("jlevel_level", 0) + 1)
		ent:SetNWInt("jlevel_attribute_points", ent:GetNWInt("jlevel_attribute_points", 0) + 1)
		jlevel.AddXP(ent, xp - next_level)
		xp = math.max(xp - next_level, 0)
		ent:EmitSound("garrysmod/save_load"..math.random(1,4)..".wav")
	end

	ent:SetNWInt("jlevel_xp", ent:GetNWInt("jlevel_xp", 0) + xp)
end

hook.Add("EntityTakeDamage", "jlevel", function(victim, dmginfo)
	local attacker = dmginfo:GetAttacker()

	if attacker:IsPlayer() then
		local dmg = dmginfo:GetDamage()
		jlevel.OnEntityDamaged(victim, attacker, dmg)
	end
end)

hook.Add("EntityRemoved", "jlevel", function(ent)
	if ent.jlevel_attackers then
		for attacker, dmg in pairs(ent.jlevel_attackers) do
			if attacker:IsValid() and attacker:IsPlayer() and dmg ~= 0 then
				local xp = math.min(dmg, ent:GetMaxHealth())
				jlevel.AddXP(attacker, xp)
				hitmarkers.ShowXP(ent, xp)
			end
		end
	end
end)