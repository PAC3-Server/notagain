jattributes = {}

jattributes.types = {
	health = {
		on_apply = function(ent, stats)
			ent.jattributes_base_health = ent.jattributes_base_health or ent:GetMaxHealth()
			ent:SetMaxHealth(ent.jattributes_base_health * stats.health)
		end,
		reset = function(ent, stats)
			if not ent.jattributes_base_health then return end
			ent:SetMaxHealth(ent.jattributes_base_health)
			ent:SetHealth(math.min(ent:Health(), ent:GetMaxHealth()))
			ent.jattributes_base_health = nil
		end,
	},
	stamina = {
		on_receive_damage = function(stats, dmginfo, victim)
			jattributes.SetStamina(victim, math.max(jattributes.GetStamina(victim) - dmginfo:GetDamage(), 0))
		end,
		on_fire_bullet = function(attacker, data, stats)
			if data.Damage == 0 then return end
			local wep = attacker:GetActiveWeapon()
			if not wepstats.IsElemental(wep) then
				jattributes.SetStamina(attacker, math.max(jattributes.GetStamina(attacker) - data.Damage, 0))
				attacker:GetActiveWeapon().jattributes_stamina_drained = true
			end
		end,
		on_give_damage = function(stats, dmginfo, attacker)
			local wep = attacker:GetActiveWeapon()
			if not wepstats.IsElemental(wep) and not wep.jattributes_stamina_drained then
				jattributes.SetStamina(attacker, math.max(jattributes.GetStamina(attacker) - dmginfo:GetDamage(), 0))
				wep.jattributes_stamina_drained = nil
			end
		end,
		on_apply = function(ent, stats)
			ent.jattributes_base_stamina = ent.jattributes_base_stamina or jattributes.GetMaxStamina(ent)
			jattributes.SetMaxStamina(ent, ent.jattributes_base_stamina * stats.stamina)
		end,
		reset = function(ent, stats)
			if not ent.jattributes_base_stamina then return end
			jattributes.SetMaxStamina(ent, ent.jattributes_base_stamina)
			ent.jattributes_base_stamina = nil
		end,
	},
	mana = {
		on_fire_bullet = function(attacker, data, stats)
			local wep = attacker:GetActiveWeapon()
			local dmg = data.Damage

			if data.Damage == 0 then
				if wep.jattributes_last_damage and wep.jattributes_last_damage ~= 0 then
					dmg = wep.jattributes_last_damage
				end
			end

			if dmg == 0 then
				return
			end

			if wepstats.IsElemental(wep) then
				local mana = math.max(jattributes.GetMana(attacker) - dmg, 0)
				if mana == 0 then
					attacker:EmitSound("plats/crane/vertical_stop.wav", 75, 255)
					attacker:EmitSound("plats/crane/vertical_stop.wav", 75, 200)
					attacker:EmitSound("plats/crane/vertical_stop.wav", 75, 100)
					wep:SetNextPrimaryFire(CurTime() + 1)
					wep:SetNextSecondaryFire(CurTime() + 1)
					wep.jattributes_not_enough_mana = true
					return false
				end
				jattributes.SetMana(attacker, mana)
				wep.jattributes_mana_drained = true
			end
		end,
		on_give_damage = function(stats, dmginfo, attacker)
			local wep = attacker:GetActiveWeapon()
			wep.jattributes_last_damage = dmginfo:GetDamage()
		end,
		on_apply = function(ent, stats)
			ent.jattributes_base_mana = ent.jattributes_base_mana or jattributes.GetMaxMana(ent)
			jattributes.SetMaxMana(ent, ent.jattributes_base_mana * stats.mana)
		end,
		reset = function(ent, stats)
			if not ent.jattributes_base_mana then return end
			jattributes.SetMaxMana(ent, ent.jattributes_base_mana)
			ent.jattributes_base_mana = nil
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
				if not ent.jattributes_base_jump_power then return end
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
				if not ent.jattributes_base_run_speed then return end
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

if SERVER then

	function jattributes.SetAttribute(ent, type, num)
		if num then
			ent.jattributes = ent.jattributes or {}
			ent.jattributes[type] = num

			if jattributes.types[type] and jattributes.types[type].on_apply then
				jattributes.types[type].on_apply(ent, ent.jattributes)
			end
		elseif ent.jattributes and jattributes.types[type] and jattributes.types[type].reset then
			jattributes.types[type].reset(ent, ent.jattributes)
			ent.jattributes[type] = nil

			if not next(ent.jattributes) then
				ent.jattributes = nil
			end
		end
	end

	function jattributes.Disable(ent)
		for type, info in pairs(jattributes.types) do
			jattributes.SetAttribute(ent, type, nil)
		end

		jattributes.SetMana(ent, -1)
		jattributes.SetStamina (ent, -1)
	end

	function jattributes.SetTable(ent, stats)
		for type in pairs(jattributes.types) do
			jattributes.SetAttribute(ent, type, stats[type])
		end
	end

	function jattributes.GetTable(ent)
		return ent.jattributes or {}
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
				local b = info.on_fire_bullet(ply, data, ply.jattributes)
				if b ~= nil then
					return b
				end
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
			ply:SetHealth(ply:GetMaxHealth())
		end)
	end)

	do
		function jattributes.SetMaxMana(ent, num)
			ent:SetNWFloat("jattributes_max_mana", num)
		end

		function jattributes.SetMana(ent, num)
			ent:SetNWFloat("jattributes_mana", num)
		end
	end

	do -- stamina
		function jattributes.SetMaxStamina(ent, num)
			ent:SetNWFloat("jattributes_max_stamina", num)
		end

		function jattributes.SetStamina(ent, num)
			if num == 0 then
				ent.jattributes_regen_stamina_timer = CurTime() + 1
			end
			ent:SetNWFloat("jattributes_stamina", num)
		end

		function jattributes.CanRegenStamina(ent)
			return not ent.jattributes_regen_stamina_timer or ent.jattributes_regen_stamina_timer < CurTime()
		end

		timer.Create("jattributes_stamina", 0.05, 0, function()
			for _, ply in ipairs(player.GetAll()) do
				if jattributes.HasMana(ply) then
					jattributes.SetMana(ply, math.min(jattributes.GetMana(ply) + 0.1, jattributes.GetMaxMana(ply)))
				end

				if jattributes.HasStamina(ply) then
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
								jattributes.SetStamina(ply, math.min(jattributes.GetStamina(ply) + 1, jattributes.GetMaxStamina(ply)))
							end
						end
					end
				end
			end
		end)
	end
