local SWEP = {Primary = {}, Secondary = {}}
SWEP.ClassName = "weapon_jsword_base"

SWEP.PrintName = "jrpg base sword"
SWEP.Spawnable = false
SWEP.ModelScale = 1
SWEP.OverallSpeed = 1
SWEP.SwordRange = 30
SWEP.Damage = 30
SWEP.Force = 1

SWEP.ViewModel = SWEP.WorldModel
SWEP.UseHands = true
SWEP.is_jsword = true
--ryoku pure vanguard judge phalanx
SWEP.MoveSet = "phalanx"

hook.Add("Move", SWEP.ClassName, function(ply, mv)
	local self = ply:GetActiveWeapon()
	if not self.is_jsword then return end
	if ply:GetNW2Float("roll_time", 0) > CurTime() or ply.roll_time then return end


	if ply.sword_anim then
		local f = (ply.sword_anim_time - CurTime()) / (ply.sword_anim.duration*self.OverallSpeed)
		f = -f + 1
		if f > 0 and f < 0.7 then
			if f >= ply.sword_anim.damage_frac then
				mv:SetForwardSpeed(50)
			else
				mv:SetForwardSpeed(0)
			end
			mv:SetSideSpeed(0)
		end
	end
end)

hook.Add("CalcMainActivity", SWEP.ClassName, function(ply)
	local self = ply:GetActiveWeapon()
	if not self.is_jsword then return end
	if ply:GetNW2Float("roll_time", 0) > CurTime() or ply.roll_time then return end

	if ply.sword_anim then
--		ply:SetSequence(ply:LookupSequence(ply.sword_anim))
	end
end)

local function manip_pos(ply, id, pos)
	if pac and pac.ManipulateBonePosition then
		pac.ManipulateBonePosition(ply, id, pos)
	else
		ply:ManipulateBonePosition(id, pos)
	end
end

hook.Add("UpdateAnimation", SWEP.ClassName, function(ply)
	if ply.sword_bone_hack then
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_Head1"), Vector(0,0,0))
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_Neck1"), Vector(0,0,0))
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_R_Clavicle"), Vector(0,0,0))
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_L_Clavicle"), Vector(0,0,0))
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_L_UpperArm"), Vector(0,0,0))
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_R_UpperArm"), Vector(0,0,0))
		ply.sword_bone_hack = nil
	end

	local self = ply:GetActiveWeapon()
	if not self.is_jsword then return end
	if jrpg.IsWieldingShield(ply) then return end
	if ply:GetNW2Float("roll_time", 0) > CurTime() or ply.roll_time then return end

	local vel = ply:GetVelocity()
	local seq
	if vel:IsZero() then
		seq = ply:LookupSequence(self.MoveSet .. "_idle_lower")

		if seq < 0 then
			seq = ply:LookupSequence(self.MoveSet .. "_b_idle")
		end
		ply:SetPlaybackRate(1)
	elseif false then
		seq = ply:LookupSequence(self.MoveSet.. "_run_lower")
		if seq == -1 then
			seq = ply:LookupSequence(self.MoveSet .. "_run")
			if seq == -1 then
				seq = ply:LookupSequence("run_all_02")
			end
		end
		ply:SetPlaybackRate(vel:Length()/200)
	end

	if seq then
		ply:SetSequence(seq)
	end


	if ply.sword_anim then
		local f = (ply.sword_anim_time - CurTime()) / (ply.sword_anim.duration*self.OverallSpeed)
		f = math.Clamp(-f+1, 0, 1)

		if ply.sword_anim then
			ply:SetSequence(ply:LookupSequence(ply.sword_anim.seq))
			local min = ply.sword_anim.min or 0
			local max = ply.sword_anim.max or 1

			ply:SetCycle(Lerp(f, min, max))
			ply:SetPlaybackRate(0)

			if f >= ply.sword_anim.damage_frac then
				if not ply.sword_damaged then
					local pos = ply:WorldSpaceCenter() + ply:GetForward() * self.SwordRange
					local ang = ply:LocalToWorldAngles(ply.sword_anim.damage_ang)
					local size = 40
					debugoverlay.Sphere(pos, size, 0.5)
					debugoverlay.Axis(pos, ang, 20, 1, true)
					for k,v in pairs(ents.FindInSphere(pos, size)) do
						if v ~= ply and v:GetOwner() ~= ply then
							if SERVER then
								local d = DamageInfo()
								d:SetAttacker(ply)
								d:SetInflictor(ply)
								d:SetDamage(self.Damage)
								d:SetDamageType(DMG_SLASH)
								d:SetDamagePosition(ply:EyePos())
								d:SetDamageForce(ang:Forward() * 10000 * self.Force)
								v:TakeDamageInfo(d)
							else
								v:EmitSound("npc/fast_zombie/claw_strike"..math.random(1,3)..".wav", 100, math.Rand(140,160))
								debugoverlay.Cross(v:GetPos(), 10)
							end
						end
					end

					if CLIENT then
						ply:EmitSound("npc/fast_zombie/claw_miss1.wav", 100, math.Rand(140,160))
					end

					ply.sword_damaged = true
				end
			end

			if f == 1 then
				ply.sword_anim = nil
			end
		end
	end

	if ply:GetSequenceName(ply:GetSequence()):find(self.MoveSet) and jrpg.GetGender(ply) == "female" then
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_Head1"), Vector(-2,1,0))
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_Neck1"), Vector(-0.5,0,0))
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_R_Clavicle"), Vector(0,0,1))
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_L_Clavicle"), Vector(0,0,-1))
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_L_UpperArm"), Vector(-2,-1,0))
		manip_pos(ply, ply:LookupBone("ValveBiped.Bip01_R_UpperArm"), Vector(-2,-1,0))
		ply.sword_bone_hack = true
	end

	--return true
end)

