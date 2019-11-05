jattributes = {}
jattributes.Colors = {
	Health = Color(50,160,50),
	Mana = Color(50,90,255),
	Stamina = Color(255,160,50),
	XP = Color(100,0,255),
}

local game_script_damage = {}
jattributes.game_script_damage = game_script_damage

local function get_damage(wep)
	local dmg = nil

	if game_script_damage[wep:GetClass()] == nil then
		local str = file.Read("scripts/"..wep:GetClass()..".txt", "GAME")
		if str then
			game_script_damage[wep:GetClass()] = util.KeyValuesToTable(str).damage
		end

		if not game_script_damage[wep:GetClass()] then
			game_script_damage[wep:GetClass()] = false
		end
	end

	if game_script_damage[wep:GetClass()] then
		dmg = game_script_damage[wep:GetClass()]
	end

	if not dmg or dmg == 0 and wep.jattributes_last_damage and wep.jattributes_last_damage ~= 0 then
		dmg = wep.jattributes_last_damage
		game_script_damage[wep:GetClass()] = dmg
	end

	return dmg
end

jattributes.types = {
	health = {
		init = 100,
		on_level = function(ent, val) return val + 25 end,
		on_apply = function(ent, stats)
			ent.jattributes_base_health = ent.jattributes_base_health or ent:GetMaxHealth()
			ent:SetMaxHealth(ent.jattributes_base_health + stats.health)
		end,
		reset = function(ent, stats)
			if not ent.jattributes_base_health then return end
			ent:SetMaxHealth(ent.jattributes_base_health)
			ent:SetHealth(math.min(ent:Health(), ent:GetMaxHealth()))
			ent.jattributes_base_health = nil
		end,
	},
	stamina = {
		init = 25,
		on_level = function(ent, val) return val + 5 end,
		on_receive_damage = function(stats, dmginfo, victim)
		--	jattributes.SetStamina(victim, math.max(jattributes.GetStamina(victim) - dmginfo:GetDamage(), 0))
		end,
		--[[on_probable_attack = function(wep, attacker, what)
			local dmg = get_damage(wep)
			if dmg then
				if not wepstats.IsElemental(wep) then
					jattributes.SetStamina(attacker, math.max(jattributes.GetStamina(attacker) - dmg, 0))
					wep.jattributes_stamina_drained = os.clock() + 0.05
				end
			end
		end,]]
		on_fire_bullet = function(attacker, data, stats)
			local wep = attacker:GetActiveWeapon()
			if attacker.rpg_cheat then return end
			if wep.jattributes_stamina_drained and wep.jattributes_stamina_drained > os.clock() then return end
			local dmg = get_damage(wep) or data.Damage

			if dmg == 0 then
				return
			end

			if not wepstats.IsElemental(wep) then
				jattributes.SetStamina(attacker, math.max(jattributes.GetStamina(attacker) - dmg, 0))
				wep.jattributes_stamina_drained = os.clock() + 0.05
			end
		end,
		on_give_damage = function(stats, dmginfo, attacker)
			local wep = attacker:GetActiveWeapon()
			if attacker.rpg_cheat then return end
			if wep.jattributes_stamina_drained and wep.jattributes_stamina_drained > os.clock() then return end
			if not wepstats.IsElemental(wep) then
				jattributes.SetStamina(attacker, math.max(jattributes.GetStamina(attacker) - dmginfo:GetDamage(), 0))
				wep.jattributes_stamina_drained = nil
			end
		end,
		on_apply = function(ent, stats)
			ent.jattributes_base_stamina = ent.jattributes_base_stamina or jattributes.GetMaxStamina(ent)
			jattributes.SetMaxStamina(ent, ent.jattributes_base_stamina + stats.stamina)
			jattributes.SetStamina(ent, math.min(jattributes.GetStamina(ent), jattributes.GetMaxStamina(ent)))
		end,
		reset = function(ent, stats)
			if not ent.jattributes_base_stamina then return end
			jattributes.SetMaxStamina(ent, ent.jattributes_base_stamina)
			ent.jattributes_base_stamina = nil
		end,
	},
	mana = {
		init = 75,
		on_level = function(ent, val) return val + 10 end,
		on_fire_bullet = function(attacker, data, stats)
			local wep = attacker:GetActiveWeapon()
			local dmg = get_damage(wep) or data.Damage

			if dmg == 0 then
				return
			end

			if wepstats.IsElemental(wep) then
				return jattributes.DrainMana(attacker, wep, dmg)
			end
		end,
		on_give_damage = function(stats, dmginfo, attacker)
			local wep = attacker:GetActiveWeapon()
			wep.jattributes_last_damage = dmginfo:GetDamage()
		end,
		on_apply = function(ent, stats)
			ent.jattributes_base_mana = ent.jattributes_base_mana or jattributes.GetMaxMana(ent)
			jattributes.SetMaxMana(ent, ent.jattributes_base_mana + stats.mana)
			jattributes.SetMana(ent, math.min(jattributes.GetMana(ent), jattributes.GetMaxMana(ent)))
		end,
		reset = function(ent, stats)
			if not ent.jattributes_base_mana then return end
			jattributes.SetMaxMana(ent, ent.jattributes_base_mana)
			ent.jattributes_base_mana = nil
		end,
	},
	physical_attack = {
		init = 1,
		on_level = function(ent, val) return val + 0.2 end,
		on_give_damage = function(stats, dmginfo)
			if not jdmg.GetDamageType(dmginfo) then
				dmginfo:SetDamage(dmginfo:GetDamage() * stats.physical_attack)
			end
		end,
	},
	physical_defense = {
		init = 1,
		on_level = function(ent, val) return val + 0.2 end,
		on_receive_damage = function(stats, dmginfo)
			if not jdmg.GetDamageType(dmginfo) then
				dmginfo:SetDamage(dmginfo:GetDamage() / stats.physical_defense)
			end
		end,
	},
	magic_attack = {
		init = 1,
		default = 1,
		on_give_damage = function(stats, dmginfo)
			if jdmg.GetDamageType(dmginfo) then
				dmginfo:SetDamage(dmginfo:GetDamage() * stats.magic_attack)
			end
		end,
	},
	magic_defense = {
		init = 1,
		on_level = function(ent, val) return val + 0.2 end,
		on_receive_damage = function(stats, dmginfo)
			if jdmg.GetDamageType(dmginfo) then
				dmginfo:SetDamage(dmginfo:GetDamage() / stats.magic_defense)
			end
		end,
	},
	jump = {
		init = 1,
		on_level = function(ent, val) return val + 0.2 end,
		on_apply = function(ent, stats)
			if ent:IsPlayer() then
				ent.jattributes_base_jump_power = ent.jattributes_base_jump_power or ent:GetJumpPower()

				ent:SetJumpPower(ent.jattributes_base_jump_power * stats.jump * 1.4)
			end
		end,
		reset = function(ent, stats)
			if ent:IsPlayer() then
				if not ent.jattributes_base_jump_power then return end
				ent:SetJumpPower(ent.jattributes_base_jump_power)
				ent.jattributes_base_jump_power = nil
			end
		end,
	},
	speed = {
		init = 0,
		on_level = function(ent, val) return val + 30 end,
		on_apply = function(ent, stats)
			if ent:IsPlayer() then
				ent.jattributes_base_walk_speed = ent.jattributes_base_walk_speed or ent:GetWalkSpeed()
				ent.jattributes_base_run_speed = ent.jattributes_base_run_speed or ent:GetRunSpeed()
				ent.jattributes_base_crouched_walk_speed = ent.jattributes_base_crouched_walk_speed or ent:GetCrouchedWalkSpeed()

				ent:SetRunSpeed(ent.jattributes_base_run_speed + stats.speed)
				ent:SetWalkSpeed(ent.jattributes_base_walk_speed + stats.speed)
				ent:SetCrouchedWalkSpeed(ent.jattributes_base_crouched_walk_speed + stats.speed)
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

local PLAYER = FindMetaTable("Player")

if SERVER then

	function jattributes.SetElementalMultiplier(ent, type, num)
		ent.jattribute_elemental = ent.jattribute_elemental or {}

		ent.jattribute_elemental[type] = num
	end

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

	function jattributes.GetAttribute(ent, type)
		if ent.jattributes then
			return ent.jattributes[type]
		end

		return jattributes.types[type].init
	end

	function jattributes.LevelAttribute(ent, type)
		print(ent, type, jattributes.types[type].on_level)
		print(ent, jattributes.GetAttribute(ent, type))
		jattributes.SetAttribute(ent, type, jattributes.types[type].on_level(ent, jattributes.GetAttribute(ent, type)))
	end

	function jattributes.Disable(ent)
		for type, info in pairs(jattributes.types) do
			jattributes.SetAttribute(ent, type, nil)
		end

		jattributes.SetMana(ent, -1)
		jattributes.SetStamina(ent, -1)
	end

	function jattributes.SetTable(ent, stats)
		for type, data in pairs(jattributes.types) do
			jattributes.SetAttribute(ent, type, stats and stats[type] or data.init)
		end
	end

	function jattributes.GetTable(ent)
		return ent.jattributes or {}
	end

	hook.Add("EntityTakeDamage", "jattributes", function(victim, dmginfo)
		local attacker = dmginfo:GetAttacker()
		if not attacker:IsPlayer() and not attacker:IsNPC() then return end

		if victim.jattribute_elemental then
			local type = jdmg.GetDamageType(dmginfo)
			if type and victim.jattribute_elemental[type] then
				dmginfo:SetDamage(dmginfo:GetDamage() * victim.jattribute_elemental[type])
				local dmg = dmginfo:GetDamage()
				if dmg < 0 then
					victim:SetHealth(math.min(victim:Health() + -dmg, victim:GetMaxHealth()))
				end
			end
		end

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

	hook.Add("PlayerPostThink", "jattributes", function(ply)
		local wep = ply:GetActiveWeapon()

		if not wep:IsValid() then return end

		local attacked = false

		local diff = wep:GetNextPrimaryFire() - CurTime()
		if diff > 0 and diff < 0.01 then
			attacked = true
		end

		if attacked then
			for type, info in pairs(jattributes.types) do
				if info.on_probable_attack and ply.jattributes and ply.jattributes[type] then
					info.on_probable_attack(wep, ply)
				end
			end
		end
	end)

	jrpg.AddPlayerHook("PlayerSpawn", "jattributes", function(ply)
		timer.Simple(0, function()
			if not ply:IsValid() or not ply.jattributes then return end
			for type, info in pairs(jattributes.types) do
				if info.on_apply and ply.jattributes[type] then
					info.on_apply(ply, ply.jattributes)
				end
			end
			ply:SetHealth(ply:GetMaxHealth())

			if jattributes.HasMana(ply) then
				jattributes.SetMana(ply, jattributes.GetMaxMana(ply))
			end

			if jattributes.HasStamina(ply) then
				jattributes.SetStamina(ply, jattributes.GetMaxStamina(ply))
			end
		end)
	end)

	do
		function jattributes.SetMaxMana(ent, num)
			ent:SetNWFloat("jattributes_max_mana", num)
		end

		function jattributes.SetMana(ent, num)
			ent:SetNWFloat("jattributes_mana", num)
		end

		PLAYER.SetMaxMana = jattributes.SetMaxMana
		PLAYER.SetMana = jattributes.SetMana

		function jattributes.DrainMana(ply, wep, amt)
			local mana = math.max(jattributes.GetMana(ply) - amt, 0)
			if mana == 0 then
				ply:EmitSound("plats/crane/vertical_stop.wav", 75, 255)
				ply:EmitSound("plats/crane/vertical_stop.wav", 75, 200)
				ply:EmitSound("plats/crane/vertical_stop.wav", 75, 100)
				wep:SetNextPrimaryFire(CurTime() + 1)
				wep:SetNextSecondaryFire(CurTime() + 1)
				wep.jattributes_not_enough_mana = true
				return false
			end
			jattributes.SetMana(ply, mana)
			wep.jattributes_not_enough_mana = false
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

		PLAYER.SetMaxStamina = jattributes.SetMaxStamina
		PLAYER.SetStamina = jattributes.SetStamina

		function jattributes.CanRegenStamina(ent)
			return not ent.jattributes_regen_stamina_timer or ent.jattributes_regen_stamina_timer < CurTime()
		end

		jrpg.CreateTimer("jattributes_stamina", 0.05, 0, function()
			for _, ply in ipairs(player.GetAll()) do
				if ply.rpg_cheat then
					jattributes.SetStamina(ply, 9999)
					jattributes.SetMana(ply, 9999)
					continue
				end
				if math.random() > 0.9 and jattributes.HasMana(ply) and wepstats.ContainsElement(ply:GetActiveWeapon(), "dark") then
					jattributes.SetMana(ply, math.min(jattributes.GetMana(ply) + 1, jattributes.GetMaxMana(ply)))
				end

				if math.random() > 0.9 and wepstats.ContainsElement(ply:GetActiveWeapon(), "holy") then
					ply:SetHealth(math.min(ply:Health() + 1, ply:GetMaxHealth()))
				end

				if jattributes.HasStamina(ply) and not ply:GetNWBool("shield_stunned") then
					if ply:IsOnGround() then
						local shield = jrpg.IsWieldingShield(ply)
						if ply:GetVelocity():IsZero() then
							if jattributes.CanRegenStamina(ply) then
								jattributes.SetStamina(ply, math.min(jattributes.GetStamina(ply) + (shield and 0.5 or 3), jattributes.GetMaxStamina(ply)))
							end
						else
							if ply:GetVelocity():Length()-5 > ply:GetWalkSpeed() then
								jattributes.SetStamina(ply, math.max(jattributes.GetStamina(ply) - 1, 0))
							elseif jattributes.CanRegenStamina(ply) and not shield then
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
	return jrpg.IsEnabled(ent) and ent:GetNWFloat("jattributes_stamina", -1) ~= -1
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
	return jrpg.IsEnabled(ent) and ent:GetNWFloat("jattributes_mana", -1) ~= -1
end

PLAYER.GetMana = jattributes.GetMana
PLAYER.GetMaxMana = jattributes.GetMaxMana
PLAYER.HasMana = jattributes.HasMana
PLAYER.GetStamina = jattributes.GetStamina
PLAYER.GetMaxStamina = jattributes.GetMaxStamina
PLAYER.HasStamina = jattributes.HasStamina

if SERVER then
	for _, ent in ipairs(ents.GetAll()) do
		for type, info in pairs(jattributes.types) do
			if info.on_apply and ent.jattributes and ent.jattributes[type] then
				info.on_apply(ent, ent.jattributes)
			end
		end
	end
end
