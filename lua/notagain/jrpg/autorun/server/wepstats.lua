wepstats = _G.wepstats or {}
wepstats.registered = wepstats.registered or {}

function wepstats.AddStatus(wep, class_name, ...)
	if class_name ~= "base" and (not wep.wepstats or not wep.wepstats.base) then
		wepstats.AddStatus(wep, "base")
	end

	wep.wepstats = wep.wepstats or {}

	local status = setmetatable({}, wepstats.registered[class_name])
	status.Weapon = wep
	wep.wepstats[class_name] = status
	status:__init()
	status:OnAttach(...)

	return status
end

function wepstats.RemoveStatus(wep, class_name)
	if wep.wepstats[class_name] then
		wep.wepstats[class_name]:OnDetach()
		wep.wepstats[class_name] = nil
	end
end

function wepstats.GetStatus(wep, class_name)
	return wep.wepstats[class_name]
end

function wepstats.GetTable(wep)
	local out = {}
	for class_name, status in pairs(wep.wepstats) do
		if class_name ~= "base" then
			out[class_name] = {
				name = status.Name,
				adjective = status.AdjectiveName,
			}
		else
			out[class_name] = {
				rarity = status.rarity.name,
				mult = status.stat_mult,
			}
		end
	end
	return out
end

function wepstats.SetTable(wep, tbl)
	wep.wepstats = nil
	wepstats.AddStatus(wep, "base", tbl.base.rarity, tbl.base.mult, false)
	for class_name, data in pairs(tbl) do
		if class_name ~= "base" then
			local status = wepstats.AddStatus(wep, class_name)
			status.Name = data.name
			status.AdjectiveName = data.adjective
		end
	end
	wep:SetNWString("wepstats_name", wepstats.GetName(wep))
	wep:SetNWVector("wepstats_color", wepstats.GetStatus(wep, "base"):GetRarityInfo().color)
end

function wepstats.AddToWeapon(wep, ...)
	wep.wepstats = {} -- clear
	wepstats.AddStatus(wep, "base", ...)
	wep:SetNWString("wepstats_name", wepstats.GetName(wep))
	wep:SetNWVector("wepstats_color", wepstats.GetStatus(wep, "base"):GetRarityInfo().color)
	duplicator.StoreEntityModifier(wep, "wepstats", wepstats.GetTable(wep))

	if wep.SetDamageTypesInternal then
		local ugh = {}
		for name, dmgtype in pairs(wep.wepstats) do
			if dmgtype.Elemental then
				table.insert(ugh, name)
			end
		end
		wep:SetDamageTypesInternal(table.concat(ugh, ","))
	end
end

function wepstats.IsElemental(wep)
	if not wep.wepstats then return end
	for k,v in pairs(wep.wepstats) do
		if v.Elemental then
			return true
		end
	end
end

function wepstats.ContainsElement(wep, ...)
	if not wep.wepstats then return end
	local tbl = {...}
	for k,v in pairs(wep.wepstats) do
		if v.Elemental and table.HasValue(tbl, v.ClassName) then
			return true
		end
	end
end

duplicator.RegisterEntityModifier("wepstats", function(ply, ent, data)
	wepstats.SetTable(ent, data)
end)

function wepstats.GetName(wep)
	if not wep.wepstats then return wep:GetClass() end

	local base
	local positive = {}
	local negative = {}

	for _, status in pairs(wep.wepstats) do
		if status.ClassName == "base" then
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
		str = str .. status:GetAdjectiveName() .. " "
		if i ~= #negative then
			if i+1 == #negative then
				str = str .. "and "
			else
				str = str .. ", "
			end
		end
	end

	str = str .. "CLASSNAME "

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

function wepstats.CallStatusFunction(wep, func_name, ...)
	if not wep.wepstats then return end
	for _, status in pairs(wep.wepstats) do
		local a, b, c, d, e = status[func_name](status, ...)
		if a ~= nil then
			return a, b, c, d, e
		end
	end
end

do -- status events
	hook.Add("EntityTakeDamage", "wepstats", function(victim, info)
		if wepstats.suppress_events then return end

		local attacker = info:GetAttacker()

		if attacker:IsPlayer() and not jrpg.IsEnabled(attacker) then return end

		if not attacker.GetActiveWeapon then return end
		local wep = attacker:GetActiveWeapon()

		wepstats.suppress_events = true
		wepstats.CallStatusFunction(wep, "OnDamage", attacker, victim, info)
		wepstats.suppress_events = false

		if not (victim:IsNPC() or victim:IsPlayer()) then return end

		local wep = victim:GetActiveWeapon()
		if wep:IsValid() then
			wepstats.suppress_events = true
			wepstats.CallStatusFunction(wep, "OnReceiveDamage", victim, attacker, info)
			wepstats.suppress_events = false
		end
	end)

	wepstats.suppress_events = nil

	hook.Add("EntityFireBullets", "wepstats", function(wep, data)
		if wepstats.suppress_events then return end

		if wep.GetActiveWeapon then
			wep = wep:GetActiveWeapon()
		end

		wepstats.suppress_events = true
		wepstats.CallStatusFunction(wep, "OnFireBullet", data)
		wepstats.suppress_events = false
	end)