function SWEP:Animation(type)
	local ply = self.Owner
	ply.sword_anim = self.MoveSet2.light[math.Round(util.SharedRandom(self.ClassName, 1, #self.MoveSet2.light))]
	ply.sword_anim_time = CurTime() + (ply.sword_anim.duration*self.OverallSpeed)
	ply.sword_damaged = nil
end

if CLIENT then
	net.Receive(SWEP.ClassName, function()
		local wep = net.ReadEntity()
		if not wep:IsValid() then return end
		local light = net.ReadBool()
		local delay = net.ReadFloat()
		wep:Attack(light and "light" or "heavy")
	end)

	local suppress_player_draw = false

	hook.Add("PrePlayerDraw", SWEP.ClassName, function(ply)
		if suppress_player_draw then
			return true
		end
	end)

	local emitter = ParticleEmitter(vector_origin)
	local mute_sounds = false
	local volume = 1
	hook.Add("EntityEmitSound", SWEP.ClassName, function(data)
		if mute_sounds then
			data.Pitch = math.Rand(105,200)
			data.Volume = math.Clamp(math.Rand(0.25, 1) * volume/2^2, 0, 1)
			return true
		end
	end)
	function SWEP:DrawWorldModel()
		local pos, ang = Vector(), Angle()
		if self.Owner:IsValid() then
			local id = self.Owner:LookupBone("ValveBiped.Bip01_R_Hand")
			if id then
				pos, ang = self.Owner:GetBonePosition(id)
				pos, ang = self:SetupPosition(pos, ang)

				self:SetPos(pos)
				self:SetAngles(ang)
				self:SetupBones()
			end
		end

		self:DrawModel()

		if self:GetNWBool("wepstats_elemental") then
			for k, v in pairs(jdmg.types) do
				if self:GetNWBool("wepstats_elemental_" .. k) then
					local len = self.last_vel_length or 0
					len = 1
					v.draw(self, len, len, RealTime())
				end
			end
			render.SetColorModulation(1,1,1)
			render.ModelMaterialOverride()
			render.SetBlend(1)
		end

		if self.Owner:IsValid() and self.Owner.sword_anim then
			if self:GetNWBool("wepstats_elemental") then
				for k, v in pairs(jdmg.types) do
					if self:GetNWBool("wepstats_elemental_" .. k) then
						local len = self.last_vel_length or 0
						len = 1
						v.draw(self, len, len, RealTime())
						if v.think then v.think(self, len, len, RealTime()) end
						v.draw_projectile(self, len, false)
					end
				end
				render.SetColorModulation(1,1,1)
				render.ModelMaterialOverride()
				render.SetBlend(1)
			end

			suppress_player_draw = true
			self.pos_history = self.pos_history or {}

			if #self.pos_history > 10 then
				table.remove(self.pos_history, 1)
			end

			self:RemoveEffects(EF_BONEMERGE)

			table.insert(self.pos_history, {pos = pos, ang = ang})

			local vel = Vector()
			for i, data in ipairs(self.pos_history) do
				if self.pos_history[i+1] then
					vel = vel + (data.pos - self.pos_history[i+1].pos)
				end
			end
			vel = vel / #self.pos_history
			local l = vel:Length()

			self.last_vel_length = l

			local hit = false
			local last_pos = Vector()

			for i, data in ipairs(self.pos_history) do
				render.SetColorModulation(1,1,1)
				render.SetBlend(((i/10) * 0.1)^1.25)

				if self.pos_history[i+1] then

					local cur_pos = data.pos
					local nxt_pos = self.pos_history[i+1].pos

					local cur_ang = data.ang
					local nxt_ang = self.pos_history[i+1].ang

					for i2 = 1,20 do
						local pos = LerpVector(i2/20, cur_pos, nxt_pos)
						local ang = LerpAngle(i2/20, cur_ang, nxt_ang)

						self:SetPos(pos)
						self:SetAngles(ang)
						self:SetupBones()
						self:DrawModel()
					end
				end
			end

			render.SetBlend(1)
			render.SetColorModulation(1,1,1)
			suppress_player_draw = false
		end
	end

	function SWEP:OnRemove()

	end
end

function SWEP:Initialize()
	self:SetHoldType("melee2")
	self:SetModelScale(self.ModelScale)
	--self:SetModelScale(1.25)
end

hook.Add("ShouldCollide", SWEP.ClassName, function(a, b)
	if a.is_sword_phys and b:IsWorld() then return false end
	if a.is_sword_phys and b.is_shield_ent and a:GetOwner() == b:GetOwner() then return  false end
end)
--[[
function SWEP:Deploy()
	if SERVER then
		local ent = ents.Create("prop_physics")
		ent:SetModel(self.WorldModel)
		ent:SetOwner(self:GetOwner())
		ent:SetMaterial("models/wireframe")
		--ent:SetNoDraw(true)
		ent:SetPos(self:GetOwner():GetPos())
		ent:Spawn()
		ent:GetPhysicsObject():SetMass(1)
		ent:GetPhysicsObject():EnableGravity(false)
		ent:SetCustomCollisionCheck(true)
		ent.is_sword_phys = true
		self:SetNW2Entity("physics", ent)
		self.phys = ent
	end
	return true
end

function SWEP:Think()
	if SERVER then
		local id = self.Owner:LookupBone("ValveBiped.Bip01_R_Hand")

		if id then
			local pos, ang = self.Owner:GetBonePosition(id)
			pos, ang = self:SetupPosition(pos, ang)

			if self.phys:IsValid() then

				local phys = self.phys:GetPhysicsObject()

				phys:SetPos(pos)
				phys:SetAngles(ang)
			end
		end
	end
end

function SWEP:Holster()
	if SERVER then
		SafeRemoveEntity(self.phys)
	end
	return true
end

if SERVER then
	function SWEP:OnDrop()
		SafeRemoveEntity(self.phys)
	end
end
function SWEP:OnRemove()
	if SERVER then
		SafeRemoveEntity(self.phys)
	end
end
]]

if SERVER then
	util.AddNetworkString(SWEP.ClassName)

--[[
	-- hahahha
	util.AddNetworkString("sword_damage")
	net.Receive("sword_damage", function(_, ply)
		local self = ply:GetActiveWeapon()
		if not self.is_jsword then return end

		local pos = net.ReadVector()
		local dmg = net.ReadUInt(8)
		local ent = net.ReadEntity()

		if ent:IsValid() and ent:GetPos():Distance(ply:GetPos()) < 150 then
			local d = DamageInfo()
			d:SetAttacker(ply)
			d:SetInflictor(ply )
			d:SetDamage(dmg)
			d:SetDamageType(DMG_SLASH)
			d:SetDamagePosition(pos)
			ent:TakeDamageInfo(d)
		end
	end)
]]
end

function SWEP:Attack(type)
	-- self.Owner:SetVelocity(self.Owner:GetAimVector()*500)

	if SERVER then
		self:Animation(type)
		net.Start(SWEP.ClassName, true)
			net.WriteEntity(self)
			net.WriteBool(type == "light")
		net.SendOmit(self.Owner)
	end

	if CLIENT then
		self:Animation(type)
	end
end

function SWEP:PrimaryAttack()
	self:Attack(3, 0.3)
	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)
end


function SWEP:SecondaryAttack()
	self:Attack(1, 0.25)
	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)
end

weapons.Register(SWEP, SWEP.ClassName)

do
	local SWEP = {Primary = {}, Secondary = {}}
	SWEP.ClassName = "weapon_jsword_virtuouscontract"
	SWEP.Base = "weapon_jsword_base"

	SWEP.PrintName = "virtuous contract"
	SWEP.Spawnable = true
	SWEP.Category = "JRPG"

	SWEP.MoveSet2 = {
		light = {
			{
				seq = "phalanx_b_s2_t2",
				duration = 0.5,
				min = 0,
				max = 0.7,

				damage_frac = 0.3,
				damage_ang = Angle(45,-90,0),
			},

			{
				seq = "phalanx_b_s2_t3",
				duration = 0.5,
				min = 0,
				max = 0.8,

				damage_frac = 0.3,
				damage_ang = Angle(45,-90,0),
			},
			{
				seq = "phalanx_b_s1_t2",
				duration = 1,
				min = 0,
				max = 0.65,

				damage_frac = 0.3,
				damage_ang = Angle(45,90,0),
			},
			{
				seq = "phalanx_b_s1_t3",
				duration = 1,
				min = 0,
				max = 0.8,

				damage_frac = 0.4,
				damage_ang = Angle(60,90,0),
			},
		},
	}

	SWEP.WorldModel = "models/kuma96/2b/virtuouscontract/virtuouscontract.mdl"
	SWEP.SetupPosition = function(self, pos, ang)
		pos = pos + ang:Forward()*2
		pos = pos + ang:Right()*1
		pos = pos + ang:Up()*-50

		ang:RotateAroundAxis(ang:Up(), 90)
		return pos, ang
	end
	SWEP.TracePosition = function(self, pos, ang)
		return pos + ang:Up() * 50, pos
	end

	weapons.Register(SWEP, SWEP.ClassName)
end


if true then
	local SWEP = {Primary = {}, Secondary = {}}
	SWEP.ClassName = "weapon_jsword_overture"
	SWEP.Base = "weapon_jsword_base"

	SWEP.PrintName = "overture"
	SWEP.Spawnable = true
	SWEP.Category = "JRPG"
	SWEP.OverallSpeed = 2

	SWEP.MoveSet2 = {
		light = {
			{
				seq = "ryoku_b_s1_t2",
				duration = 0.25,
				min = 0.6,
				max = 0.9,

				damage_frac = 0.15,
				damage_ang = Angle(0,-0,0),
			},
			--[[{
				seq = "ryoku_b_s1_t3",
				duration = 0.6,
				min = 0.4,
				max = 0.86,

				damage_frac = 0.3,
				damage_ang = Angle(45,-90,0),
			},
			{
				seq = "phalanx_b_s2_t2",
				duration = 0.5,
				min = 0,
				max = 0.7,

				damage_frac = 0.3,
				damage_ang = Angle(45,-90,0),
			},

			{
				seq = "phalanx_b_s2_t3",
				duration = 0.5,
				min = 0,
				max = 0.8,

				damage_frac = 0.3,
				damage_ang = Angle(45,-90,0),
			},
			{
				seq = "phalanx_b_s1_t2",
				duration = 1,
				min = 0,
				max = 0.65,

				damage_frac = 0.3,
				damage_ang = Angle(45,90,0),
			},
			{
				seq = "phalanx_b_s1_t3",
				duration = 1,
				min = 0,
				max = 0.8,

				damage_frac = 0.4,
				damage_ang = Angle(60,90,0),
			},]]
		},
	}

	SWEP.MoveSet = "ryoku"
	SWEP.WorldModel = "models/kuma96/lightningetro/overture/overture.mdl"
	SWEP.SetupPosition = function(self, pos, ang)
		pos = pos + ang:Forward()*-12
		pos = pos + ang:Right()*-0
		pos = pos + ang:Up()*-13

		ang:RotateAroundAxis(ang:Right(), -90)
		return pos, ang
	end
	SWEP.TracePosition = function(self, pos, ang)
		return pos, pos + ang:Up() * 50
	end

	weapons.Register(SWEP, SWEP.ClassName)
end

do
	local SWEP = {Primary = {}, Secondary = {}}
	SWEP.ClassName = "weapon_jsword_crowbar"
	SWEP.Base = "weapon_jsword_base"

	--ryoku pure vanguard judge phalanx
	SWEP.MoveSet = "phalanx"

	SWEP.PrintName = "crowbar"
	SWEP.Spawnable = true
	SWEP.Category = "JRPG"

	SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
	SWEP.ModelScale = 1.5
	SWEP.SetupPosition = function(self, pos, ang)
		ang:RotateAroundAxis(ang:Right(), 90)
		ang:RotateAroundAxis(ang:Up(), 180)
		pos = pos + ang:Forward()*20
		pos = pos + ang:Up()*-3.2
		pos = pos + ang:Right()*-1.5

		return pos, ang
	end
	SWEP.TracePosition = function(self, pos, ang)
		return pos + ang:Forward() * -20, pos + ang:Forward() * 20
	end


	weapons.Register(SWEP, SWEP.ClassName)
end

do
	local SWEP = {Primary = {}, Secondary = {}}
	SWEP.ClassName = "weapon_jsword_beastlord"
	SWEP.Base = "weapon_jsword_base"

	SWEP.OverallSpeed = 1.5
	SWEP.SwordRange = 60
	SWEP.Damage = 60
	SWEP.Force = 5

	SWEP.MoveSet2 = {
		light = {
			{
				seq = "vanguard_b_s1_t3",
				duration = 1,
				min = 0,
				max = 1,

				damage_frac = 0.7,
				damage_ang = Angle(45,-90,0),
			},
			{
				seq = "vanguard_b_s2_t3",
				duration = 1,
				min = 0.25,
				max = 1,

				damage_frac = 0.3,
				damage_ang = Angle(-45,-90,0),
			},
			{
				seq = "vanguard_b_s3_t1",
				duration = 1,
				min = 0.1,
				max = 1,

				damage_frac = 0.4,
				damage_ang = Angle(90,-90,0),
			},
			{
				seq = "vanguard_b_s3_t1",
				duration = 1,
				min = 0,
				max = 0.6,

				damage_frac = 0.7,
				damage_ang = Angle(90,-90,0),
			},
			{
				seq = "vanguard_b_s3_t3",
				duration = 1,
				min = 0,
				max = 1,

				damage_frac = 0.4,
				damage_ang = Angle(90,-90,0),
			},
			{
				seq = "vanguard_b_s3_t2",
				duration = 1,
				min = 0.1,
				max = 1,

				damage_frac = 0.4,
				damage_ang = Angle(90,-90,0),
			},
		},
	}

	SWEP.PrintName = "beastlord"
	SWEP.Spawnable = true
	SWEP.Category = "JRPG"

	SWEP.MoveSet = "vanguard"
	SWEP.WorldModel = "models/kuma96/2b/beastlord/beastlord.mdl"
	SWEP.SetupPosition = function(self, pos, ang)
		pos = pos + ang:Forward()*-1
		pos = pos + ang:Right()*1
		pos = pos + ang:Up()*-70

		ang:RotateAroundAxis(ang:Up(), 90)
		return pos, ang
	end
	SWEP.TracePosition = function(self, pos, ang)
		return pos, pos + ang:Up() * 50
	end

	weapons.Register(SWEP, SWEP.ClassName)
end