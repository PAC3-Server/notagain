local jskill = {}

do
	local SKILL = {}
	SKILL.__index = SKILL

	SKILL.Target = NULL

	function SKILL:SetTarget(ent)
		jtarget.SetEntity(self.Player, ent)
		self.Target = ent
	end

	function SKILL:MoveTo(ent, min_distance)
		
	end

	function SKILL:Hook(what, cb, id)
		id = id or "jskill_" .. self.Player:UniqueID() .. "_"  .. what
		hook.Add(what, id, function(...) 
			local a,b,c,d,e,f = pcall(cb, ...) 
			if not a then 
				print(b) 
				self:UnHook(what)
			end 
			return b,c,d,e,f 
		end)
	end

	function SKILL:UnHook(what, id)
		id = id or "jskill_" .. self.Player:UniqueID() .. "_"  .. what
		hook.Remove(what, id)
	end

	function SKILL:MoveFunc(func, id)
		self:Hook("StartCommand", function(ply, mov)
			if ply == self.Player then
				local res = func(mov)
				if res == false then
					self:UnHook("StartCommand", id)
				end
				return res
			end
		end, id)
	end

	function SKILL:Wait(sec)
		if not sec then 
			coroutine.yield()
		else
			coroutine.wait(sec)
		end
	end
	
	function SKILL:Dodge(distance, ent)
		distance = distance or 100
		local res, msg = nil

		self:MoveFunc(function(mov)
			local ent = ent or jtarget.GetEntity(self.Player)

			if not ent:IsValid() then 
				res = false
				msg = "target is not valid"
				return false 
			end

			local cur_pos = self.Player:WorldSpaceCenter()
			local target_pos = ent:WorldSpaceCenter()

			local aim_ang = (target_pos - cur_pos):Angle()
			mov:SetViewAngles(aim_ang)
			mov:SetForwardMove(-1000)
			mov:SetButtons(bit.bor(mov:GetButtons(), IN_SPEED))

			if self.Player:GetVelocity():Length() > 150 then
				mov:SetButtons(bit.bor(mov:GetButtons(), IN_JUMP))
			end

			if target_pos:Distance(cur_pos) > distance then
				res = true
				return false
			end
		end)

		while res == nil do
			coroutine.yield()
		end

		return res
	end

	function SKILL:MoveTowards(distance, ent)
		distance = distance or 100
		
		local ent = ent or jtarget.GetEntity(self.Player)
		if not ent:IsValid() then
			return false, "target is not valid"
		end
		
		local cur_pos = self.Player:WorldSpaceCenter()
		local target_pos = ent:WorldSpaceCenter()
		
		if target_pos:Distance(cur_pos) < distance then
			return true
		end
		
		local timer = CurTime() + 3
		local res, msg = nil

		self:MoveFunc(function(mov)
			local ent = ent or jtarget.GetEntity(self.Player)
			if not ent:IsValid() then 
				res = false
				msg = "target is not valid"
				return false 
			end

			local cur_pos = self.Player:WorldSpaceCenter()
			local target_pos = ent:NearestPoint(cur_pos)

			mov:SetViewAngles((target_pos - cur_pos):Angle())
			mov:SetForwardMove(1000)
			mov:SetButtons(bit.bor(mov:GetButtons(), IN_SPEED))

			if target_pos:Distance(cur_pos) < distance then
				res = true
				return false
			end
		end)

		while res == nil do
			if timer < CurTime() then
				res = false
				msg = "timeout"
				break
			end
			coroutine.yield()
		end

		return res, msg
	end

	function SKILL:UseWeapon(class)
		local wep = self.Player:GetActiveWeapon()
		if wep:IsValid() and wep:GetClass() == class then
			return true
		end

		local res = nil

		if SERVER then
			if not self.Player:HasWeapon(class) then
				hook.Add("PlayerCanPickupWeapon", "temp", function(ply, wep) 
					if ply == self.Player and wep:GetClass() == class then	
						return true 
					end
				end)
				local wep = self.Player:Give(class)
				hook.Remove("PlayerCanPickupWeapon", "temp")
			end
		end

		self:MoveFunc(function(mov)
			local wep = self.Player:GetWeapon(class)
			if wep:IsValid() then
				--wep:SetDeploySpeed(0)				
				mov:SelectWeapon(wep)
				if SERVER then
					self.Player:SelectWeapon(class)
				end
				local wep = self.Player:GetActiveWeapon()
				if wep:GetClass() == class then
					res = true
					return false
				end
			end
		end)

		while res == nil do
			coroutine.yield()
		end

		return res
	end

	function SKILL:TriggerWeapon(duration, button)
		button = button or IN_ATTACK

		local res = nil
		local time = CurTime() + (duration or 0)

		
		local wep = self.Player:GetActiveWeapon()
		if wep:IsValid() then
			wep:SetNextPrimaryFire(CurTime())
			wep:SetNextSecondaryFire(CurTime())
		end
		
		local flip = true
		local fired = false
		self:MoveFunc(function(mov)
			local wep = self.Player:GetActiveWeapon()
			if wep:IsValid() then
				if wep:GetNextPrimaryFire() - CurTime() < 0 then
					fired = true
					if flip then
						mov:ClearButtons()
						mov:SetButtons(button)
						flip = false
					else
						mov:ClearButtons()
						flip = true
					end
				elseif fired and wep:GetNextPrimaryFire() - CurTime() < 0 then
					res = true
					return false
				end
			end

			if CurTime() > time then
				res = false
				return false
			end
		end)

		while res == nil do
			coroutine.yield()
		end

		return res
	end
	
	function SKILL:StartTrigger(button)
		button = button or IN_ATTACK

		self:Hook("StartCommand", function(ply, mov)
			if ply == self.Player then
				mov:SetButtons(bit.bor(mov:GetButtons(), button))
			end
		end, "hold_trigger")
	end

	function SKILL:StopTrigger(button)
		button = button or IN_ATTACK
		
		self:UnHook("StartCommand", "hold_trigger")
	end

	function SKILL:TaskInternal()
		if self.Weapon then
			self:UseWeapon(self.Weapon)
		end
		self:Task()
	end

	function SKILL:Execute()
		local co = coroutine.create(self.TaskInternal)
		local id = tostring(self)
		self:Hook("Think", function()
			if coroutine.status(co) == "dead" then
				self:UnHook("Think")
			else
				local ok, err = coroutine.resume(co, self)
				if not ok then
					print(err)
					hitmarkers.ShowDamage(jtarget.GetEntity(self.Player), 0, self.Player:EyePos())
					self:UnHook("Think")
				end
			end
		end)
	end

	jskill.base_skill = SKILL
