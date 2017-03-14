local SWEP = {Primary = {}, Secondary = {}}

SWEP.ClassName = "weapon_magic"
SWEP.PrintName = "magic"
SWEP.Spawnable = true
SWEP.RenderGroup = RENDERGROUP_TRANSLUCENT
SWEP.WorldModel = "models/Gibs/HGIBS.mdl"

function SWEP:SetupDataTables()
	self:NetworkVar("String", 0, "DamageTypes")
end

if CLIENT then
	net.Receive(SWEP.ClassName, function(len, ply)
		local wep = net.ReadEntity()
		if wep:IsValid() and wep:GetClass() == SWEP.ClassName and wep.DeployMagic then
			if net.ReadBool() then
				wep:DeployMagic()
			else
				local ply = wep:GetOwner()
				local left_hand = net.ReadBool()
				wep:ThrowAnimation(left_hand)

				wep:ShootMagic()
			end
		end
	end)
end

function SWEP:DrawWorldModel()

end

function SWEP:DrawWorldModelTranslucent()

	for _, bone_name in ipairs({"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Hand"}) do
		local pos, ang

		if self.Owner:IsValid() then
			local id = self.Owner:LookupBone(bone_name)
			if id then
				pos, ang = self.Owner:GetBonePosition(id)
				pos = pos + ang:Forward()*2
			end

			self:SetPos(pos)
			self:SetAngles(ang)
		end

		local types = self:GetDamageTypes()
		if types ~= self.last_damage_types then
			self.damage_types = types:Split(",")
			if not self.damage_types[1] then
				table.insert(self.damage_types, "generic")
			end
			self.last_damage_types = types
		end

		for _, name in ipairs(self.damage_types) do
			if jdmg.types[name] and jdmg.types[name].draw_projectile then
				jdmg.types[name].draw_projectile(self, 40, true)
			end
		end

		if not self.Owner:IsValid() then
			return
		end
	end


	if CurTime()%0.5 < 0.25 then
		if not self.lol then
			self.Owner:AnimResetGestureSlot(GESTURE_SLOT_VCD)
			self.Owner:AnimRestartGesture(GESTURE_SLOT_VCD,  self.Owner:GetSequenceActivity(self.Owner:LookupSequence("jump_land")), true)
			self.Owner:AnimRestartGesture(GESTURE_SLOT_CUSTOM,  self.Owner:GetSequenceActivity(self.Owner:LookupSequence("flinch_stomach_02")), true)
			self.Owner:AnimSetGestureWeight(GESTURE_SLOT_VCD, math.Rand(0.2,0.35))
			self.Owner:AnimSetGestureWeight(GESTURE_SLOT_CUSTOM, math.Rand(0.2,0.35))
			self.lol = true
		end
	elseif self.lol then
		self.lol = false
	end

end

function SWEP:TranslateActivity(act)
	if act == ACT_MP_STAND_IDLE then
		return  ACT_HL2MP_IDLE_MELEE_ANGRY
	elseif act == ACT_MP_RUN then
		return ACT_HL2MP_RUN_FAST
	end

	return -1
end

function SWEP:Initialize()

	self:SetHoldType("melee")

	self:DrawShadow(false)

	if SERVER and not self.wepstats then
		wepstats.AddToWeapon(self, "legendary", "+5", "holy")
	end
end

if CLIENT then
	function SWEP:GetMagicColor()
		local r = 0
		local g = 0
		local b = 0
		local div = 1
		for _, name in ipairs(self.damage_types) do
			if jdmg.types[name] and jdmg.types[name].color then
				r = r + jdmg.types[name].color.r
				g = g + jdmg.types[name].color.g
				b = b + jdmg.types[name].color.b
				div = div + 1
			end
		end

		r = r / div
		g = g / div
		b = b / div

		return r,g,b
	end

	function SWEP:DeployMagic()
		local r,g,b = self:GetMagicColor()
		jeffects.CreateEffect("something", {
			ent = self.Owner,
			color = Color(r, g, b, 255),
			size = nil,
			something = 1,
			length = 2,
		})

		local snd = CreateSound(self.Owner, "music/hl2_song10.mp3")
		snd:PlayEx(0.5, 150)
		snd:FadeOut(2)

		self:EmitSound("ambient/water/distant_drip2.wav", 75, 75, 1)
	end

	function SWEP:ShootMagic()
		local r,g,b = self:GetMagicColor()
		jeffects.CreateEffect("something", {
			ent = self.Owner,
			color = Color(r, g, b, 50),
			size = nil,
			something = 0,
			length = 1,
		})

		--[[jeffects.CreateEffect("trails", {
			ent = self.Owner,
			color = Color(255, 255, 255, 255),
			length = 1,
		})]]
	end
end

function SWEP:Deploy()
	if SERVER then
		net.Start(SWEP.ClassName, true)
			net.WriteEntity(self)
			net.WriteBool(true)
		net.Broadcast()

		local ugh = {}
		for name, dmgtype in pairs(self.wepstats) do
			if dmgtype.Elemental then
				table.insert(ugh, name)
			end
		end
		self:SetDamageTypes(table.concat(ugh, ","))
	end

	self:SetHoldType("melee")

	return true
end

function SWEP:ThrowAnimation(left_hand)
	self.Owner:AddVCDSequenceToGestureSlot(left_hand and GESTURE_SLOT_GRENADE or GESTURE_SLOT_ATTACK_AND_RELOAD, self.Owner:LookupSequence("zombie_attack_0" .. (left_hand and 3 or 2)), 0.25, true)
end

function SWEP:PrimaryAttack()
	if self:GetNextPrimaryFire() > CurTime() or not self.wepstats then return end

	self:SetNextPrimaryFire(CurTime() + 0.6)

	if SERVER then
		self.left_hand_anim = not self.left_hand_anim

		net.Start(SWEP.ClassName, true)
			net.WriteEntity(self)
			net.WriteBool(false)
			net.WriteBool(self.left_hand_anim)
		net.Broadcast()

		self:ThrowAnimation(self.left_hand_anim)

		local snd = CreateSound(self, "music/hl2_song10.mp3")
		snd:PlayEx(0.5, 255)
		snd:FadeOut(2)

		--do return end

		local bone_id = self.Owner:LookupBone(self.left_hand_anim and "ValveBiped.Bip01_L_Hand" or "ValveBiped.Bip01_R_Hand")

		local ent = ents.Create("jprojectile_bullet")
		ent:SetOwner(self.Owner)
		ent:SetProjectileData(self.Owner, self.Owner:GetShootPos(), self.Owner:GetAimVector(), 1, self)

		if bone_id then
			ent:FollowBone(self.Owner, bone_id)
			ent:SetLocalPos(Vector(0,0,0))
		end

		ent:Spawn()

		timer.Simple(0.25, function()
			ent:SetParent(NULL)
			local pos

			if bone_id then
				pos = self.Owner:GetBonePosition(bone_id)
			else
				pos = self.Owner:EyePos() + self.Owner:GetVelocity()/4
			end

			ent:SetProjectileData(self.Owner, pos, self.Owner:GetAimVector(), 1, self)
		end)
	end
end

function SWEP:SecondaryAttack()

end

weapons.Register(SWEP, SWEP.ClassName)

if SERVER then
	if me then
		local name = SWEP.ClassName
		SafeRemoveEntity(me:GetWeapon(name))
		timer.Simple(0.1, function()
			me:Give(name)
			me:SelectWeapon(name)
		end)
	end
end