wepstats = {}
wepstats.effects = {}

function wepstats.AddEffect(name, wep)
	local stat = setmetatable({}, wepstats.effects[name])
	stat.Weapon = wep
	wep.wepstats_effects = wep.wepstats_effects or {}
	table.insert(wep.wepstats_effects, stat)

	stat:OnAttach()
end

function wepstats.RemoveEffect(name, wep)
	for i = #wep.wepstats_effects, 1, -1 do
		local status = wep.wepstats_effects[i]
		if status.Name == name then
			table.remove(wep.wepstats_effects, i)
		end
	end
end

local function wep_name(wep)
	do return wep:GetClass():gsub("weapon_", "") end

	return "#"..wep:GetClass()
end

function wepstats.GetName(wep)
	if not wep.wepstats_effects then return wep:GetClass() end

	local base
	local positive = {}
	local negative = {}

	for i, status in ipairs(wep.wepstats_effects) do
		if status.Name == "base" then
			base = status
		elseif status.Positive then
			table.insert(positive, status)
		elseif status.Negative then
			table.insert(negative, status)
		end
	end

	local str = base:GetName() .. " "

	if positive[1] then
		table.insert(negative, positive[1])
		table.remove(positive, 1)
	end

	for i, status in ipairs(negative) do
		str = str .. status:GetName(true) .. " "
		if i ~= #negative then
			if i+1 == #negative then
				str = str .. "and "
			else
				str = str .. ", "
			end
		end
	end

	str = str .. wep_name(wep) .. " "

	if positive[1] then
		str = str .. "of "

		for i, status in ipairs(positive) do
			str = str .. status:GetName() .. " "
			if i ~= #positive then
				if i+1 == #positive then
					str = str .. "and "
				else
					str = str .. ", "
				end
			end
		end
	end

	str = str .. " " .. base:GetStatusMultiplierName()
	str = (" " .. str):gsub(" %l", function(s) return s:upper() end):Trim()
	str = str:gsub(" Of ", " of ")
	str = str:gsub(" And ", " and ")

	return str
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
		return self.Name
	end

	function BASE:GetStatus(stat)
		for k,v in pairs(self.Weapon.wepstats_effects) do
			if v.Name == stat then
				return v
			end
		end
	end

	function BASE:Remove()
		for i,v in pairs(self.Weapon.wepstats_effects) do
			if v == self then
				table.remove(self, i)
				break
			end
		end
	end

	function BASE:CopyDamageInfo(dmginfo)
		local copy = DamageInfo()

		copy:SetAmmoType(dmginfo:GetAmmoType())
		copy:SetAttacker(dmginfo:GetAttacker())
		copy:SetDamage(dmginfo:GetDamage())
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

	do -- always added
		local META = {}
		META.Name = "base"

		META.Rarity = {
			{
				name = "broken",
				damage_mult = -0.10,
				status_mult = {-5, -2},
				max_positive = 0,
				max_negative = math.huge,
			},
			{
				name = "boring",
				damage_mult = -0.05,
				status_mult = {-5, -1},
				max_positive = 0,
				max_negative = math.huge,
			},
			{
				name = "common",
				damage_mult = 0,
				status_mult = {0, 0},
				max_positive = 0,
				max_negative = math.huge,
			},
			{
				name = "uncommon",
				damage_mult = 0.05,
				status_mult = {-5, 2},
				max_positive = 1,
				max_negative = 1,
			},
			{
				name = "greater",
				damage_mult = 0.10,
				status_mult = {-5, 3},
				max_positive = 2,
				max_negative = 1,
			},
			{
				name = "rare",
				damage_mult = 0.15,
				status_mult = {-5, 6},
				max_positive = 2,
				max_negative = 1,
			},
			{
				name = "epic",
				damage_mult = 0.20,
				status_mult = {1, 9},
				max_positive = 2,
				max_negative = 0,
			},
			{
				name = "legendary",
				damage_mult = 0.30,
				status_mult = {1, 12},
				max_positive = math.huge,
				max_negative = 0,
			},
			{
				name = "godly",
				damage_mult = 0.35,
				status_mult = {1, 15},
				max_positive = math.huge,
				max_negative = 0,
			},
		}

		function META:GetName()
			return self.rarity.name
		end

		function META:GetStatusMultiplier()
			return self.stat_mult or 1
		end

		function META:GetStatusMultiplierName()
			if not self.stat_mult_num or self.stat_mult_num == 0 then return "" end
			if self.stat_mult_num > 0 then
				return "(+" .. self.stat_mult_num .. ")"
			else
				return "(-" .. -self.stat_mult_num .. ")"
			end
		end

		function META:OnAttach()
			local rand = math.random()^3
			local num = math.ceil(rand*#self.Rarity)
			self.rarity = self.Rarity[num]
			self.rarity.i = (num/#self.Rarity) + 1

			if math.random() < 0.1 then
				local num = math.random(unpack(self.rarity.status_mult))
				self.stat_mult_num = num
				self.stat_mult = 1 + num * 0.02
			end

			if self.rarity.max_positive > 0 then
				local i = 1
				for name, status in pairs(wepstats.effects) do
					if status.Positive and math.random() < status.Chance then
						wepstats.AddEffect(name, self.Weapon)
						i = i + 1
					end
					if i == self.rarity.max_positive then break end
				end
			end

			if self.rarity.max_negative > 0 then
				local i = 1
				for name, status in pairs(wepstats.effects) do
					if status.Negative and math.random() / self.rarity.i < status.Chance then
						wepstats.AddEffect(name, self.Weapon)
						i = i + 1
					end
					if i == self.rarity.max_negative then break end
				end
			end

			local owner = self.Weapon:GetOwner()
			if owner:IsPlayer() then
				owner:ChatPrint(wepstats.GetName(self.Weapon))
			end

			self.Weapon:SetNWString("wepstats_name", wepstats.GetName(self.Weapon))
		end

		function META:OnDamage(attacker, victim, dmginfo)
			local dmg = dmginfo:GetDamage()
			dmg = dmg * (1 + self.rarity.damage_mult)
			dmginfo:SetDamage(dmg)
		end

		wepstats.Register(META)
	end
end

hook.Add("OnEntityCreated", "wepstats", function(ent)
	if type(ent) ~= "Weapon" then return end

	wepstats.AddEffect("base", ent)
end)

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

do -- effects
	do -- negative
		do
			local META = {}
			META.Name = "clumsy"
			META.Negative = true
			META.Chance = 0.5

			function META:GetName()
				return self.name
			end

			function META:OnAttach()
				self.drop_chance = 0.1
				self.name = table.Random({
					"wet",
					"slippery",
					"doused",
					"clumsy",
				})
			end

			function META:OnDamage(attacker, victim, dmginfo)
				if math.random()*self:GetStatus("base"):GetStatusMultiplier() < self.drop_chance then
					attacker:DropWeapon(self.Weapon)
				end
			end

			wepstats.Register(META)
		end

		do
			local META = {}
			META.Name = "dull"
			META.Negative = true
			META.Chance = 0.5

			function META:OnAttach()
				local rarity = self:GetStatus("base").rarity.name

				if rarity == "broken" then
					self.damage = -0.2
				elseif rarity == "boring" then
					self.damage = -0.1
				else
					self:Remove()
				end
			end

			function META:OnDamage(attacker, victim, dmginfo)
				local dmg = dmginfo:GetDamage()
				dmg = dmg * (1 + self.damage) / self:GetStatus("base"):GetStatusMultiplier()
				dmginfo:SetDamage(dmg)
			end

			wepstats.Register(META)
		end

		do
			local META = {}
			META.Name = "dumb"
			META.Negative = true
			META.Chance = 0.5

			function META:OnDamage(attacker, victim, dmginfo)
				if math.random() < 0.1 then
					dmginfo = self:CopyDamageInfo(dmginfo)
					dmginfo:SetDamage(dmginfo:GetDamage() * 0.1 / self:GetStatus("base"):GetStatusMultiplier())
					attacker:TakeDamageInfo(dmginfo)
				end
			end

			wepstats.Register(META)
		end
	end

	do -- positive
		local function basic_elemental(name, type, on_damage, alt_names, names)
			local META = {}
			META.Name = name
			META.Positive = true
			META.Chance = 0.5

			function META:OnAttach()
				self.amount = math.random()

				self.name = table.Random(names)
				self.alt_name = table.Random(alt_names)
			end

			function META:GetName(alt)
				return alt and self.alt_name or self.name
			end

			function META:OnDamage(attacker, victim, dmginfo)
				dmginfo = self:CopyDamageInfo(dmginfo)
				dmginfo:SetDamageType(type)
				dmginfo:SetDamage(dmginfo:GetDamage() * self:GetStatus("base"):GetStatusMultiplier())
				victim:TakeDamageInfo(dmginfo)

				if on_damage then
					on_damage(self, attacker, victim, dmginfo)
				end
			end

			wepstats.Register(META)
		end

		basic_elemental("fire", DMG_BURN, nil, {"hot", "molten", "burning"}, {"fire"})
		basic_elemental("poison", DMG_ACID, function(self, attacker, victim, dmginfo)
			local dmg = dmginfo:GetDamage()
			timer.Create("poison_"..tostring(attacker)..tostring(victim), 0.5, 10, function()
				if not attacker:IsValid() or not victim:IsValid() then return end
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(dmg * self:GetStatus("base"):GetStatusMultiplier())
				dmginfo:SetDamageType(DMG_ACID)
				dmginfo:SetDamagePosition(victim:WorldSpaceCenter())
				dmginfo:SetAttacker(attacker)
				victim:TakeDamageInfo(dmginfo)
			end)
		end, {"poisonous", "venomous"}, {"poison", "venom"})
		basic_elemental("ice", DMG_DROWN, function(self, attacker, victim, dmginfo)
			if victim.GetLaggedMovementValue then
				if victim:GetLaggedMovementValue() == 0 then return end
				victim:SetLaggedMovementValue(victim:GetLaggedMovementValue() * 0.9)
				if victim:GetLaggedMovementValue() < 0.5 then
					victim:EmitSound("weapons/icicle_freeze_victim_01.wav")
					victim:SetLaggedMovementValue(0)
					if victim.Freeze then
						victim:Freeze(true)
					end
				end
				timer.Create("ice_freeze_"..tostring(attacker)..tostring(victim), 3, 1, function()
					if victim:IsValid() then
						victim:SetLaggedMovementValue(1)
						victim:EmitSound("weapons/icicle_melt_01.wav")
						if victim.Freeze then
							victim:Freeze(false)
						end
					end
				end)
			end
		end, {"cold", "frozen", "freezing", "chill"}, {"ice"})
	end
end