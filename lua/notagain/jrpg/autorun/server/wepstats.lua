wepstats = wepstats or {}
wepstats.effects = wepstats.effects or {}

function wepstats.AddEffect(name, wep)
	local stat = setmetatable({}, wepstats.effects[name])
	stat.Weapon = wep
	wep.wepstats_effects = wep.wepstats_effects or {}
	table.insert(wep.wepstats_effects, stat)

	stat:OnAttach()
end

function wepstats.GetName(wep)
	if not wep.wepstats_effects then return wep:GetClass() end

	local str = ""

	for i, status in ipairs(wep.wepstats_effects) do
		str = str .. " " .. status:GetName()
	end

	return str .. " " .. wep:GetClass()
end

function wepstats.CallEffect(wep, func_name, ...)
	if not wep.wepstats_effects then return end
	for i, status in ipairs(wep.wepstats_effects) do
		local a, b, c, d, e = status[func_name](status, ...)
		if a ~= nil then
			return a, b, c, d, e
		end
	end
end

do
	local BASE = {}

	function BASE:Initialize() end
	function BASE:OnAttach() end
	function BASE:OnDamage(attacker, victim, dmginfo) end

	function BASE:GetName()
		return ""
	end

	function BASE:CopyDamageInfo(dmginfo)
		local copy = DamageInfo()

		copy:SetAmmoType(dmginfo:GetAmmoType())
		copy:SetAttacker(dmginfo:GetAttacker())
		--copy:SetDamage(dmginfo:GetDamage())
		--copy:SetDamageBonus(dmginfo:GetDamageBonus())
		--copy:SetDamageCustom(dmginfo:GetDamageCustom())
		copy:SetDamageForce(dmginfo:GetDamageForce())
		copy:SetDamagePosition(dmginfo:GetDamagePosition())
		copy:SetDamageType(dmginfo:GetDamageType())
		copy:SetInflictor(dmginfo:GetInflictor())
		--copy:SetMaxDamage(dmginfo:GetMaxDamage())
		copy:SetReportedPosition(dmginfo:GetReportedPosition())

		return copy
	end

	function wepstats.Register(META)
		for key, val in pairs(BASE) do
			META[key] = META[key] or val
		end

		META.__index = META

		wepstats.effects[META.Name] = META
	end
end

--[[
hook.Add("OnEntityCreated", "wepstats", function(ent)
	if type(ent) ~= "Weapon" then return end

	for _, effect in pairs(wepstats.effects) do
		if math.random() <= effect.Chance then
			wepstats.AddEffect(effect.Name, ent)
		end
	end
end)
]]

local suppress = false
hook.Add("EntityTakeDamage", "wepstats", function(ent, info)
	if suppress then return end

	local attacker = info:GetAttacker()

	if not (attacker:IsNPC() or attacker:IsPlayer()) then return end

	local wep = info:GetInflictor()

	if wep:IsPlayer() then
		wep = wep:GetActiveWeapon()
	end
	suppress = true
	wepstats.CallEffect(wep, "OnDamage", attacker, ent, info)
	suppress = false
end)

for _, ent in pairs(ents.GetAll()) do
	ent.wepstats_effects = nil
end

do -- effects
	do
		local META = {}
		META.Name = "rare"
		META.Chance = 1 -- this is always addded

		META.RarityNames = {
			"boring",
			"common",
			"uncommon",
			"greater",
			"rare",
			"legendary",
		}

		function META:GetName()
			return self.RarityNames[math.ceil(self.rarity*#self.RarityNames)]
		end

		function META:OnAttach()
			self.rarity = math.random()
		end

		function META:OnDamage(attacker, victim, dmginfo)
			local dmg = dmginfo:GetDamage()
			dmg = dmg * 1 + (self.rarity * 100)
			dmginfo:SetDamage(dmg)
		end

		wepstats.Register(META)
	end

	do
		local META = {}
		META.Name = "clumsy"
		META.Chance = 0.1

		function META:GetName()
			return self.name
		end

		function META:OnAttach()
			self.drop_chance = math.random()^0.1
			self.name = table.Random({
				"wet",
				"slippery",
				"doused",
				"clumsy",
			})
		end

		function META:OnDamage(attacker, victim, dmginfo)
			if math.random() > self.drop_chance then
				attacker:DropWeapon(self.Weapon)
			end
		end

		wepstats.Register(META)
	end

	local function basic_elemental(name, type)
		local META = {}
		META.Name = name
		META.Chance = 0.25
		META.Elemental = true

		function META:GetName()
			return self.Name .. " (+" .. math.Round(self.amount*12) .. ")"
		end

		function META:OnAttach()
			self.amount = math.random()
		end

		function META:OnDamage(attacker, victim, dmginfo)
			dmginfo = self:CopyDamageInfo(dmginfo)
			dmginfo:SetDamageType(type)
			dmginfo:SetDamage(self.amount*20)
			victim:TakeDamageInfo(dmginfo)
		end

		wepstats.Register(META)
	end

	basic_elemental("fire", DMG_BURN)
	basic_elemental("poison", DMG_ACID)
end