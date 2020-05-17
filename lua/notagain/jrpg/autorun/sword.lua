local SWEP = {Primary = {}, Secondary = {}}
SWEP.ClassName = "weapon_jsword_base"

SWEP.PrintName = "jrpg base sword"
SWEP.Spawnable = false
SWEP.ModelScale = 1
SWEP.OverallSpeed = 1
SWEP.SwordRange = 30
SWEP.Damage = 30
SWEP.Force = 1
SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.ViewModel = SWEP.WorldModel
SWEP.UseHands = true
SWEP.is_jsword = true
--ryoku pure vanguard judge phalanx
SWEP.MoveSet = "phalanx"
SWEP.MoveSet2 = {
	light = {
		{
			seq = "phalanx_b_s1_t3",
			duration = 0.5,
			min = 0,
			max = 0.7,

			damage_frac = 0.3,
			damage_ang = Angle(45,-90,0),
		}
	}
}

hook.Add("Move", SWEP.ClassName, function(ply, mv)
	local self = ply:GetActiveWeapon()
	if not self.is_jsword then return end
	if ply:GetNW2Float("roll_time", 0) > CurTime() or ply.roll_time then return end


	if self.sword_anim_cycle and ply:IsOnGround() then
		local f = self.sword_anim_cycle
		if f > 0 and f < 0.9 then
			if f <= self.sword_anim_info.damage_frac then
				local dir = ply:GetAimVector()
				dir.z = 0
				dir = dir*60
				mv:SetVelocity(dir)
			end
		end
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
	local self = ply:GetActiveWeapon()
	if not self.is_jsword then return end
	if jrpg.IsWieldingShield(ply) then return end
	if ply:GetNW2Float("roll_time", 0) > CurTime() or ply.roll_time then return end

	local vel = ply:GetVelocity()
	local seq

	if vel:Length2D() < 20 then
		if ply:KeyDown(IN_DUCK) then
			seq = ply:LookupSequence("cidle_knife")
		else
			seq = ply:LookupSequence(self.MoveSet .. "_idle_lower")

			if seq < 0 then
				seq = ply:LookupSequence(self.MoveSet .. "_b_idle")
			end
		end
		ply:SetPlaybackRate(0)
		ply:SetCycle((CurTime()*0.1)%1)
	end

	if seq then
		ply:SetSequence(seq)
	end

	--return true
end)

