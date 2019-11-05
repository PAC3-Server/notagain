local suppress

do
	local ENT = {}
	ENT.Base = "base_anim"
	ENT.ClassName = "jprojectile_bullet"

	function ENT:SetupDataTables()
		self:NetworkVar("Vector", 0, "CollisionPoint")
		self:NetworkVar("Vector", 1, "CollisionNormal")
		self:NetworkVar("Entity", 0, "CollisionEntity")
		self:NetworkVar("String", 0, "DamageTypes")

		self:NetworkVar("Float", 0, "Damage")
		self:NetworkVar("Float", 1, "LifeTime")
	end

	function ENT:Initialize()
		self:SetCollisionPoint(Vector(0,0,0))
		self:SetCollisionEntity(NULL)

		self.life_time = RealTime() + self:GetLifeTime()

		if SERVER then
			self:SetModel("models/props_junk/PopCan01a.mdl")
			self:PhysicsInitSphere(5)
			local phys = self:GetPhysicsObject()

			self:StartMotionController()

			self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)

			if self:GetOwner():IsValid() then
				self.rand_dir = (self.dir - self:GetOwner():EyeAngles():Forward())
				self.start_time = RealTime() + 1
				self.damp = math.random()
				if self.damage then self:SetDamage(self.damage) end
				SafeRemoveEntityDelayed(self, 30)
				phys:EnableGravity(false)
			end
		end

		if CLIENT then
			self:SetRenderBounds(Vector(1,1,1)*-200, Vector(1,1,1)*200)
			self.pixvis = util.GetPixelVisibleHandle()
			self.damage_types = self:GetDamageTypes():Split(",")
			if not self.damage_types[1] then
				table.insert(self.damage_types, "generic")
			end

			self.sounds = {}

			for _, name in ipairs(self.damage_types) do
				if jdmg.types[name] and jdmg.types[name].sounds then
					for _, info in ipairs(jdmg.types[name].sounds) do
						local snd = CreateSound(self, info.path)
						snd:Play()
						snd:ChangeVolume(1)
						table.insert(self.sounds, {
							snd = snd,
							base_pitch = info.pitch
						})
					end
				end
			end

			if not self.sounds[1] then
				local snd = CreateSound(self, "physics/cardboard/cardboard_box_scrape_smooth_loop1.wav")
				snd:Play()
				snd:ChangeVolume(1)
				table.insert(self.sounds, {snd = snd, base_pitch = 100})
			end
		end
	end

	function ENT:OnDamage()
		local pos = self:GetCollisionPoint()
		local normal = self:GetCollisionNormal()
		local ent = self:GetCollisionEntity()

		if CLIENT then
			for _, data in ipairs(self.sounds) do
				data.snd:Stop()
			end
		end

		if SERVER then
			local data = self.bullet_info
			if data then
				data.Attacker = self:GetOwner()
				data.Dir = normal
				data.Src = self:GetPos()
				data.Distance = pos:Distance(self:GetPos())*2
				data.HullSize = 10
				suppress = true
				self:FireBullets(data)
				suppress = false
			else
				for _, name in ipairs(self:GetDamageTypes():Split(",")) do
					if jdmg.enums[name] then

						local d = DamageInfo()
						d:SetDamage(50)
						d:SetDamageCustom(jdmg.enums[name])
						d:SetAttacker(self:GetOwner())
						d:SetInflictor(self:GetOwner())

						if ent:IsValid() then
							ent:TakeDamageInfo(d)
						else
							for i = 1, math.random(2, 4) do
								local temp = ents.Create("prop_physics")
								temp:SetModel("models/props_junk/rock001a.mdl")
								if CPPI then temp:CPPISetOwner(self:GetOwner()) end
								temp:SetPos(pos)
								temp:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
								temp:SetModelScale(math.Rand(0.25, 1))
								temp:SetAngles(VectorRand():Angle())
								temp:SetColor(Color(1,1,1,1))
								temp:SetRenderMode(RENDERMODE_TRANSALPHA)
								temp:SetMaterial("models/debug/debugwhite")
								temp:Spawn()
								if i < 2 then
									temp:PhysicsInit(SOLID_NONE)
								else
									temp:GetPhysicsObject():SetVelocity((VectorRand()-normal)*50 - self.old_vel*math.Rand(0.25,0.5))
								end
								SafeRemoveEntityDelayed(temp, 2)

								local d = DamageInfo()
								d:SetDamage(100)
								d:SetDamageCustom(jdmg.enums[name])
								d:SetAttacker(self:GetOwner())
								d:SetInflictor(self:GetOwner())
								d:SetDamagePosition(pos)
								temp:TakeDamageInfo(d)
							end

							local sphere = ents.Create("jprojectile_bullet")
							sphere:SetPos(pos)
							sphere:SetDamageTypes(self:GetDamageTypes())
							if CPPI then sphere:CPPISetOwner(self:GetOwner()) end
							sphere:Spawn()
							local phys = sphere:GetPhysicsObject()
							phys:SetVelocity(self.old_vel*1)
							phys:SetMaterial("gmod_bouncy")
							phys:SetMass(5)

							sphere:SetLifeTime(2)
							SafeRemoveEntityDelayed(sphere, 2.1)

							sphere:TakeDamageInfo(d)
						end
					else
						print("invalid damage type", name, "!?")
						print(self:GetDamageTypes())
						ErrorNoHalt()
					end
				end
			end

			SafeRemoveEntityDelayed(self, 0)
		end
	end

	if CLIENT then
		function ENT:Think()
			if self.damaged or not self.pixvis then return end

			if CLIENT then
				local pitch = self:GetVelocity():Length()/100
				pitch = pitch ^ 2

				for _, data in ipairs(self.sounds) do
					data.snd:ChangePitch(math.Clamp(data.base_pitch + pitch, 0, 255))
				end
			end

			if self:GetCollisionPoint() ~= vector_origin and not self.damaged then
				self:OnDamage()
				self.damaged = true
			end

			self:NextThink(CurTime())
		end

		function ENT:Draw()
			self:SetRenderAngles(self:GetVelocity():Angle()+Angle(90,0,0))
		end

		ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

		function ENT:DrawTranslucent()
			if self.damaged or not self.pixvis then return end

			--[[
			if self:GetLocalPos():Distance(EyePos()) < 40 then
				local posang = self:GetOwner():GetViewModel():GetAttachment(1)
				self:SetRenderOrigin(posang.Pos)
			else
				self:SetRenderOrigin()
			end
			]]

			local f = math.max(self.life_time - RealTime(), 0)
			f = f / self:GetLifeTime()
			if self:GetLifeTime() == 0 then f = 1 end
			f = f ^ 0.25

			for _, name in ipairs(self.damage_types) do
				if jdmg.types[name] and jdmg.types[name].draw_projectile then
					local rad = math.max(self:GetDamage(), 50) + math.Rand(0.75,1.25)
					jdmg.types[name].draw_projectile(self, rad*f, nil, util.PixelVisible(self:GetPos(), rad, self.pixvis))
				end
			end
		end

		function ENT:OnRemove()
			for _, data in ipairs(self.sounds) do
				data.snd:Stop()
			end
		end
	end

	if SERVER then
		hook.Add("GravGunOnPickedUp", ENT.ClassName, function(ply, self)
			if self:GetClass() ~= ENT.ClassName then return end

			if self.bullet_info then
				self:SetBulletData(ply, self.bullet_info, self:GetOwner():GetActiveWeapon())
			end
		end)

		function ENT:SetProjectileData(attacker, pos, dir, dmg, wep)
			wep = wep or attacker:GetActiveWeapon()

			self:SetDamage(dmg or 1)
			self.dir = dir

			local filter = ents.FindByClass(ENT.ClassName)
			table.insert(filter, attacker)
			local trace = util.TraceLine({
				start = pos,
				endpos = pos + dir * 100000,
				filter = filter,
			})

			self:SetOwner(attacker)

			if trace.Entity:IsValid() then
				self.pos = trace.Entity
				self.lpos = trace.Entity:WorldToLocal(trace.HitPos)
			end

			local bone_id = attacker:LookupBone("ValveBiped.Bip01_R_Hand")

			if bone_id then
				self:SetPos(attacker:GetBonePosition(bone_id))
			else
				self:SetPos(pos)
			end

			local ugh = {}
			for name, dmgtype in pairs(wep.wepstats) do
				if dmgtype.Elemental then
					table.insert(ugh, name)
				end
			end
			self:SetDamageTypes(table.concat(ugh, ","))
		end

		function ENT:SetBulletData(attacker, data, wep)
			self:SetProjectileData(attacker, data.Src, data.Dir, data.Damage, wep)
			self.bullet_info = data
		end

		function ENT:PhysicsCollide(data, phys)
			if not self:GetOwner():IsValid() then return end

			if self.damaged or self:GetParent():IsValid() then return end
			self.damaged = true

			self:SetCollisionPoint(data.HitPos)
			self:SetCollisionNormal(data.HitNormal)
			self:SetCollisionEntity(data.HitEntity)

			timer.Simple(0, function()
				self.old_vel = data.OurOldVelocity
				self:StopMotionController()
				phys:Sleep()
				phys:SetVelocity(Vector(0,0,0))

				self:OnDamage()
			end)
		end

		function ENT:Think()
			if self.damaged or self:GetParent():IsValid() then return end

			self:PhysWake()
		end

		function ENT:PhysicsSimulate(phys, delta)
			if self.damaged or self:GetParent():IsValid() then return end

			local ply = self:GetOwner()
			if ply:IsValid() and self.rand_dir then
				local pos = self.pos

				if IsEntity(pos) and pos:IsValid() then
					pos = pos:NearestPoint(pos:LocalToWorld(self.lpos))
				elseif not pos or not pos:IsValid() then
					local filter = ents.FindByClass(ENT.ClassName)
					table.insert(filter, ply)
					pos = util.TraceLine({start = ply:EyePos(), endpos = ply:EyePos() + ply:EyeAngles():Forward()*10000, filter = filter}).HitPos
				end
				local dir = pos - phys:GetPos()
				local dist = dir:Length()
				dir:Normalize()

				local n = dist/150
				local rand_dir = Vector(math.sin(n+self.rand_dir.x), math.cos(n+self.rand_dir.y), math.sin(n+self.rand_dir.z)) * self.rand_dir*20
				rand_dir.z = math.abs(rand_dir.z)

				local vel = LerpVector(math.max(self.start_time - RealTime(), 0), dir * math.Clamp(dist / 10, 1, 20), (dir + rand_dir) * 50)
				vel = vel + phys:GetVelocity() * -delta*3

				for _, ent in ipairs(ents.FindInSphere(self:GetPos(), 100)) do
					if ent ~= self and ent:GetClass() == ENT.ClassName then
						vel = vel + (ent:GetPos() - self:GetPos())*-0.01
					end
				end

				phys:AddVelocity(vel)
			end
		end
	end

	scripted_ents.Register(ENT, ENT.ClassName)
