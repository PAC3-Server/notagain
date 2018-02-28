local ENT = {}

ENT.ClassName = "mount_base"
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.PrintName = "seagull mount"
ENT.Model = "models/seagull.mdl"

local mins = Vector(-1.75, -0.5, 0) * 5
local maxs = Vector(0.75, 0.5, 1.5) * 5

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "WingFlap" )
end

function ENT:UpdateSeatPosition()
	local seat = self.seat or NULL
	if seat:IsValid() then
		local pos = self:GetPos()
		local ang = self:GetAngles()
		pos = pos + ang:Up() * 30
		pos = pos + ang:Forward() * -10
		seat:SetPos(pos)
		ang:RotateAroundAxis(self:GetUp(), -90)
		seat:SetAngles(ang)

		if CLIENT then
			seat:SetupBones()
		end
	end
end

if CLIENT then
	function ENT:OnRemove()
		self.FlapSound:Stop()
		self.WindSound:Stop()
	end

	function ENT:DrawHitBoxes()
		local s = self:GetModelScale()
		local color_debug = self:InAir() and Color(0, 0, 255, 128) or Color(255, 0, 0, 128)
		debugoverlay.BoxAngles(self:GetPos(), mins*s, maxs*s, self:GetAngles(), 0, color_debug)
	end

	function ENT:Draw()
		self:AnimationThink()
		if not self:InAir() then
			local ang = self:GetAngles()
			local dot = ang:Right():Dot(self:GetVelocity())
			self:ManipulateBoneAngles(0, Angle(0,0,dot*0.1))
		else
			self:ManipulateBoneAngles(0, Angle(0,0,0))
		end
		self:DrawModel()
		self:UpdateSeatPosition()
		self:DrawHitBoxes()
	end

	function ENT:GetPlayerPosAng()
		local m = self:GetBoneMatrix(self:LookupBone("seagull.pelvis"))
		if not m then return self:GetPos(), self:GetAngles() end
		local pos, ang = m:GetTranslation(), m:GetAngles()
		ang:RotateAroundAxis(ang:Forward(), -90)
		pos = pos + ang:Up()*15
		return pos, ang
	end

	function ENT:PrePlayerDraw(ply)
		local pos, ang = self:GetPlayerPosAng()

		ply:SetRenderOrigin(pos)
		ply:SetPos(pos)
		ply:SetRenderAngles(ang)

		if false then
		local bone = ply:LookupBone("ValveBiped.Bip01_Spine")
		if bone then
			local ang = self:GetAngles()
			ply:ManipulateBoneAngles(bone, Angle(-ang.r,-ang.p,0))
		end
		local bone_r = ply:LookupBone("ValveBiped.Bip01_R_Thigh")
		if bone_r then
			ply:ManipulateBoneAngles(bone_r, Angle(25,0,0))
		end
		local bone_l = ply:LookupBone("ValveBiped.Bip01_L_Thigh")
		if bone_l then
			ply:ManipulateBoneAngles(bone_l, Angle(-25,0,0))
		end
		end
		local wep = ply:GetActiveWeapon()
		if wep:IsValid() then
			wep:SetupBones()
		end
		ply:SetupBones()
	end

	function ENT:CalcView(ply, origin, angles)
		--if os.clock()%0.1 < 0.05 then return end
		local pos, ang = self:GetPlayerPosAng()
		--angles.r = ang.r
		return {
			origin = pos + self:GetUp()*12 + self:GetForward()*3,
			angles = angles,
		}
	end

	hook.Add("PrePlayerDraw", ENT.ClassName, function(ply)
		local veh = ply:GetVehicle()
		if veh:IsValid() then
			local self = veh:GetNW2Entity("mount")
			if self:IsValid() and self:GetClass() == ENT.ClassName then
				return self:PrePlayerDraw(ply)
			end
		end
	end)

	hook.Add("CalcView", ENT.ClassName, function(ply, origin, angles)
			do return end
		local veh = ply:GetVehicle()
		if veh:IsValid() then
			local self = veh:GetNW2Entity("mount")
			if self:IsValid() and self:GetClass() == ENT.ClassName then
				return self:CalcView(ply, origin, angles)
			end
		end
	end)

	hook.Remove("CalcViewModelView", ENT.ClassName)
