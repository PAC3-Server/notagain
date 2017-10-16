local SWEP = {Primary = {}, Secondary = {}}
SWEP.ClassName = "weapon_jsword_base"

SWEP.PrintName = "jrpg base sword"
SWEP.Spawnable = false
SWEP.ModelScale = 1

SWEP.ViewModel = SWEP.WorldModel
SWEP.UseHands = true
SWEP.is_jsword = true
--ryoku pure vanguard judge phalanx
SWEP.MoveSet = "phalanx"
SWEP.Speed = 0.05

hook.Add("Move", SWEP.ClassName, function(ply, mv)
	local self = ply:GetActiveWeapon()
	if not self.is_jsword then return end
	if ply:GetNW2Float("roll_time", 0) > CurTime() or ply.roll_time then return end

	if ply.sword_anim and ply.sword_cycle and ply.sword_cycle < 0.9 and ply.sword_cycle > 0.1 then
		mv:SetForwardSpeed(0)
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
		ply:SetSequence(ply:LookupSequence(ply.sword_anim))
		ply:SetCycle(ply.sword_cycle)

		--ply:SetPlaybackRate(1)
		ply.sword_cycle = ply.sword_cycle + FrameTime()
		if ply.sword_cycle > 1 then
			ply.sword_anim = nil
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

function SWEP:Animation(id)
	local ply = self.Owner

	ply.sword_anim = self.MoveSet .. "_b_s" .. id .. "_t" .. math.Round(util.SharedRandom(self.ClassName, 1, 3))
	ply.sword_cycle = 0
end

if CLIENT then
	net.Receive(SWEP.ClassName, function()
		local wep = net.ReadEntity()
		if not wep:IsValid() then return end
		local id = net.ReadUInt(8)
		local delay = net.ReadFloat()
		wep:Attack(id, delay)
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
					if v.think then v.think(self, len, len, RealTime()) end
					v.draw_projectile(self, len, false)
				end
			end
			render.SetColorModulation(1,1,1)
			render.ModelMaterialOverride()
			render.SetBlend(1)
		end

		if self.Owner:IsValid() then--and self.Owner.sword_anim then

			if not self.snd then
				self.snd = CreateSound(self.Owner, "weapons/tripwire/ropeshoot.wav")
				self.snd:Play()
				self.snd:ChangeVolume(0)

				self.scrape_snd = CreateSound(self.Owner, "physics/cardboard/cardboard_box_scrape_smooth_loop1.wav")
				self.scrape_snd:Play()
				self.scrape_snd:ChangeVolume(0)
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
				render.SetBlend((i/10) * 0.1)

				if self.pos_history[i+1] then

					local cur_pos = data.pos
					local nxt_pos = self.pos_history[i+1].pos

					local cur_ang = data.ang
					local nxt_ang = self.pos_history[i+1].ang

					for i2 = 1,20 do
						local pos = LerpVector(i2/20, cur_pos, nxt_pos)
						local ang = LerpAngle(i2/20, cur_ang, nxt_ang)

						local start_pos, end_pos = self:TracePosition(pos, ang)

						if i > 8 and l > 2 and last_pos:Distance(start_pos) > 2.5 then
							last_pos = start_pos

							local data = {
								start = start_pos,
								endpos = end_pos,
								filter = {self.Owner, self, self.Owner:GetNWEntity("shield"), self:GetNW2Entity("physics")}
							}
							local tr = util.TraceLine(data)
							debugoverlay.Line(data.start, tr.HitPos, 1, tr.Hit and Color(255, 0,0,0) or Color(255, 255, 255, 255))
							if tr.Hit then
								debugoverlay.Cross(tr.HitPos, 10, 2)
								hit = true
								--self:EmitSound("weapons/sniper/sniper_zoomout.wav", 75, math.random(100,150), 1)
								mute_sounds = true
								self:FireBullets({
									Damage = 100,
									Distance = 1,
									Dir = tr.Normal,
									Src = tr.HitPos - tr.HitNormal*2,
									TracerName = "HelicopterTracer",
									AmmoType = "none",
								})

								--[[hahahha
								if tr.Entity:IsValid() then
									net.Start("sword_damage", true)
										net.WriteVector(tr.HitPos)
										net.WriteUInt(l, 8)
										net.WriteEntity(tr.Entity)
									net.SendToServer()
								end]]
								volume = l
								mute_sounds = false
							end
						end

						self:SetPos(pos)
						self:SetAngles(ang)
						self:SetupBones()
						self:DrawModel()
					end
				end
			end

			if self.snd then
				local size = 90
				local phys = self:GetNW2Entity("physics")
				if phys:IsValid() then
					size = 1/(phys:OBBMins() - phys:OBBMaxs()):Length2D() * 700
				end

				self.snd:ChangePitch(math.min(size + l*5, 255))
				self.snd:ChangeVolume((l/8)^4)

				if hit then
					self.scrape_snd:ChangeVolume(0.25)
					self.scrape_snd:ChangePitch(math.min(200 + l*10, 255))
				else
					self.scrape_snd:ChangeVolume(0)
				end
			end

			render.SetBlend(1)
			render.SetColorModulation(1,1,1)
			suppress_player_draw = false
		else
			if self.snd then
				self.snd:ChangeVolume(0)
				self.scrape_snd:ChangeVolume(0)
			end
		end
	end

	function SWEP:OnRemove()
		if self.snd then
			self.snd:Stop()
			self.scrape_snd:Stop()
		end
	end
end

function SWEP:Initialize()
	self:SetHoldType("melee2")
	self:SetModelScale(self.ModelScale)
	--self:SetModelScale(1.25)
end

hook.Add("ShouldCollide", SWEP.ClassName, function(a, b)
	if a.is_sword_phys and b:IsWorld() then return false end
	if a.is_sword_phys and b.is_shield_ent and a:GetOwner() == b:GetOwner() then print("yes")return  false end
end)

function SWEP:Deploy()
	if SERVER then
		local ent = ents.Create("prop_physics")
		ent:SetModel(self.WorldModel)
		ent:SetOwner(self:GetOwner())
		--ent:SetMaterial("models/wireframe")
		ent:SetNoDraw(true)
		ent:SetPos(self:GetOwner():GetPos())
		ent:Spawn()
		ent:GetPhysicsObject():SetMass(1)
		ent:GetPhysicsObject():EnableGravity(false)
		ent:SetCustomCollisionCheck(true)
		ent.is_sword_phys = true
		self:SetNW2Entity("physics", ent)
		ent:AddCallback("PhysicsCollide", function(_, data)
			if not data.HitEntity:IsValid() then return end
			local d = DamageInfo()
			d:SetAttacker(self.Owner)
			d:SetInflictor(self.Owner)
			d:SetDamage(data.Speed/100)
			d:SetDamageType(DMG_SLASH)
			d:SetDamagePosition(self.Owner:EyePos())
			data.HitEntity:TakeDamageInfo(d)
			self.tp_back = true
		end)
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

			--[[local start_pos, end_pos = self:TracePosition(pos, ang)
			local data = {
				mins = Vector( -10, -10, -10 ),
				maxs = Vector( 10, 10, 10 ),
				start = start_pos,
				endpos = end_pos,
				filter = {self.Owner, self, self.Owner:GetNWEntity("shield"), self:GetNW2Entity("physics")}
			}
			local tr = util.TraceHull(data)

			if tr.Entity:IsValid() then
				local d = DamageInfo()
				d:SetAttacker(self.Owner)
				d:SetInflictor(self.Owner)
				d:SetDamage(1)
				d:SetDamageType(DMG_SLASH)
				d:SetDamagePosition(self.Owner:EyePos())
				tr.Entity:TakeDamageInfo(d)
			end
			]]

			if self.phys:IsValid() then

				local phys = self.phys:GetPhysicsObject()

				if self.tp_back then
					phys:SetPos(pos)
					phys:SetAngles(ang)
					self.tp_back = false
				end

				phys:Wake()
				phys:ComputeShadowControl({
					pos = pos,
					angle = ang,
					deltatime = FrameTime(),
					teleportdistance = 150,
					dampfactor = 0.9,
					maxspeeddamp = 1000000,
					maxspeed = 1000000,
					maxangulardamp = 1000000,
					maxangular = 1000000,
					secondstoarrive = 0.001,
				})
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

function SWEP:Attack(id, delay)
	-- self.Owner:SetVelocity(self.Owner:GetAimVector()*500)

	if SERVER then
		self:Animation(id)
		net.Start(SWEP.ClassName, true)
			net.WriteEntity(self)
			net.WriteUInt(id, 8)
			net.WriteFloat(delay)
		net.SendOmit(self.Owner)
	end

	if CLIENT then
		self:Animation(id)
	end

	--self:Damage(delay)
end

function SWEP:Damage(delay)
	if CLIENT then
		--timer.Create(tostring(self) .. "sound", delay/2, 1, function()
--			self:EmitSound("Weapon_Crowbar.Single", nil, 100)
		--end)
	end

	local ply = self.Owner
	timer.Create(tostring(self) .. "damage", delay, 1, function()
		local tr = util.TraceHull({start = ply:EyePos() + ply:GetAimVector() * 15, endpos = ply:EyePos() + ply:GetAimVector() * 30, filter = {ply}, mins = Vector(1,1,1)*-30, maxs = Vector(1,1,1)*30})
		if tr.Entity:IsValid() then
			if SERVER then
				local d = DamageInfo()
				d:SetAttacker(ply)
				d:SetInflictor(ply)
				d:SetDamage(30)
				d:SetDamageType(DMG_SLASH)
				d:SetDamagePosition(ply:EyePos())
				tr.Entity:TakeDamageInfo(d)
			end
		end
	end)
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

	SWEP.WorldModel = "models/kuma96/2b/virtuouscontract/virtuouscontract.mdl"
	SWEP.SetupPosition = function(self, pos, ang)
		pos = pos + ang:Forward()*2
		pos = pos + ang:Right()*1
		pos = pos + ang:Up()*-63

		ang:RotateAroundAxis(ang:Up(), 90)
		return pos, ang
	end
	SWEP.TracePosition = function(self, pos, ang)
		return pos + ang:Up() * 50, pos
	end

	weapons.Register(SWEP, SWEP.ClassName)
end


if false then
	local SWEP = {Primary = {}, Secondary = {}}
	SWEP.ClassName = "weapon_jsword_overture"
	SWEP.Base = "weapon_jsword_base"

	SWEP.PrintName = "overture"
	SWEP.Spawnable = true
	SWEP.Category = "JRPG"

	SWEP.WorldModel = "models/kuma96/lightningetro/overture/overture.mdl"
	SWEP.SetupPosition = function(self, pos, ang)
		pos = pos + ang:Forward()*2
		pos = pos + ang:Right()*1
		pos = pos + ang:Up()*-10

		ang:RotateAroundAxis(ang:Up(), -180)
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

	SWEP.PrintName = "beastlord"
	SWEP.Spawnable = true
	SWEP.Category = "JRPG"

	SWEP.MoveSet = "vanguard"
	SWEP.WorldModel = "models/kuma96/2b/beastlord/beastlord.mdl"
	SWEP.SetupPosition = function(self, pos, ang)
		pos = pos + ang:Forward()*-1
		pos = pos + ang:Right()*1
		pos = pos + ang:Up()*-92

		ang:RotateAroundAxis(ang:Up(), 90)
		return pos, ang
	end
	SWEP.TracePosition = function(self, pos, ang)
		return pos, pos + ang:Up() * 50
	end

	weapons.Register(SWEP, SWEP.ClassName)
end