end

do
	local BASE = {}

	function BASE:__init()
		if self.Adjectives then
			self.AdjectiveName = table.Random(self.Adjectives)
		end
		if self.Names then
			self.Name = table.Random(self.Names)
		end
	end

	function BASE:GetStatusMultiplier()
		return self:GetStatus("base"):GetStatusMultiplier()
	end

	function BASE:GetRarityInfo()
		return self:GetStatus("base").rarity
	end

	function BASE:Initialize() end
	function BASE:OnAttach() end
	function BASE:OnDetach() end
	function BASE:OnDamage(attacker, victim, dmginfo) end
	function BASE:OnReceiveDamage(attacker, victim, dmginfo) end
	function BASE:OnFireBullet(data) end

	function BASE:GetName()
		return self.Name or self.ClassName
	end

	function BASE:GetAdjectiveName()
		return self.AdjectiveName or self:GetName()
	end

	function BASE:GetStatus(class_name)
		return wepstats.GetStatus(self.Weapon, class_name)
	end

	function BASE:Remove()
		self.Weapon.wepstats[self.ClassName] = nil
		self:OnDetach()
	end

	function wepstats.TakeDamageInfo(ent, dmginfo)
		wepstats.suppress_events = true
		ent:TakeDamageInfo(dmginfo)
		wepstats.suppress_events = false
	end

	function BASE:TakeDamageInfo(ent, dmginfo)
		wepstats.TakeDamageInfo(ent, dmginfo)
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
		if dmginfo:GetInflictor():IsValid() then
			copy:SetInflictor(dmginfo:GetInflictor())
		end
		--copy:SetMaxDamage(dmginfo:GetMaxDamage())
		copy:SetReportedPosition(dmginfo:GetReportedPosition())

		return copy
	end

	function wepstats.Register(META)
		for key, val in pairs(BASE) do
			META[key] = META[key] or val
		end

		META.__index = META

		wepstats.registered[META.ClassName] = META

		for _, wep in pairs(ents.GetAll()) do
			if wep.wepstats and wep.wepstats[META.ClassName] then
				for k, v in pairs(META) do
					if type(v) == "function" then
						wep.wepstats[META.ClassName][k] = v
					end
				end
			end
		end
	end

	do -- always added
		local META = {}
		META.ClassName = "base"

		META.Rarity = {
			{
				name = "broken",
				damage_mult = -0.30,
				status_mult = {-5, -2},
				max_positive = 0,
				max_negative = 3,
				color = Vector(30, 30, 30),
			},
			{
				name = "uninteresting",
				damage_mult = -0.15,
				status_mult = {-5, -1},
				max_positive = 0,
				max_negative = 2,
				color = Vector(60, 60, 60),
			},
			{
				name = "common",
				damage_mult = 0,
				status_mult = {0, 0},
				max_positive = 0,
				max_negative = 2,
				color = Vector(120, 120, 120),
			},
			{
				name = "uncommon",
				damage_mult = 0.05,
				status_mult = {-5, 2},
				max_positive = 1,
				max_negative = 1,
				color = Vector(159, 197, 232),
			},
			{
				name = "greater",
				damage_mult = 0.10,
				status_mult = {-5, 3},
				max_positive = 2,
				max_negative = 1,
				color = Vector(61, 133, 198),
			},
			{
				name = "rare",
				damage_mult = 0.15,
				status_mult = {-5, 6},
				max_positive = 2,
				max_negative = 1,
				color = Vector(75, 255, 75),
			},
			{
				name = "epic",
				damage_mult = 0.20,
				status_mult = {1, 9},
				max_positive = 2,
				max_negative = 0,
				color = Vector(241, 194, 50),
			},
			{
				name = "legendary",
				damage_mult = 0.30,
				status_mult = {1, 12},
				max_positive = math.huge,
				max_negative = 0,
				color = Vector(255, 0, 0),
			},
			{
				name = "godly",
				damage_mult = 0.35,
				status_mult = {1, 15},
				max_positive = math.huge,
				max_negative = 0,
				color = Vector(-1,-1,-1),
			},
		}

		for i, v in ipairs(META.Rarity) do
			v.i = (i / #META.Rarity) + 1
		end

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

		function META:OnAttach(rarity, status_multiplier, ...)
			if rarity then
				if type(rarity) == "string" then
					for k,v in pairs(self.Rarity) do
						if v.name == rarity then
							self.rarity = v
							break
						end
					end
				elseif type(rarity) == "number" then
					self.rarity = self.Rarity[math.ceil(math.Clamp(rarity, 0, 1)*#self.Rarity)]
				end
			else
				self.rarity = self.Rarity[math.ceil((math.random()^4)*#self.Rarity)]
			end

			if status_multiplier then
				if type(status_multiplier) == "string" then
					local sign, num = status_multiplier:match("^(.)(%d+)")

					if sign == "-" then
						num = -tonumber(num)
					else
						num = tonumber(num)
					end

					self.stat_mult_num = num
					self.stat_mult = 1 + num * 0.02
				elseif type(status_multiplier) == "number" then
					self.stat_mult_num = (status_multiplier - 1) * 1/0.02
					self.stat_mult = status_multiplier
				end
			else
				if math.random() < 0.25 then
					local num = math.random(unpack(self.rarity.status_mult))
					self.stat_mult_num = num
					self.stat_mult = 1 + num * 0.02
				end
			end

			local statuses = {...}

			if statuses[1] == false then return end

			if statuses[1] then
				for _, class_name in ipairs(statuses) do
					wepstats.AddStatus(self.Weapon, class_name)
				end
			else
				if self.rarity.max_positive > 0 then
					local i = 1
					for name, status in pairs(wepstats.registered) do
						if i == self.rarity.max_positive then break end
						if status.Positive and math.random() < status.Chance then
							wepstats.AddStatus(self.Weapon, name)
							i = i + 1
						end
					end
				end

				if self.rarity.max_negative > 0 then
					local i = 1
					for name, status in pairs(wepstats.registered) do
						if i == self.rarity.max_negative then break end
						if status.Negative and math.random() / self.rarity.i < status.Chance then
							wepstats.AddStatus(self.Weapon, name)
							i = i + 1
						end
					end
				end
			end
		end

		function META:OnDamage(attacker, victim, dmginfo)
			local dmg = dmginfo:GetDamage()
			dmg = dmg * (1 + self.rarity.damage_mult)
			dmginfo:SetDamage(dmg)
		end

		wepstats.rarities = META.Rarity

		wepstats.Register(META)
	end
end

do -- effects
	do -- negative
		do
			local META = {}
			META.ClassName = "clumsy"
			META.Negative = true
			META.Chance = 0.5
			META.Names = {"slippery", "clumsy", "unstable"}

			function META:OnDamage(attacker, victim, dmginfo)
				if math.random()*self:GetStatusMultiplier() < 0.1 then
					attacker:DropWeapon(self.Weapon)
					attacker:SelectWeapon("none")
				end
			end

			wepstats.Register(META)
		end

		do
			local META = {}
			META.ClassName = "dull"
			META.Negative = true
			META.Chance = 0.5
			META.Names = {"dull", "dim", "sluggish", "tedious", "faint", "pale", "faded", "weak"}


			function META:OnAttach()
				local rarity = self:GetRarityInfo().name

				if rarity == "broken" then
					self.damage = -0.2
				elseif rarity == "uninteresting" then
					self.damage = -0.1
				else
					self:Remove()
				end
			end

			function META:OnDamage(attacker, victim, dmginfo)
				local dmg = dmginfo:GetDamage()
				dmg = dmg * (1 + self.damage) / self:GetStatusMultiplier()
				dmginfo:SetDamage(dmg)
			end

			wepstats.Register(META)
		end

		do
			local META = {}
			META.ClassName = "dumb"
			META.Negative = true
			META.Chance = 0.5
			META.Names = {"dumb", "idiotic", "selfharming"}


			function META:OnDamage(attacker, victim, dmginfo)
				if math.random() < 0.1 then
					dmginfo = self:CopyDamageInfo(dmginfo)
					dmginfo:SetDamage(math.max(dmginfo:GetDamage() * 0.25 / self:GetStatusMultiplier(),1))
					self:TakeDamageInfo(attacker, dmginfo)
				end
			end

			wepstats.Register(META)
		end
	end

	do -- positive
		do
			local META = {}
			META.ClassName = "deflect"
			META.Positive = true
			META.Chance = 0.5
			META.Names = {"deflect"}
			META.Adjectives = {"shielding", "deflecting", "repelling", "ricocheting", "warding", "resist", "shielding"}


			function META:OnReceiveDamage(victim, attacker, dmginfo)
				if math.random() < 0.3 then
					dmginfo = self:CopyDamageInfo(dmginfo)
					dmginfo:SetDamage(math.max(dmginfo:GetDamage() * 0.3 / self:GetStatusMultiplier(),1))
					self:TakeDamageInfo(attacker, dmginfo)
				end
			end

			wepstats.Register(META)
		end

		do
			local META = {}
			META.ClassName = "decay"
			META.Positive = true
			META.Chance = 0.1
			META.Names = {"decay"}
			META.Adjectives = {"withering", "decaying", "fading", "deteriorating", "fading", "withering", "decay"}

			function META:OnDamage(attacker, victim, dmginfo)
				if victim:IsPlayer() then
					if not attacker.CanAlter or not attacker:CanAlter(victim) then return end

					jdmg.SetStatus(victim, "decay", true)
					local dmg = dmginfo:GetDamage()
					local id = "decay_"..tostring(attacker)..tostring(victim)
					local health = victim:Health()

					timer.Create(id, 0.5, 0, function()
						if not attacker:IsValid() or not victim:IsValid() then
							timer.Remove(id)
							return
						end

						local dmginfo = DamageInfo()
						dmginfo:SetDamage(2)
						dmginfo:SetDamageCustom(JDMG_DARK)
						dmginfo:SetDamagePosition(victim:WorldSpaceCenter())
						dmginfo:SetAttacker(attacker)

						self:TakeDamageInfo(victim, dmginfo)

						if not victim:Alive() or victim:Health() > health then
							timer.Remove(id)
							jdmg.SetStatus(victim, "decay", false)
						end

						health = victim:Health()
					end)
				end
			end

			wepstats.Register(META)
		end

		do
			local META = {}
			META.ClassName = "leech"
			META.Positive = true
			META.Chance = 0.5
			META.Names = {"life steal"}
			META.Adjectives = {"vampiric", "leeching"}

			function META:OnDamage(attacker, victim, dmginfo)
				attacker:SetHealth(math.min(attacker:Health() + math.max(dmginfo:GetDamage() * 0.25 / self:GetStatusMultiplier(), 1), attacker:GetMaxHealth()))
			end

			wepstats.Register(META)
		end

		do
			local META = {}
			META.ClassName = "fast"
			META.Positive = true
			META.Chance = 0.5

			META.Names = {"speed", "quickness", "haste"}
			META.Adjectives = {"quick", "snappy", "rapid", "swift", "accelerated", "snappy", "speedy", "fast"}

			function META:OnFireBullet(data)
				local div = 1 + (self:GetStatusMultiplier() ^ 2)
				local rate = self.Weapon:GetNextPrimaryFire() - CurTime()
				rate = rate / div
				self.Weapon:SetNextPrimaryFire(CurTime() + rate)

				local rate = self.Weapon:GetNextSecondaryFire() - CurTime()
				rate = rate / div
				self.Weapon:SetNextSecondaryFire(CurTime())
			end

			wepstats.Register(META)
		end

		function wepstats.AddBasicElemental(name, on_damage, adjectives, names, dont_copy)
			local META = {}
			META.ClassName = name
			META.Positive = true
			META.Chance = 0.5
			META.Adjectives = adjectives
			META.Names = names
			META.Elemental = true

			function META:OnAttach()
				self.Weapon:SetNWBool("wepstats_elemental", true)
				self.Weapon:SetNWBool("wepstats_elemental_" .. name, true)
			end

			function META:OnDetach()
				self.Weapon:SetNWBool("wepstats_elemental", false)
				self.Weapon:SetNWBool("wepstats_elemental_" .. name, false)
			end

			function META:OnDamage(attacker, victim, dmginfo)
				if name ~= "heal" then
					dmginfo = self:CopyDamageInfo(dmginfo)
				end

				dmginfo:SetDamageCustom(jdmg.enums[name])
				dmginfo:SetDamage(dmginfo:GetDamage() * self:GetStatusMultiplier())

				if on_damage then
					on_damage(self, attacker, victim, dmginfo)
				end

				self:TakeDamageInfo(victim, dmginfo)
			end

			wepstats.Register(META)
		end


	end
end

hook.Add("OnEntityCreated", "wepstats_bugbait", function(ent)
	if ent:GetClass() == "npc_grenade_bugbait" and ent:GetOwner():IsValid() then
		local ply = ent:GetOwner()
		local wep = ply:GetActiveWeapon()
		if wep:IsValid() and wep.wepstats then
			ent:CallOnRemove("wepstats", function()
				for k,v in pairs(ents.FindInSphere(ent:GetPos(), 100)) do
					v:TakeDamage(10, ply, ent)
				end
			end)
		end
	end
end)

if me or game.SinglePlayer() then
	local blacklist = {
		weapon_physgun = true,
	}

	hook.Add("OnEntityCreated", "", function(wep)
		timer.Simple(0.1, function()
			if not wep.wepstats and wep:IsValid() and wep:IsWeapon() and wep:GetClass():StartWith("weapon_") and not blacklist[wep:GetClass()] then
				wepstats.AddToWeapon(wep)
			end
		end)
	end)
end