end

function ENT:SetSize2(scale)
	self:SetModelScale(scale)

	local mins = mins * scale
	local maxs = maxs * scale

	self:SetCollisionBounds(mins, maxs)
	self.PhysCollide = CreatePhysCollideBox(mins, maxs)

	if SERVER then
		self:PhysicsInitBox(mins, maxs)
		self:SetSolid(SOLID_VPHYSICS)
		self:StartMotionController()

		local seat = ents.Create( "prop_vehicle_prisoner_pod" )
		seat:SetModel( "models/nova/jeep_seat.mdl")
		seat:Spawn()
		seat:Activate()
		seat:SetNoDraw(true)
		seat:SetNW2Entity("mount", self)
		seat:SetNW2Entity("seat", seat)
		self:CallOnRemove("mount", function() SafeRemoveEntity(seat) end)
		seat:SetMoveType(MOVETYPE_NONE)
		seat:SetSolid(SOLID_NONE)

		self.seat = seat

		self:GetPhysicsObject():SetMaterial("gmod_ice")
	end

	self:EnableCustomCollisions( true )
	self:DrawShadow( false )
end

function ENT:Initialize()
	self:SetModel(self.Model)

	self:SetSize2(6)

	if CLIENT then
		self:SetLOD(0)

		self.FlapSound = CreateSound(self, "ambient/wind/windgust_strong.wav")
		self.WindSound = CreateSound(self, "vehicles/fast_windloop1.wav")
		self.FlapSound:Play()
		--self.WindSound:Play()
	end
end

function ENT:TestCollision( startpos, delta, isbox, extents )
	if not IsValid(self.PhysCollide) then
		return
	end

	-- TraceBox expects the trace to begin at the center of the box, but TestCollision is bad
	local max = extents
	local min = -extents
	max.z = max.z - min.z
	min.z = 0

	local hit, norm, frac = self.PhysCollide:TraceBox( self:GetPos(), self:GetAngles(), startpos, startpos + delta, min, max )

	if not hit then
		return
	end

	return {
		HitPos = hit,
		Normal = norm,
		Fraction = frac,
	}
end

function ENT:InAir()
	return not self:GetGroundTrace().Hit
end

function ENT:GetGroundTrace(distance)
	distance = distance or 20
	local gravity_dir = physenv.GetGravity():GetNormalized()
	local bottom = self:NearestPoint(self:GetPos() + gravity_dir * self:BoundingRadius() * 2)
	local info = {
		start = self:GetPos(),
		endpos =  bottom + gravity_dir * distance,
		filter = {self, self:GetNW2Entity("seat")},
	}

	local res = util.TraceLine(info)
	debugoverlay.Line(bottom, res.HitPos, 0, nil, true)

	return res
end

