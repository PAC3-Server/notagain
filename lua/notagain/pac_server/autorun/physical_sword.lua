local ENT = {}

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.Spawnable = true
ENT.Category = "CapsAdmin"

function ENT:GetTipPos()
	return self:NearestPoint(self:GetPos() + self:GetUp() * self:BoundingRadius() * 2)
end

function ENT:GetHoldPos()
	return self:GetPos() + self:GetForward() * (self.charge * (self:BoundingRadius() / 2))
end

function ENT:GetLocalTipPos()
	self:WorldToLocal(self:GetTipPos())
end

function ENT:GetLocalHoldPos()
	return self:WorldToLocal(self:GetHoldPos())
end


if CLIENT then
	function ENT:Draw()
		local pos = self:GetPos()

		if self.last_pos and self.last_pos:Distance(pos) > 100 then
			self.shake = 1
		end

		if self.shake then
			self.shake = self.shake - FrameTime()*2

			if self.shake < 0 then
				self.shake = nil

				self:SetRenderAngles()
				self:DisableMatrix("RenderMultiply")
			else
				local mat = Matrix()
				mat:Rotate(Angle(math.Rand(-self.shake, self.shake), math.Rand(-self.shake, self.shake), math.Rand(-self.shake, self.shake)))
				self:EnableMatrix("RenderMultiply", mat)
			end
		end

		self:DrawModel()

		self.last_pos = pos
	end

	local function create_move(ucmd)
		local ply = LocalPlayer()

		local ok = false
		for k,v in pairs(ents.FindByClass("physical_sword")) do
			if v:GetOwner() == ply then
				ok = true
			end
		end

		if not ok then return end

		if ucmd:KeyDown(IN_ATTACK) then
			ply.prev_ang = ply.prev_ang or ucmd:GetViewAngles()

			ucmd:SetViewAngles(ply.prev_ang)
		else
			ply.prev_ang = nil
		end
	end

	local ref = 0

	function ENT:Initialize()
		self.wind_snd = CreateSound(self, "weapons/tripwire/ropeshoot.wav")
		self.wind_snd:Play()

		ref = ref + 1
		hook.Add("CreateMove", "physical_sword", create_move)
	end

	function ENT:Think()
		local len = self:GetVelocity():Length()
		self.wind_snd:ChangePitch(math.Clamp(len/10, 50, 255), 0)
		self.wind_snd:ChangeVolume(math.Clamp((len/1000) ^ 2, 0, 1), 0)
	end

	function ENT:OnRemove()
		self.wind_snd:Stop()
		ref = ref - 1
		if ref == 0 then
			hook.Remove("CreateMove", "physical_sword")
		end
	end
end