end

if CLIENT then
	net.Receive("jprojectile_sounds", function()
		local ent = net.ReadEntity()
		if ent:IsValid() then
			ent:EmitSound("ambient/levels/citadel/portal_beam_shoot5.wav", 75, 255, 1)
		end
	end)
end

if SERVER then
	util.AddNetworkString("jprojectile_sounds")
end

hook.Add("EntityEmitSound", "jprojectiles", function(data)
	if data.SoundName:find("weapons/", nil, true) and data.OriginalSoundName:EndsWith(".Single") then
		local ply = data.Entity
		if not ply:IsPlayer() and not ply:IsNPC() then return end

		if ply:IsPlayer() and not jrpg.IsEnabled(ply) then return end

		local wep = ply:GetActiveWeapon()

		if wep.jattributes_not_enough_mana then
			return false
		end

		if wep:GetNWBool("wepstats_elemental") then
			--data.SoundLevel = 75
			--data.Volume = 1
			data.DSP = 34

			if not wep.jprojectiles_sound_played or wep.jprojectiles_sound_played < RealTime() then
				wep.jprojectiles_sound_played = RealTime() + 0.1

				if CLIENT then
					data.Entity:EmitSound("ambient/levels/citadel/portal_beam_shoot5.wav", 75, 255, 1)
				end

				if SERVER then
					net.Start("jprojectile_sounds", true)
						net.WriteEntity(data.Entity)
					net.SendOmit(data.Entity)
				end
			end

			return true
		end
	end
end)

hook.Add("EntityFireBullets", "jprojectiles", function(attacker, data)
	if suppress then return end
	if not attacker.GetActiveWeapon then return end

	local wep = attacker:GetActiveWeapon()

	if wep:GetNWBool("wepstats_elemental") then
		if CLIENT then
			return false
		end

		local ent = ents.Create("jprojectile_bullet")
		ent:SetBulletData(attacker, data)
		ent:Spawn()

		return false
	end
end)