end

function  jattributes.GetStamina(ent)
	return ent:GetNWFloat("jattributes_stamina", 0)
end

function jattributes.HasStamina(ent)
	return ent:GetNWFloat("jattributes_stamina", -1) ~= -1
end

function jattributes.GetMaxStamina(ent)
	return ent:GetNWFloat("jattributes_max_stamina", 75)
end

function jattributes.GetMaxMana(ent)
	return ent:GetNWFloat("jattributes_max_mana", 50)
end

function  jattributes.GetMana(ent)
	return ent:GetNWFloat("jattributes_mana", 0)
end

function jattributes.HasMana(ent)
	return ent:GetNWFloat("jattributes_mana", -1) ~= -1
end

hook.Add("Move", "jattributes_stamina", function(ply, mov)
	if jattributes.HasStamina(ply) and jattributes.GetStamina(ply) == 0 then
		mov:SetForwardSpeed(math.Clamp(mov:GetForwardSpeed(), -100, 100))
		mov:SetSideSpeed(math.Clamp(mov:GetSideSpeed(), -100, 100))
		local wep = ply:GetActiveWeapon()
		if wep:IsValid() then
			wep:SetNextPrimaryFire(CurTime() + 0.1)
			wep:SetNextSecondaryFire(CurTime() + 0.1)
		end
	end
end)

if SERVER then
	for _, ent in ipairs(ents.GetAll()) do
		for type, info in pairs(jattributes.types) do
			if info.on_apply and ent.jattributes and ent.jattributes[type] then
				info.on_apply(ent, ent.jattributes)
			end
		end
	end
end