do -- calc
	ENT.Cycle = 0
	ENT.Noise = 0


	ENT.Animations = {
		Fly = "Fly",
		Run = "run",
		Walk = "walk",
		Idle = "idle01",
		Soar = "soar",
		Land = "land",
		Takeoff = "takeoff",
	}

	function ENT:SetAnim(anim)
		self:SetSequence(self:LookupSequence(self.Animations[anim]))
	end

	function ENT:AnimationThink()
		local scale = self:GetModelScale()

		local vel = self:GetVelocity() / scale
		local len = vel:Length()
		local ang = vel:Angle()
		local siz = scale*150
		len = len / siz

		if not self:InAir() then
			self.takeoff = false

			if len < 3 / siz then
				self:SetAnim("Idle")
				len = 15 / siz * (self.Noise * 2)
			else
				if CLIENT then
					self:StepSoundThink()
				end

				if len > 50 / siz then
					self:SetAnim("Run")
				else
					self:SetAnim("Walk")
				end
			end

			self.Noise = (self.Noise + (math.Rand(-1,1) - self.Noise) * FrameTime())

			self.Cycle = (self.Cycle + (len / (21 / siz)) * FrameTime() * math.Clamp(self:GetForward():Dot(vel), -1, 1)) % 1
			self:SetCycle(self.Cycle)

			if CLIENT then
				self.FlapSound:ChangeVolume(0)
				self.WindSound:ChangeVolume(0)
			end
		else

			local ground = self:GetGroundTrace(200)

			if ground.Fraction < 1 then
				local f = ground.Fraction
				if vel.z > 0 then
					if not self.takeoff then
						self:SetAnim("Takeoff")
						f = Lerp(f, 0.3, 0.4)
					end
				else
					f = Lerp(f, 0.5, 0.8)
					self:SetAnim("Land")
				end

				self:SetCycle(f)

				if CLIENT then
					self:SetupBones()
				end
				return
			else
				self.takeoff = true
			end


			local rate = 10
			if math.abs(vel.z) < 10 then
				rate = vel:Length2D()/100
				self:SetAnim("Soar")
				self.Cycle = math.random()
			else
				self:SetAnim("Fly")

				local c = self:GetWingFlap()

				if c ~= 0 then
					self.Cycle = c + 0.15
				else
					self.Cycle = Lerp(math.Clamp((-vel.z/200), 0, 1), 0.2, 1)
				end
			end

			self.smooth_cycle = self.smooth_cycle or 0
			self.smooth_cycle = self.smooth_cycle + ((self.Cycle - self.smooth_cycle) * FrameTime() * rate)

			if self.smooth_cycle > 10 then self.smooth_cycle = 0 end

			if CLIENT then
				local RoundedZ = self.smooth_cycle*100

				self.FlapSound:ChangePitch(math.Clamp(RoundedZ/2, 50, 100))
				self.FlapSound:ChangeVolume(math.Clamp(RoundedZ/80, 0, 1))

				self.WindSound:ChangePitch(100)
				self.WindSound:ChangeVolume(self:GetVelocity():Length() / 2000)
			end


			self:SetCycle(self.smooth_cycle)
		end

		if CLIENT then
			self:SetupBones()
		end
	end

	function ENT:StepSoundThink()
		local siz = self:GetModelScale()
		local stepped = self.Cycle%0.5
		if stepped  < 0.3 then
			if not self.stepped then
				sound.Play(
					"npc/fast_zombie/foot2.wav",
					self:GetPos(),
					math.Clamp(10 * siz, 70, 160) + math.Rand(-5,5),
					math.Clamp(100 / (siz/3), 40, 200) + math.Rand(-10,10)
				)
				self.stepped = true
			end
		else
			self.stepped = false
		end
	end
end

