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
			self:SetModelScale(self.bullet_info.Damage)
		end

		if CLIENT then
			local snd = CreateSound(self, "physics/cardboard/cardboard_box_scrape_smooth_loop1.wav")
			snd:Play()
			snd:ChangeVolume(1)
			self.loop_snd = snd

			self.pixvis = util.GetPixelVisibleHandle()
			self.damage_types = self:GetDamageTypes():Split(",")
			if not self.damage_types[1] then
				table.insert(self.damage_types, "generic")
			end
		end
	end

	function ENT:Damage()
		local pos = self:GetCollisionPoint()
		local normal = self:GetCollisionNormal()
		local ent = self:GetCollisionEntity()

		if CLIENT then
			self.loop_snd:Stop()
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
				local pitch = self:GetVelocity():Length()/200
				pitch = pitch ^ 2
				if self.loop_snd then
					self.loop_snd:ChangePitch(math.Clamp(100 + pitch, 0, 255))
				end
			end

			if self:GetCollisionPoint() ~= vector_origin and not self.damaged then
				self:Damage()
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

			if self:GetLocalPos():Distance(EyePos()) < 40 then
--				local posang = self:GetOwner():GetViewModel():GetAttachment(1)

				--self:SetRenderOrigin(posang.Pos)
			else
				--self:SetRenderOrigin()
			end

			for _, name in ipairs(self.damage_types) do
				if jdmg.types[name] and jdmg.types[name].draw_projectile then
					jdmg.types[name].draw_projectile(self, math.max(self:GetModelScale(), 50))
				end
			end
		end

		function ENT:OnRemove()
			self.loop_snd:Stop()
		end
	end

	if SERVER then
		function ENT:SetBulletData(attacker, data)
			self:SetOwner(attacker)
			local wep = attacker:GetActiveWeapon()

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
				self:Damage()
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

				local vel = LerpVector(math.max(self.start_time - RealTime(), 0), dir * dist / 10, (dir + rand_dir) * 20)
				vel = vel + phys:GetVelocity() * -delta*3 * self.damp

				phys:AddVelocity(vel)
			end
		end
	end

	scripted_ents.Register(ENT, ENT.ClassName)
end

hook.Add("EntityFireBullets", "jprojectiles", function(attacker, data)
	if suppress then return end
	if not attacker:IsPlayer() and not attacker:IsNPC() then return end

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