if SERVER then
	local models =
	{
		"models/props_junk/harpoon002a.mdl",
		"models/props_junk/iBeam01a_cluster01.mdl",
		"models/mechanics/solid_steel/i_beam2_32.mdl",
		"models/mechanics/solid_steel/i_beam2_48.mdl",
		"models/mechanics/solid_steel/i_beam2_60.mdl",
		"models/mechanics/solid_steel/i_beam_48.mdl",
		"models/mechanics/solid_steel/i_beam_32.mdl",
	}

	local function move(ply, mov)
		local cmd = ply:GetCurrentCommand()

		ply.ps_mousevel = Angle(cmd:GetMouseY(), -cmd:GetMouseX(), 0) * 0.05
	end

	local ref = 0

	function ENT:Initialize()
		self:SetModel("models/props_c17/signpole001.mdl")--table.Random(models))

		self:PhysicsInit(SOLID_VPHYSICS)
		self:StartMotionController()
		self:GetPhysicsObject():SetMass(50)
		self:GetPhysicsObject():SetMaterial("jeeptire")

		ref = ref + 1
		hook.Add("Move", "physical_sword", move)
	end

	function ENT:OnRemove()
		self:Drop()

		ref = ref - 1

		if ref == 0 then
			hook.Remove("Move", "physical_sword")
		end
	end

	function ENT:Think()
		self:PhysWake()

		local parent = self:GetParent()

		if parent:IsValid() and parent:IsPlayer() and not parent:Alive() then
			self:SetParent()
			self:SetMoveType(MOVETYPE_VPHYSICS)
		end

		local owner = self:GetOwner()

		if not owner:IsValid() then return end

		if not owner:Alive() then
			self:Drop()
		end

		if self.drop_delay then
			self:SetPhysicsAttacker(owner)

			if self.drop_delay < SysTime() then
				self:Drop()
			end
		end
	end

	ENT.charge = 0

	function ENT:GetSwordPos()
		local owner = self:GetOwner()
		local id = owner:LookupBone("ValveBiped.Bip01_R_Hand")
		local pos = id and owner:GetBonePosition(id) or owner:EyePos()
		local ang = owner:EyeAngles()

		local ang_offset

		if owner:KeyDown(IN_ATTACK) then
			ang_offset = Angle(90 + -45,0,0)

			owner.ps_eyeang.p = math.Clamp(owner.ps_eyeang.p, ang.p - 90, ang.p + 90)
			owner.ps_eyeang.y = math.Clamp(owner.ps_eyeang.y, ang.y - 90, ang.y + 90)

			ang = owner.ps_eyeang
		else
			owner.ps_eyeang = ang
			ang_offset = Angle(90, 0, 0)
		end

		return LocalToWorld(-self:GetLocalHoldPos(), ang_offset, pos, ang)
	end

	function ENT:Use(ent)
		if self:GetOwner():IsValid() then return end

		self:SetParent()

		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetOwner(ent)

		ent.physical_sword = self
	end

	function ENT:Drop(seconds)
		if seconds then
			self.drop_delay = SysTime() + seconds
			return
		end

		self:SetOwner(NULL)
		self.charge = 0
		self.drop_delay = nil

		local owner = self:GetOwner()
		if owner:IsValid() then
			owner.physical_sword = NULL
		end
	end

	local params = {}
	params.teleportdistance = 200

	params.maxspeed = 1000000
	params.maxangular = 1000000

	params.maxspeeddamp = 1000000
	params.maxangulardamp = 1000000

	params.dampfactor = 0.4
	params.secondstoarrive = 0.01

	function ENT:StartTouch(ent)
		if ent:GetClass() ~= self:GetClass() then return end

		self.scrape_sound = self.scrape_sound or CreateSound(self, "physics/metal/canister_scrape_smooth_loop1.wav")
		self.scrape_sound:Play()
	end

	function ENT:Touch(ent)
		if ent:GetClass() ~= self:GetClass() then return end

		local phys = ent:GetPhysicsObject()
		local energy = phys:GetEnergy()
		energy = energy / 2000000

		if energy == 0 then energy = 255 end

		self.scrape_sound:ChangePitch(math.Clamp(energy+50, 0, 255), 0)
		self.scrape_sound:ChangeVolume(math.Clamp(energy / 10, 0, 1), 0)
	end

	function ENT:EndTouch(ent)
		if ent:GetClass() ~= self:GetClass() then return end

		self.scrape_sound = self.scrape_sound or CreateSound(self, "physics/metal/canister_scrape_smooth_loop1.wav")
		self.scrape_sound:Stop()
	end

	function ENT:PhysicsCollide(data)
		local ent = data.HitEntity

		local len = data.OurOldVelocity:Length()

		if ent:GetClass() ~= self:GetClass() and false then
			if len < 50 and len > 20 then
				self:EmitSound("physics/metal/metal_canister_impact_soft"..math.random(3)..".wav", len/4, math.random(200, 240))
			else
				self:EmitSound("physics/metal/metal_canister_impact_hard"..math.random(3)..".wav", len/10, math.random(200, 240))
			end
		end

		if
			ent:GetClass() == self:GetClass() or
			data.HitNormal:Distance(self:GetUp()) > 1 or
			len < 400 or
			data.HitPos:Distance(self:GetTipPos()) > 50
		then
		return end

		if ent:IsPlayer() then
			self:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav", 100, math.random(150, 200))

			local ef = EffectData()
			ef:SetOrigin(data.HitPos)
			util.Effect("BloodImpact", ef)
		end

		if not self:GetOwner():IsValid() or self.drop_delay then
			self:SetPos(data.HitPos + self:GetUp() * -self:BoundingRadius()*2)

			if ent:IsValid() then
				self:SetParent(ent)
			else
				self:SetMoveType(MOVETYPE_NONE)
			end

			self:EmitSound("physics/metal/sawblade_stick"..math.random(3)..".wav", 100, math.random(70, 80))
			self:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav", 100, math.random(150, 200))

			local ef = EffectData()
			ef:SetOrigin(data.HitPos)
			ef:SetMagnitude(1)
			ef:SetScale(1)
			util.Effect("Sparks", ef)
		end
	end

	function ENT:PhysicsSimulate(phys, delta)
		--phys:SetMass(200)
		--phys:SetDamping(0)
		phys:ApplyForceOffset(phys:GetVelocity()*1.1, self:GetTipPos())
		phys:AddAngleVelocity(phys:GetAngleVelocity() * -0.1)

		local owner = self:GetOwner()

		if not owner:IsValid() or self.drop_delay then return end

		owner.ps_eyeang = (owner.ps_eyeang or Angle()) + owner.ps_mousevel
		owner.current_charging = owner.current_charging or NULL

		if not owner:KeyDown(IN_ATTACK2) and self.charge > 0 then
			phys:SetVelocity(phys:GetAngles():Up() * phys:GetMass() * self.charge * 50 * delta * 50)
			self:Drop(1)
			owner.current_charging = NULL
			return
		end

		if owner:KeyDown(IN_ATTACK2) and (not owner.current_charging:IsValid() or owner.current_charging == self) then
			self.charge = math.Clamp(self.charge + delta * 5, 0, 1)
			owner.current_charging = self
		end


		local pos, ang = self:GetSwordPos()
			params.deltatime = delta
			params.pos = pos
			params.angle = ang
		phys:ComputeShadowControl(params)

		--ang = self:GetAngles()
		--ang.r = 0
		--owner:SetEyeAngles(ang)
	end
end

scripted_ents.Register(ENT, "physical_sword", true)
