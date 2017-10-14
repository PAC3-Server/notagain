local SWEP = {Primary = {}, Secondary = {}}
SWEP.ClassName = "weapon_jsword"

SWEP.PrintName = "jrpg sword"
SWEP.Spawnable = true

SWEP.WorldModel = "models/kuma96/2b/virtuouscontract/virtuouscontract.mdl"
SWEP.ViewModel = SWEP.WorldModel
SWEP.UseHands = true

--ryoku pure vanguard judge phalanx
SWEP.MoveSet = "phalanx"
SWEP.Speed = 0.1

hook.Add("Move", SWEP.ClassName, function(ply, mv)
	local self = ply:GetActiveWeapon()
	if self.ClassName ~= SWEP.ClassName then return end
	if ply:GetNW2Float("roll_time", 0) > CurTime() or ply.roll_time then return end

	if ply.sword_anim and ply.sword_cycle and ply.sword_cycle < 0.5 then
		mv:SetForwardSpeed(mv:GetForwardSpeed() + 75)
	end
end)

hook.Add("CalcMainActivity", SWEP.ClassName, function(ply)
	local self = ply:GetActiveWeapon()
	if self.ClassName ~= SWEP.ClassName then return end
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
	if self.ClassName ~= SWEP.ClassName then return end
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

	ply.sword_anim = self.MoveSet .. "_b_s" .. id .. "_t" .. math.random(1, 3)
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
		local pos, ang
		if self.Owner:IsValid() then
			local id = self.Owner:LookupBone("ValveBiped.Bip01_R_Hand")
			if id then
				pos, ang = self.Owner:GetBonePosition(id)

				--ang:RotateAroundAxis(ang:Right(), 90)
				--pos = pos + ang:Forward()*20
				--pos = pos + ang:Up()*-3.2
				--pos = pos + ang:Right()*-1.5

				pos = pos + ang:Forward()*2
				pos = pos + ang:Right()*1
				pos = pos + ang:Up()*-63

				ang:RotateAroundAxis(ang:Up(), 90)

				self:SetPos(pos)
				self:SetAngles(ang)
				self:SetupBones()
			end
		end

		self:DrawModel()

		if self.Owner:IsValid() and self.Owner.sword_anim then

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

			local hit = false

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

						if i > 8 and l > 2 and math.random() > 0.95 then

							local tr = util.TraceLine({start = pos, endpos = pos + ang:Up() * 50, filter = {self.Owner, self, self.Owner:GetNWEntity("shield")}})
							if tr.Hit then

								hit = true
								--self:EmitSound("weapons/sniper/sniper_zoomout.wav", 75, math.random(100,150), 1)
								mute_sounds = true
								self:FireBullets({
									Damage = 100,
									Distance = 1,
									Dir = tr.Normal,
									Src = tr.HitPos - tr.HitNormal,
									TracerName = "HelicopterTracer",
									AmmoType = "none",
								})

								-- hahahha
								if tr.Entity:IsValid() then
									net.Start("sword_damage", true)
										net.WriteVector(tr.HitPos)
										net.WriteUInt(l, 8)
										net.WriteEntity(tr.Entity)
									net.SendToServer()
								end
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
				self.snd:ChangePitch(math.min(90 + l*5, 255))
				self.snd:ChangeVolume((l/8)^2)

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
	--self:SetModelScale(1.5)
	self:SetModelScale(1.25)
end


if SERVER then
	util.AddNetworkString(SWEP.ClassName)

	-- hahahha
	util.AddNetworkString("sword_damage")
	net.Receive("sword_damage", function(_, ply)
		local self = ply:GetActiveWeapon()
		if self.ClassName ~= SWEP.ClassName then return end

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
	--self:SetNextPrimaryFire(CurTime() + 0.25)
end


function SWEP:SecondaryAttack()
	self:Attack(1, 0.25)
	--self:SetNextPrimaryFire(CurTime() + 0.25)
end

weapons.Register(SWEP, SWEP.ClassName)