if SERVER then
	function ENT:OnTakeDamage(info)
		print(info:GetDamage(), info:GetAttacker())
	end

	function ENT:Think()
		local scale = self:GetModelScale()
		self:PhysWake()
		self:AnimationThink(self:GetVelocity() / scale, self:GetVelocity():Length(), self:GetAngles())

		local driver = self.seat and self.seat:GetDriver()

		if driver:IsValid() then
			local dir = Vector()

			self.aim_dir = false

			if not self:InAir() then
				if driver:KeyDown(IN_FORWARD) then
					dir = driver:GetAimVector()
					self.aim_dir = true
				elseif driver:KeyDown(IN_BACK) then
					dir = -self:GetForward()
				end
			end

			if driver:KeyDown(IN_MOVELEFT) then
				dir = dir + -driver:EyeAngles():Right()
				self.aim_dir = true
			elseif driver:KeyDown(IN_MOVERIGHT) then
				dir = dir + driver:EyeAngles():Right()
				self.aim_dir = true
			end


			if dir then
				dir:Normalize()
				if not self:InAir() then
					dir.z = self:GetForward().z
				end
				dir = dir * 10
				if driver:KeyDown(IN_SPEED) then
					dir = dir * 2
				end
			end

			if driver:KeyDown(IN_JUMP) then
				self.flap_wing = self.flap_wing or 0
			end

			self.direction = dir
		end
	end

	function ENT:PhysicsUpdate(phys)
		self:UpdateSeatPosition()

		if self.flap_wing then
			self.flap_wing = self.flap_wing + FrameTime() * 1
			self:SetWingFlap(self.flap_wing)

			phys:AddVelocity((self:GetUp()+self:GetForward()) * self.flap_wing*30)
			--phys:AddAngleVelocity(Vector(0,3000,0))

			if self.flap_wing >= 1 then
				self:SetWingFlap(0)
				self.flap_wing = nil
			end
		end

		phys:Wake()

		local driver = self.seat:GetDriver()

		if self:InAir() then
			self.efficiency = 10
			self.pln = 1

			local curvel = phys:GetVelocity()
			local curup = self:GetUp()


			local vec1 = curvel
			local vec2 = curup
			vec1 = vec1 - 2*(vec1:Dot(vec2))*vec2
			local sped = vec1:Length()

			local finalvec = curvel
			local modf = math.abs(curup:DotProduct(curvel:GetNormalized()))
			local nvec = (curup:DotProduct(curvel:GetNormalized()))

			if nvec > 0 then
				vec1 = vec1 + (curup * 10)
			else
				vec1 = vec1 + (curup * -10)
			end

			finalvec = vec1:GetNormalized() * (math.pow(sped, modf) - 1)
			finalvec = finalvec:GetNormalized()
			finalvec = (finalvec * self.efficiency) + curvel

			local liftmul = 1 - math.abs(nvec)
			finalvec = finalvec + (curup * liftmul * curvel:Length() * self.efficiency) / 700
			finalvec = finalvec:GetNormalized()
			finalvec = finalvec * curvel:Length()

			phys:SetVelocity(finalvec)
		else
			if driver:IsValid() and self.direction then
				phys:AddVelocity(self.direction)
			end
		end

		-- Get angle difference of the prop and up right and facing away from the camera
		local vel = phys:GetVelocity()
		local default_angle = phys:GetAngles()
		default_angle.p = 0
		local desired_ang = (self:InAir() or self.aim_dir) and vel:Angle() or default_angle

		local ang = self:GetAngles()


		local p = -math.AngleDifference( desired_ang.p, ang.p)
		local y = -math.AngleDifference( desired_ang.y, ang.y)
		local r = -math.AngleDifference( desired_ang.r, ang.r)

		local mult = math.Clamp((vel:Length()/1000) - 0.1, 0, 1)
		local force = self:InAir() and 1 or 3
		if vel:Length() > 5 or math.abs(math.NormalizeAngle(ang.r)) > 70 then
			local z = 0
			local roll = 0
			if driver:IsValid() then
				if driver:KeyDown(IN_FORWARD) then
					z = -1
				elseif driver:KeyDown(IN_BACK) then
					z = 1
				end

				if driver:KeyDown(IN_MOVELEFT) then
					roll = 1
				elseif driver:KeyDown(IN_MOVERIGHT) then
					roll = -1
				end
			end

			roll = roll * vel:Length()/15
			z = z * vel:Length()/15

			if driver:IsValid() and driver:KeyDown(IN_SPEED) then
				roll = roll * 2
				z = z * 2
			end

			phys:AddAngleVelocity(-phys:GetAngleVelocity() - Vector(force*r + roll, force*p + z, force*y))
		end

		-- damping

		if not self:InAir() then
			phys:AddAngleVelocity(-phys:GetAngleVelocity() * 0.05)
			local vel = phys:GetVelocity()
			vel.z = 0
			phys:AddVelocity(-vel * 0.05)
		end
	end

	function ENT:OnEnter(ply)
		self:SetOwner(ply)
		self.seat:SetOwner(ply)
		self.player_allow_weapons = ply:GetAllowWeaponsInVehicle()
		ply:SetAllowWeaponsInVehicle(true)
		ply:EnterVehicle(self.seat)
	end

	function ENT:OnExit(ply)
		self:SetOwner(NULL)
		self.seat:SetOwner(NULL)
		if self.player_allow_weapons ~= nil then
			ply:SetAllowWeaponsInVehicle(self.player_allow_weapons)
			self.player_allow_weapons = nil
		end

		self.suppress_use = os.clock() + 0.25
	end

	function ENT:Use(ply)
		if self.suppress_use and self.suppress_use > os.clock() then return end
		if ply.EnterVehicle and not ply:GetVehicle():IsValid() then
			self:OnEnter(ply)
		end
	end

	hook.Add("PlayerLeaveVehicle", ENT.ClassName, function(ply, veh)
		local self = veh:GetNW2Entity("mount")
		if self:IsValid() and self:GetClass() == ENT.ClassName then
			self:OnExit(ply)
		end
	end)
end

scripted_ents.Register(ENT, ENT.ClassName, true)