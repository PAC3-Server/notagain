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
	end

	function ENT:Initialize()
		self:SetCollisionPoint(Vector(0,0,0))
		self:SetCollisionEntity(NULL)

		if SERVER then
			self:SetModel("models/props_junk/PopCan01a.mdl")
			self:PhysicsInitSphere(5)
			local phys = self:GetPhysicsObject()
			phys:EnableGravity(false)

			self:StartMotionController()

			self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)

			self.rand_dir = (self.bullet_info.Dir - self:GetOwner():GetAimVector())
			self.start_time = RealTime() + 1
			self.damp = math.random()
			self:SetDamage(self.bullet_info.Damage)
			SafeRemoveEntityDelayed(self, 30)
		end

		if CLIENT then
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
			data.Attacker = self:GetOwner()
			data.Dir = normal
			data.Src = self:GetPos()
			data.Distance = pos:Distance(self:GetPos())*2
			data.HullSize = 10
			suppress = true
			self:FireBullets(data)
			suppress = false

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

			for _, name in ipairs(self.damage_types) do
				if jdmg.types[name] and jdmg.types[name].draw_projectile then
					jdmg.types[name].draw_projectile(self, math.max(self:GetDamage(), 50) + math.Rand(0.75,1.25))
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

			self:SetBulletData(ply, self.bullet_info, self:GetOwner():GetActiveWeapon())
		end)

		function ENT:SetBulletData(attacker, data, wep)
			wep = wep or attacker:GetActiveWeapon()
			self:SetOwner(attacker)

			local filter = ents.FindByClass(ENT.ClassName)
			table.insert(filter, attacker)
			local trace = util.TraceLine({
				start = data.Src,
				endpos = data.Src + data.Dir * 100000,
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
				self:SetPos(data.Src)
			end

			self.bullet_info = data

			local ugh = {}
			for name, dmgtype in pairs(wep.wepstats) do
				if dmgtype.Elemental then
					table.insert(ugh, name)
				end
			end
			self:SetDamageTypes(table.concat(ugh, ","))
		end

		function ENT:PhysicsCollide(data, phys)
			self:StopMotionController()
			phys:Sleep()
			phys:SetVelocity(Vector(0,0,0))

			self:SetCollisionPoint(data.HitPos)
			self:SetCollisionNormal(data.HitNormal)
			self:SetCollisionEntity(data.HitEntity)

			timer.Simple(0, function()
				self:OnDamage()
				self.damaged = true
			end)
		end

		function ENT:Think()
			self:GetPhysicsObject():Wake()
		end

		function ENT:PhysicsSimulate(phys, delta)
			if self.damaged then return end

			local ply = self:GetOwner()
			if ply:IsValid() then
				local pos = self.pos

				if IsEntity(pos) and pos:IsValid() then
					pos = pos:LocalToWorld(self.lpos)
				elseif not pos or not pos:IsValid() then
					local filter = ents.FindByClass(ENT.ClassName)
					table.insert(filter, ply)
					pos = util.TraceLine({start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector()*100000, filter = filter}).HitPos
				end

				local dir = pos - phys:GetPos()
				local dist = dir:Length()
				dir:Normalize()

				local n = dist/150
				local rand_dir = Vector(math.sin(n+self.rand_dir.x), math.cos(n+self.rand_dir.y), math.sin(n+self.rand_dir.z)) * self.rand_dir*20
				rand_dir.z = math.abs(rand_dir.z)

				local vel = LerpVector(math.max(self.start_time - RealTime(), 0), dir * math.Clamp(dist / 10, 1, 30), (dir + rand_dir) * 20)
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
	if data.SoundName:find("weapons/") and data.OriginalSoundName:EndsWith(".Single") then
		local ply = data.Entity
		if not ply:IsPlayer() and not ply:IsNPC() then return end

		if ply:IsPlayer() and not ply:GetNWBool("rpg") then return end

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
	if not attacker:IsPlayer() and not attacker:IsNPC() then return end

	if attacker:IsPlayer() and not attacker:GetNWBool("rpg") then return end

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