function SWEP:Animation(type)
	if not self.MoveSet2[type] then
		return
	end

	local ply = self.Owner
	local move_index = self:GetNW2Int("move_index")
	local index = (move_index%#self.MoveSet2[type]) + 1
	local info = self.MoveSet2[type][index]

	self.sword_anim_info = info
	self.sword_damaged = nil
	self.sword_anim_cycle = nil
	self.sound_played = nil
	self.pos_history = {}
	local reversed = false
	local reversed2 = 0
	local callback_timer = nil

	local pos_history = {}

	jrpg.PlayGestureAnimation(ply, {
		seq = info.seq,
		start = info.min,
		stop = info.max,
		speed = self.OverallSpeed * (info.speed or 1),
		done = function(f)
			if info.done then
				info.done(self, f, callback_timer and (CurTime() - callback_timer) or 0, info)
			end
		end,
		callback = function(f, data)
			self.sword_anim_cycle = f

			local res = info.callback and info.callback(self, f, callback_timer and (CurTime() - callback_timer) or 0, info)

			if res ~= nil then
				callback_timer = callback_timer or CurTime()
				return res
			end


			local pos, ang, mins, maxs = self:GetHitBox()

			if CLIENT then
				if f >= info.damage_frac - 0.5 and type ~= "heavy" then
					if not self.sound_played then
						local pitch = (0.8/mins:Distance(maxs))*60
						ply:EmitSound("npc/zombie/claw_miss1.wav", 70, math.Clamp(math.Rand(100,120) * pitch, 50, 255))
						ply:EmitSound("npc/scanner/scanner_nearmiss1.wav", 70, math.Clamp(math.Rand(90,120) * pitch, 50, 255))
						self.sound_played = true
					end
				end
			end

			if not self.sword_damaged and f >= info.damage_frac-0.25 then
				table.insert(pos_history, pos + ang:Up() * self.SwordRange*0.5)
				if GetConVarNumber("developer") > 4 then
					debugoverlay.Cross(pos + ang:Up() * self.SwordRange*0.5, 1, 5, SERVER and Color(0,0,255) or Color(255,255,0))
				end
			end

			if f >= info.damage_frac then
				if not self.sword_damaged then
					local pos = ply:WorldSpaceCenter() + ply:GetForward() * self.SwordRange
					local dir = (pos_history[1] - pos_history[#pos_history]):GetNormalized()
					ang = dir:Angle()

					--debugoverlay.Line(pos + dir:GetNormalized() * 100, pos - dir:GetNormalized() * 100, 1.5, Color(255, 0,255,255), true)


					local size = 40
					if GetConVarNumber("developer") > 4 then
						debugoverlay.Sphere(pos, size, 0.5, Color(255, 255, 255, 5))
						debugoverlay.Axis(pos, ang, 10, 5, true)
						debugoverlay.Line(pos, pos + ang:Forward() * 150, 5, SERVER and Color(0,0,255) or Color(255,255,0), true)
					end

					local z_mult = (math.abs(ply.sword_last_zvel or ply:GetVelocity().z) / 1000) +1
					local damage = self.Damage * z_mult * (info.damage or 1)
					local hit_something = false
					local found =  ents.FindInSphere(pos, size)
					for k,v in ipairs(found) do
						if v ~= ply and v:GetOwner() ~= ply and not table.HasValue(found, v:GetOwner()) and ((not SERVER or v:GetPhysicsObject():IsValid()) or jrpg.IsActor(ent)) then
							if SERVER then
								local d = DamageInfo()
								d:SetAttacker(ply)
								d:SetInflictor(ply)
								d:SetDamage(damage)
								d:SetDamageType(DMG_SLASH)
								d:SetDamagePosition(v:NearestPoint(pos))
								d:SetDamageForce(dir * -(300 * self.Force * z_mult) * damage)
								v:TakeDamageInfo(d)

								if damage > 100 and v:IsNPC() then
									jrpg.KnockoutEntity(v, ply, (dir+Vector(0,0,0.7))*-4 * damage, true)
								end
							end
							if CLIENT then
								local info = util.GetSurfaceData(util.QuickTrace(pos, dir*1000).SurfaceProps)

								local pitch = (0.8/mins:Distance(maxs))*60


								for i = 1, 3 do
									self.Owner:EmitSound("weapons/blade_slice_"..math.random(2,4)..".wav", 70, math.Clamp(math.Rand(200,240)/(i*0.75) * pitch, 50, 255))
									local tbl = sound.GetProperties(info.impactHardSound).sound
									if _G.type(tbl) == "string" then tbl = {tbl} end
									self.Owner:EmitSound((table.Random(tbl)), 70, math.Clamp(math.Rand(140,160)/(i*0.75)*pitch, 50, 255))
								end

								local tbl = sound.GetProperties(info.bulletImpactSound).sound
								if _G.type(tbl) == "string" then tbl = {tbl} end
								self.Owner:EmitSound((table.Random(tbl)), 70, math.Clamp(math.Rand(140,160)*pitch, 50, 255))

								--debugoverlay.Cross(v:GetPos(), 10)
								break
							end
						end
					end

					self.sword_damaged = true
				end

				self:SetNextPrimaryFire(CurTime())
				self:SetNextSecondaryFire(CurTime())

				if info.recovery_time then
					data.speed_mult = info.recovery_time
				end
			end
		end
	})
end

if CLIENT then
	net.Receive(SWEP.ClassName, function()
		local wep = net.ReadEntity()
		if not wep:IsValid() or not wep.Attack then return end
		local type = net.ReadString()
		local delay = net.ReadFloat()
		wep:Attack(type)
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

	local function add_quad(start_pos, stop_pos, start_ang, stop_ang, start_width, stop_width, r,g,b,a)
		local lower_right = Vector(0,-start_width*0.5,0)
		local lower_left = Vector(0,start_width*0.5,0)

		local upper_right = Vector(0,-stop_width*0.5,0)
		local upper_left = Vector(0,stop_width*0.5,0)

		lower_right:Rotate(start_ang)
		upper_right:Rotate(stop_ang)

		lower_left:Rotate(start_ang)
		upper_left:Rotate(stop_ang)

		mesh.TexCoord(0, 0, 1)
		mesh.Color(r,g,b,a)
		mesh.Position(stop_pos + upper_left)
		mesh.AdvanceVertex()

		mesh.TexCoord(0, 0, 0)
		mesh.Color(r,g,b,a)
		mesh.Position(start_pos + lower_left)
		mesh.AdvanceVertex()

		mesh.TexCoord(0, 1, 0)
		mesh.Color(r,g,b,a)
		mesh.Position(start_pos + lower_right)
		mesh.AdvanceVertex()

		mesh.TexCoord(0, 1, 1)
		mesh.Color(r,g,b,a)
		mesh.Position(stop_pos + upper_right)
		mesh.AdvanceVertex()

		mesh.TexCoord(0, 0, 1)
		mesh.Color(r,g,b,a)
		mesh.Position(stop_pos + upper_left)
		mesh.AdvanceVertex()

		mesh.TexCoord(0, 1, 0)
		mesh.Color(r,g,b,a)
		mesh.Position(start_pos + lower_right)
		mesh.AdvanceVertex()
	end

	local jfx = requirex("jfx")
	local trail = jfx.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "vgui/gradient-r",
		NoCull = 1,
		Additive = 1,
		VertexColor = 1,
		VertexAlpha = 1,
	})

	function SWEP:DrawWorldModel()
		local pos, ang = Vector(), Angle()
		if self.Owner:IsValid() then
			local id = self.Owner:LookupBone("ValveBiped.Bip01_R_Hand")
			if id then
				self.Owner:InvalidateBoneCache()
				local m = self.Owner:GetBoneMatrix(id)
				if m then
					pos = m:GetTranslation()
					ang = m:GetAngles()

					pos, ang = self:SetupPosition(pos, ang)

					self:SetPos(pos)
					self:SetAngles(ang)
					self:SetupBones()
				end
			end
		end

		self:DrawModel()
	end

	function SWEP:DrawWorldModelTranslucent()

		if self:GetNWBool("wepstats_elemental") then
			for k, v in pairs(jdmg.types) do
				if self:GetNWBool("wepstats_elemental_" .. k) then
					local len = self.last_vel_length or 0
					len = 1
					v.draw(self, len, len, RealTime())
				end
			end
		end

		if self.Owner:IsValid() and self.sword_anim_cycle and self.sword_anim_cycle < self.sword_anim_info.damage_frac then
			local R,G,B = 255,255,255
			local total = 1

			if self:GetNWBool("wepstats_elemental") then
				for k, v in pairs(jdmg.types) do
					if self:GetNWBool("wepstats_elemental_" .. k) then

						local old = self:GetPos()
						for i = 1, 3 do
							self:SetPos(old + self:GetUp() * math.random(self.SwordRange))
							local len = self.last_vel_length or 0
							len = 1
							v.draw(self, len, len, RealTime())
							if v.think then v.think(self, len, len, RealTime()) end
							v.draw_projectile(self, len, false)
							--if v.think then v.think(self, len, 1,1) end
							self:SetPos(old)
						end

						R = R + v.color.r
						G = G + v.color.g
						B = B + v.color.b
						total = total + 1
					end
				end
			end

			R = R / total
			G = G / total
			B = B / total

			self.pos_history = self.pos_history or {}
			local pos, ang = self:GetHitBox()
			if pos then
				local real_ang = ang*1
				ang:RotateAroundAxis(ang:Forward(), 90)
				if not self.pos_history[1] or self.pos_history[1].pos:Distance(pos) > 1 then
					table.insert(self.pos_history, {pos = pos - real_ang:Up() * -self.SwordRange * 0.5, ang = ang})
				end

				if #self.pos_history > 15 then
					table.remove(self.pos_history, 1)
				end

				render.SetMaterial(trail)

				local quads = #self.pos_history
				render.SuppressEngineLighting(true)
				mesh.Begin(MATERIAL_TRIANGLES, 2*quads)
					local ok, err = pcall(function()
					for i = 0, quads - 1 do
						local a = self.pos_history[i+1]
						local b = self.pos_history[i]
						if a and b then
							add_quad(b.pos, a.pos, b.ang, a.ang, self.SwordRange, self.SwordRange, R,G,B, 55*(i/quads)^1)
						end
					end
					end) if not ok then ErrorNoHalt(err) end
				mesh.End()
				render.SuppressEngineLighting(false)
			end

			suppress_player_draw = false
		end

		render.SetColorModulation(1,1,1)
		render.ModelMaterialOverride()
		render.SetBlend(1)
	end

	function SWEP:OnRemove()

	end
end

function SWEP:Initialize()
	self:SetHoldType("hands")
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

function SWEP:GetHitBox()
	local pos, ang = Vector(), Angle()
	if self.Owner:IsValid() then
		local id = self.Owner:LookupBone("ValveBiped.Bip01_R_Hand")
		if id then
			pos, ang = self.Owner:GetBonePosition(id)
			pos, ang = self:SetupPosition(pos, ang)

			local min = Vector(-3,-3,0)
			local max = Vector(3,3,self.SwordRange)

			return pos, ang, min, max
		end
	end
end

function SWEP:Think()
	if GetConVarNumber("developer") == 0 then return end
	local pos, ang, min, max = self:GetHitBox()
	if GetConVarNumber("developer") > 4 then
		debugoverlay.BoxAngles(pos, min, max, ang, 0, SERVER and Color(0,0,255) or Color(255,255,0))
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

function SWEP:Attack(type)
	if SERVER then
		self:Animation(type)

		net.Start(SWEP.ClassName, true)
			net.WriteEntity(self)
			net.WriteString(type)
		net.SendOmit(self.Owner)
	end

	if CLIENT then
		self:Animation(type)
	end

	self:SetNW2Int("move_index", self:GetNW2Int("move_index", 0) + 1)
end

function SWEP:PrimaryAttack()
	--if not IsFirstTimePredicted() then return end
	if jrpg.IsActorRolling(self.Owner) or jrpg.IsActorDodging(self.Owner) then return end

	if not self.Owner:IsOnGround() then
		self:Attack("jump")
	elseif self.Owner:GetVelocity():Dot(self.Owner:GetForward()) > 50 then
		self:Attack("forward")
	else
		self:Attack("light")
	end
	self:SetNextPrimaryFire(CurTime() + 5)
	self:SetNextSecondaryFire(CurTime() + 5)
end


function SWEP:SecondaryAttack()
	--if not IsFirstTimePredicted() then return end
	if jrpg.IsActorRolling(self.Owner) or jrpg.IsActorDodging(self.Owner) then return end

	self:Attack("heavy")
	self:SetNextPrimaryFire(CurTime() + 5)
	self:SetNextSecondaryFire(CurTime() + 5)
end

weapons.Register(SWEP, SWEP.ClassName)

local shared_charge = {
	{
		seq = "phalanx_h_s2_t1",
		speed = 1,
		min = 0,
		max = 0.8,

		damage_frac = 0.3,
		damage = 2,

		done = function(self, f, f2, info)
			info.damage = 2
			if self.charge_sounds then
				for i,v in ipairs(self.charge_sounds) do
					v:Stop()
				end
			end
			self.charge_sounds = nil
		end,

		callback = function(self, f, f2, info)
			self.sword_anim_cycle = 1
			if SERVER then

				self.Owner:SetNW2Bool("jrpg_sword_charge", self.Owner:KeyDown(IN_ATTACK2))
			end

			if self.Owner:GetNW2Bool("jrpg_sword_charge") and f > 0.1 then
				self:SetNextPrimaryFire(CurTime())
				self:SetNextSecondaryFire(CurTime())
				info.damage = f2*5

				if CLIENT then
					jrpg.AddScreenShake(f2/10, f2, 0.35)
				end

				self.charge_sounds = self.charge_sounds or {}

				self.charge_sounds[1] = self.charge_sounds[1] or CreateSound(self.Owner, "ambient/levels/citadel/citadel_hub_ambience1.mp3")
				self.charge_sounds[1]:PlayEx(f2/10, 100)
				self.charge_sounds[1]:ChangePitch(100+f2)

				self.charge_sounds[2] = self.charge_sounds[2] or CreateSound(self.Owner, "ambient/levels/citadel/extract_loop1.wav")
				self.charge_sounds[2]:PlayEx(f2/10, 100)
				self.charge_sounds[2]:ChangePitch(100+f2*2)

				self.charge_sounds[3] = self.charge_sounds[3] or CreateSound(self.Owner, "ambient/atmosphere/tone_quiet.wav")
				self.charge_sounds[3]:PlayEx(f/3, 100)
				self.charge_sounds[3]:ChangePitch(50+f2)


				return 0.1+(math.random()*f2*0.01)
			else
				if self.charge_sounds then
					for i,v in ipairs(self.charge_sounds) do
						v:Stop()
					end



					if CLIENT then
						timer.Simple(0.25,function()
							self.Owner:EmitSound("npc/scanner/cbot_energyexplosion1.wav", 75, 200, f2/10)
							self.Owner:EmitSound("npc/scanner/cbot_energyexplosion1.wav", 75, 100, f2/20)
							self.Owner:EmitSound("npc/scanner/cbot_energyexplosion1.wav", 75, 150, f2/30)
							self.Owner:EmitSound("npc/scanner/cbot_energyexplosion1.wav", 75, 50, f2/40)
							self.Owner:EmitSound("npc/scanner/cbot_energyexplosion1.wav", 75, 50, f2/40)
						end)
					end

				end

				self.charge_sounds = nil
			end
		end,
	},
	--[[{
		seq = "phalanx_b_s2_t3",
		speed = 1,
		min = 0,
		max = 1,

		damage_frac = 0.3,
		damage = 2,
	},]]
}

do
	local SWEP = {Primary = {}, Secondary = {}}
	SWEP.ClassName = "weapon_jsword_virtuouscontract"
	SWEP.Base = "weapon_jsword_base"

	SWEP.PrintName = "virtuous contract"
	SWEP.Spawnable = true
	SWEP.Category = "JRPG"
	SWEP.OverallSpeed = 1.25
	SWEP.SwordRange = 40

	SWEP.MoveSet2 = {
		light = {
			{
				seq = "phalanx_b_s1_t2",
				speed = 1,
				min = 0,
				max = 1,
				recovery_time = 1,

				damage_frac = 0.23,
				damage_ang = Angle(-70,-90,0),
			},
			{
				seq = "phalanx_b_s2_t2",
				speed = 1,
				min = 0,
				max = 1,
				recovery_time = 1,

				damage_frac = 0.3,
				damage = 2,
			},
		},
		heavy = shared_charge,
		jump = {
			{
				seq = "phalanx_h_s1_t3",
				speed = 0.8,
				min = 0,
				max = 1,
				damage_frac = 0.4,
				damage = 3,
				callback = function(self, f)
					if f > 0.4 then
						if not self.Owner:IsOnGround() then
							self.Owner.sword_last_zvel = self.Owner:GetVelocity().z

							return 0.4
						end
					end
				end
			},
		},
		forward = {
			{
				seq = "phalanx_b_s3_t2",
				speed = 0.6,
				min = 0,
				max = 1,

				damage_frac = 0.5,
				damage = 1.5,
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

	SWEP.OverallSpeed = 0.8
	SWEP.SwordRange = 60
	SWEP.Damage = 60
	SWEP.Force = 5

	SWEP.MoveSet2 = {
		light = {
			{
				seq = "vanguard_b_s3_t3",
				duration = 1,
				min = 0.1,
				max = 1,

				damage_frac = 0.4,
				damage_ang = Angle(90,-90,0),
			},
			{
				seq = "vanguard_b_s3_t2",
				duration = 1,
				min = 0.25,
				max = 1,

				damage_frac = 0.4,
				damage_ang = Angle(90,-90,0),
			},
		},
		heavy = shared_charge,
		jump = {
			{
				seq = "phalanx_h_s1_t3",
				speed = 0.8,
				min = 0,
				max = 1,
				damage_frac = 0.4,
				damage = 3,
				callback = function(self, f)
					if f > 0.4 then
						if not self.Owner:IsOnGround() then
							self.Owner.sword_last_zvel = self.Owner:GetVelocity().z

							return false
						end
					end
				end
			},
		},
		forward = {
			{
				seq = "vanguard_b_s2_t3",
				duration = 1,
				min = 0.2,
				max = 1,

				damage_frac = 0.3,
				damage_ang = Angle(-45,-90,0),
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