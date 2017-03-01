jattributes = {}

jattributes.types = {
	health = {
		on_apply = function(ent, stats)
			ent.jattributes_base_health = ent.jattributes_base_health or ent:GetMaxHealth()
			ent:SetMaxHealth(ent.jattributes_base_health * stats.health)
		end,
		reset = function(ent, stats)
			ent:SetMaxHealth(ent.jattributes_base_health)
			ent.jattributes_base_health = nil
		end,
	},
	stamina = {
		on_receive_damage = function(stats, dmginfo, victim)
			jattributes.SetStamina(victim, math.max(jattributes.GetStamina(victim) - dmginfo:GetDamage(), 0))
		end,
		on_fire_bullet = function(attacker, data, stats)
			jattributes.SetStamina(attacker, math.max(jattributes.GetStamina(attacker) - data.Damage, 0))
		end,
		on_apply = function(ent, stats)
			ent.jattributes_base_stamina = ent.jattributes_base_stamina or jattributes.GetStamina(ent)
			jattributes.SetMaxStamina(ent, ent.jattributes_base_stamina * stats.stamina)
		end,
		reset = function(ent, stats)
			jattributes.SetMaxStamina(ent, ent.jattributes_base_stamina)
			ent.jattributes_base_stamina = nil
		end,
	},
	physical_attack = {
		on_give_damage = function(stats, dmginfo)
			if not jdmg.GetDamageType(dmginfo) then
				dmginfo:SetDamage(dmginfo:GetDamage() * stats.physical_attack)
			end
		end,
	},
	physical_defense = {
		on_receive_damage = function(stats, dmginfo)
			if not jdmg.GetDamageType(dmginfo) then
				dmginfo:SetDamage(dmginfo:GetDamage() / stats.physical_defense)
			end
		end,
	},
	magic_attack = {
		on_give_damage = function(stats, dmginfo)
			if jdmg.GetDamageType(dmginfo) then
				dmginfo:SetDamage(dmginfo:GetDamage() * stats.magic_attack)
			end
		end,
	},
	magic_defense = {
		on_receive_damage = function(stats, dmginfo)
			if jdmg.GetDamageType(dmginfo) then
				dmginfo:SetDamage(dmginfo:GetDamage() / stats.magic_defense)
			end
		end,
	},
	jump = {
		on_apply = function(ent, stats)
			if ent:IsPlayer() then
				ent.jattributes_base_jump_power = ent.jattributes_base_jump_power or ent:GetJumpPower()

				ent:SetJumpPower(ent.jattributes_base_jump_power * stats.jump)
			end
		end,
		reset = function(ent, stats)
			if ent:IsPlayer() then
				ent:SetMaxHealth(ent.jattributes_base_jump_power)
				ent.jattributes_base_jump_power = nil
			end
		end,
	},
	speed = {
		on_apply = function(ent, stats)
			if ent:IsPlayer() then
				ent.jattributes_base_walk_speed = ent.jattributes_base_walk_speed or ent:GetWalkSpeed()
				ent.jattributes_base_run_speed = ent.jattributes_base_run_speed or ent:GetRunSpeed()
				ent.jattributes_base_crouched_walk_speed = ent.jattributes_base_crouched_walk_speed or ent:GetCrouchedWalkSpeed()

				ent:SetRunSpeed(ent.jattributes_base_run_speed * stats.speed)
				ent:SetWalkSpeed(ent.jattributes_base_walk_speed * stats.speed)
				ent:SetCrouchedWalkSpeed(ent.jattributes_base_crouched_walk_speed * stats.speed)
			end
		end,
		reset = function(ent, stats)
			if ent:IsPlayer() then
				ent:SetRunSpeed(ent.jattributes_base_run_speed)
				ent:SetWalkSpeed(ent.jattributes_base_walk_speed)
				ent:SetCrouchedWalkSpeed(ent.jattributes_base_crouched_walk_speed)

				ent.jattributes_base_run_speed = nil
				ent.jattributes_base_walk_speed = nil
				ent.jattributes_base_crouched_walk_speed = nil
			end
		end,
	},
}

function jattributes.SetAttribute(ent, type, num)
	ent.jattributes = ent.jattributes or {}
	ent.jattributes[type] = num

	if jattributes.types[type] and jattributes.types[type].on_apply then
		jattributes.types[type].on_apply(ent, ent.jattributes)
	end
end

function jattributes.Disable(ent)
	if not ent.jattributes then return end

	for name, info in pairs(jattributes.types) do
		if info.reset and ent.jattributes[name] then
			info.reset(ent, ent.jattributes)
		end
	end

	ent.jattributes = nil