end

jskill.registered = {}

function jskill.Register(SKILL)
	jskill.registered[SKILL.ClassName] = SKILL
end

function jskill.GetAll()
	return jskill.registered
end

if SERVER then
	util.AddNetworkString("jskill_execute")
	net.Receive("jskill_execute", function(len, ply)
		local skill = net.ReadString()
		jskill.Execute(skill, ply)
	end)
end

function jskill.Execute(name, actor)
	if not jskill.registered[name] then return end
	if CLIENT and actor and actor:IsPlayer() and actor ~= LocalPlayer() then return end

	if CLIENT then
		net.Start("jskill_execute")
			net.WriteString(name)
		net.SendToServer()
		actor = actor or LocalPlayer()
	end

	local self = setmetatable({Player = actor}, jskill.base_skill)
	for k,v in pairs(jskill.registered[name]) do
		self[k] = v
	end

	self:Execute()

	jrpg.ShowAttack(actor, self.Name)
end

function jskill.LoadSkills()
	local blacklist = {}

	local function generic_melee(id, friendly_name, weapon_class, button, distance)
		local SKILL = {}

		SKILL.ClassName = id
		SKILL.Name = friendly_name
		SKILL.Category = "melee"
		SKILL.Weapon = weapon_class

		function SKILL:Task()
			self:MoveTowards(distance)
			self:TriggerWeapon(0.25, button)
			self:Dodge(100)
		end
		
		jskill.Register(SKILL)
		blacklist[weapon_class] = true

		return SKILL
	end

	local function generic_item(id, friendly_name, weapon_class, button, distance)
		local SKILL = {}

		SKILL.ClassName = id
		SKILL.Name = friendly_name
		SKILL.Category = "items"
		SKILL.Weapon = weapon_class

		function SKILL:Task()
			self:TriggerWeapon(0.5, button)
		end
		
		jskill.Register(SKILL)
		blacklist[weapon_class] = true

		return SKILL
	end

	local function generic_range(id, friendly_name, weapon_class, button)
		local SKILL = {}

		SKILL.ClassName = id
		SKILL.Name = friendly_name
		SKILL.Category = "range"
		SKILL.Weapon = weapon_class

		function SKILL:Task()
			self:MoveTowards(1000)
			self:TriggerWeapon(0.25, button)
		end
		
		jskill.Register(SKILL)
		blacklist[weapon_class] = true

		return SKILL
	end

	generic_melee("crowbar", "crowbar", "weapon_crowbar", IN_ATTACK, 75)
	generic_melee("stunstick", "stunstick", "weapon_stunstick", IN_ATTACK, 75)
	generic_melee("gravity_gun_punt", "gravity gun punt", "weapon_physcannon", IN_ATTACK, 250)
	generic_melee("weapon_fists", "punch", "weapon_fists", IN_ATTACK, 50)
	generic_melee("weapon_slap", "slap", "weapon_slap", IN_ATTACK, 80)

	local function hl2_range(class)
		generic_range(class, "#" .. class, class, IN_ATTACK)
	end

    hl2_range("weapon_alyxgun")
    hl2_range("weapon_annabelle")
    hl2_range("weapon_ar2")
    hl2_range("weapon_bugbait")
    hl2_range("weapon_crossbow")
    hl2_range("weapon_crowbar")
    hl2_range("weapon_frag")
    hl2_range("weapon_pistol")
    hl2_range("weapon_rpg")
    hl2_range("weapon_shotgun")
    hl2_range("weapon_smg1")

	for k,v in pairs(weapons.GetList() ) do
		if v.Spawnable and not blacklist[v.ClassName] then
			local class = v.ClassName:lower()
			
			if 
				class:find("stick", nil, true) or
				class:find("sword", nil, true) or
				class:find("knife", nil, true)
			then
				generic_melee(v.ClassName, v.PrintName, v.ClassName, IN_ATTACK, 50)	
			elseif 
				class:find("potion", nil, true) or
				class:find("heal", nil, true) or
				class:find("medkit", nil, true) or
				class:find("medic", nil, true) or
				class:find("shield", nil, true) or
				class:find("hand", nil, true)
			then
				local SKILL = generic_item(v.ClassName, v.PrintName, v.ClassName, IN_ATTACK)
				SKILL.Friendly = true
			else
				local SKILL = generic_range(v.ClassName, v.PrintName, v.ClassName, IN_ATTACK)
				if class:find("magic", nil, true) then
					SKILL.Name = v.PrintName
					SKILL.Category = "magic"
				end

				if class:find("heal", nil, true) then
					SKILL.Friendly = true
				end
			end
		end
	end

	do
		local SKILL = {}

		SKILL.ClassName = "attack"
		SKILL.Name = "attack"
		SKILL.Category = "attack"
		SKILL.Weapon = "weapon_jsword_virtuouscontract"
		function SKILL:Task()
			self:MoveTowards(50)
			self:TriggerWeapon(0.25, IN_ATTACK)
			self:Dodge(100)
		end
		
		jskill.Register(SKILL)
	end

	do
		local SKILL = {}

		SKILL.ClassName = "weapon_medkit_self"
		SKILL.Name = "medkit self"
		SKILL.Category = "items"
		SKILL.Weapon = "weapon_medkit"
		SKILL.Friendly = true

		function SKILL:Task()
			self:TriggerWeapon(1, IN_ATTACK2)
		end
		
		jskill.Register(SKILL)
	end

	do
		local SKILL = {}

		SKILL.ClassName = "weapon_medkit_other"
		SKILL.Name = "medkit other"
		SKILL.Category = "items"
		SKILL.Weapon = "weapon_medkit"
		SKILL.Friendly = true

		function SKILL:Task()
			if assert(self:MoveTowards(50)) then
				self:TriggerWeapon(1, IN_ATTACK)
			end
		end
		
		jskill.Register(SKILL)
	end

	do
		local SKILL = {}

		SKILL.ClassName = "weapon_physcannon_fling"
		SKILL.Name = "gravity gun throw"
		SKILL.Weapon = "weapon_physcannon"
		function SKILL:Task()
			if assert(self:MoveTowards(200)) then
				self:TriggerWeapon(0.25, IN_ATTACK2)
				if jtarget.GetEntity(self.Player):GetOwner() ~= self.Player then
					error("failed to pickup")
				end	
				
				self.Player:SetEyeAngles((self.Player:GetAimVector() *-1):Angle())
				self:Wait(0.2)
				self:TriggerWeapon(0.1, IN_ATTACK)
			end
		end
		
		jskill.Register(SKILL)
	end

	do
		local SKILL = {}

		SKILL.ClassName = "weapon_physgun_smash"
		SKILL.Name = "physgun throw"
		SKILL.Weapon = "weapon_physgun"

		function SKILL:PitchTo(to, duration, async)
			jtarget.pause_aiming = true 
			local ang = self.Player:EyeAngles()
			local from = ang.p
			local t = CurTime() + duration
			local res, msg = nil
			self:MoveFunc(function(mov)
				local f = (t - CurTime()) / duration

				if f <= 0 then 
					res = true
					return false
				end
				ang.p = Lerp(f, to, from)
				mov:SetViewAngles(ang)
				self.Player:SetEyeAngles(ang)
			end)

			if not async then
				while res == nil do
					coroutine.yield()
				end
			end

			return res
		end

		function SKILL:WaitForPickup()
			local timer = CurTime() + 0.5
			local res = nil
			self:Hook("PhysgunPickup", function(ply, ent)
				if ply == self.Player then
					res = true
					self:UnHook("PhysgunPickup")
				end
			end)
			while res == nil do
				if timer < CurTime() then
					return false
				end
				self:Wait()
			end
			return true
		end

		function SKILL:Task()
			if assert(self:MoveTowards(400)) then
				self:StartTrigger(IN_ATTACK)
				if self:WaitForPickup() then
					self:PitchTo(-60, 0.1)
					--self:PitchTo(0, 0.15)
					self:StopTrigger(IN_ATTACK)
				else
					self:StopTrigger(IN_ATTACK)
					error("unable to pickup target")
				end
			end
		end
		
		jskill.Register(SKILL)
	end
end

timer.Simple(0.2, jskill.LoadSkills)

_G.jskill = jskill