end

hook.Add("EntityTakeDamage", "jattributes", function(victim, dmginfo)
	local attacker = dmginfo:GetAttacker()
	if not attacker:IsPlayer() and not attacker:IsNPC() then return end

	for type, info in pairs(jattributes.types) do
		if info.on_give_damage and attacker.jattributes and attacker.jattributes[type] then
			info.on_give_damage(attacker.jattributes, dmginfo, attacker)
		end
		if info.on_receive_damage and victim.jattributes and victim.jattributes[type] then
			info.on_receive_damage(victim.jattributes, dmginfo, victim)
		end
	end
end)
hook.Add("EntityFireBullets", "jattributes", function(ply, data)
	for type, info in pairs(jattributes.types) do
		if info.on_fire_bullet and ply.jattributes and ply.jattributes[type] then
			info.on_fire_bullet(ply, data, ply.jattributes)
		end
	end
end)

hook.Add("PlayerSpawn", "jattributes", function(ply)
	timer.Simple(0, function()
		if not ply:IsValid() or not ply.jattributes then return end
		for type, info in pairs(jattributes.types) do
			if info.on_apply and ply.jattributes[type] then
				info.on_apply(ply, ply.jattributes)
			end
		end
	end)
end)

do
	function jattributes.SetMaxMana(ent, num)
		ent.jattributes_max_mana = num
		ent:SetNWFloat("jattributes_max_mana", num)
	end

	function jattributes.GetMaxMana(ent)
		return ent.jattributes_max_mana or 100
	end

	function jattributes.SetMana(ent, num)
		ent.jattributes_mana = num
		ent:SetNWFloat("jattributes_mana", num)
	end

	function  jattributes.GetMana(ent)
		return ent.jattributes_mana or 0
	end
end

do -- stamina
	function jattributes.SetMaxStamina(ent, num)
		ent.jattributes_max_stamina = num
		ent:SetNWFloat("jattributes_max_stamina", num)
	end

	function jattributes.GetMaxStamina(ent)
		return ent.jattributes_max_stamina or 100
	end

	function jattributes.SetStamina(ent, num)
		ent.jattributes_stamina = num
		if num == 0 then
			ent.jattributes_regen_stamina_timer = CurTime() + 1
		end
		ent:SetNWFloat("jattributes_stamina", num)
	end

	function jattributes.CanRegenStamina(ent)
		return not ent.jattributes_regen_stamina_timer or ent.jattributes_regen_stamina_timer < CurTime()
	end

	function  jattributes.GetStamina(ent)
		return ent.jattributes_stamina or 0
	end

	timer.Create("jattributes_stamina", 0.05, 0, function()
		for _, ply in ipairs(player.GetAll()) do
			if ply.jattributes and ply.jattributes.stamina then
				if ply:IsOnGround() then
					if
						not ply:KeyDown(IN_FORWARD) and
						not ply:KeyDown(IN_BACK) and
						not ply:KeyDown(IN_MOVELEFT) and
						not ply:KeyDown(IN_MOVERIGHT)
					then
						if jattributes.CanRegenStamina(ply) then
							jattributes.SetStamina(ply, math.min(jattributes.GetStamina(ply) + 3, jattributes.GetMaxStamina(ply)))
						end
					else
						if ply:KeyDown(IN_SPEED) then
							jattributes.SetStamina(ply, math.max(jattributes.GetStamina(ply) - 1, 0))
						elseif jattributes.CanRegenStamina(ply) then
							jattributes.SetStamina(ply, math.min(jattributes.GetStamina(ply) + 3, jattributes.GetMaxStamina(ply)))
						end
					end
				end
			end
		end
	end)

	hook.Add("Move", "jattributes_stamina", function(ply, mov)
		if ply.jattributes and ply.jattributes.stamina and jattributes.GetStamina(ply) == 0 then
			mov:SetForwardSpeed(math.Clamp(mov:GetForwardSpeed(), -100, 100))
			mov:SetSideSpeed(math.Clamp(mov:GetSideSpeed(), -100, 100))
			local wep = ply:GetActiveWeapon()
			if wep:IsValid() then
				wep:SetNextPrimaryFire(CurTime() + 0.1)
				wep:SetNextSecondaryFire(CurTime() + 0.1)
			end
		end
	end)
end

for _, ent in ipairs(ents.GetAll()) do
	for type, info in pairs(jattributes.types) do
		if info.on_apply and ent.jattributes and ent.jattributes[type] then
			info.on_apply(ent, ent.jattributes)
		end
	end
end