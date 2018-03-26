AddCSLuaFile()
creatures.DEBUG = false
local ENT = {}

ENT.ClassName = "creature_base"
ENT.IsCreature = true
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Model = "models/headcrab.mdl"

do -- example behavior, override these functions
	ENT.PhysicsUpdateRate = 10
	ENT.VelocityForce = 6
	ENT.AlternateNetworking = true

	function ENT:OnSizeChanged(size)
		if CLIENT then
			local m = Matrix()
			m:Translate(Vector(0,0,-size))
			m:Scale(Vector(1,1,1) * size / self.model:GetModelRadius() * 2)
			self.model:SetLOD(8)
			self.model:EnableMatrix("RenderMultiply", m)
		end

		if SERVER then
			self:GetPhysicsObject():SetMass(size * 20)
		end
	end

	function ENT:OnUpdate(dt)
		if CLIENT then
			self.cycle = self.cycle or 0

			if self:InAir() then
				self:SetAnim("drown")
				self.cycle = self.cycle + dt
			else
				if self.Velocity:Length() > 1 then
					self:SetAnim("run1")
					self.cycle = self.cycle + self.Velocity:Length() / self:GetSize() / 90
				else
					self:SetAnim("idle01")
					self.smooth_noise = Lerp(math.Clamp(dt, 0, 1), self.smooth_noise or 0, math.Rand(-0.75, 1))*0.5

					self.cycle = self.cycle + self.smooth_noise
				end
			end

			self.cycle = self.cycle % 1
			self.model:SetCycle(self.cycle)
		end
	end

	if SERVER then
		function ENT:AvoidOthers()
			local pos = self.Position
			local radius = self:GetSize() * 1.5
			local average_pos = Vector()
			local count = 0

			for _, v in ipairs(ents.FindInSphere(pos, radius)) do
				if v.ClassName == self.ClassName and v ~= self then
					average_pos = average_pos + v.Position or v:GetPos()
					count = count + 1
				end
			end

			if count > 1 then
				average_pos = average_pos / count

				return pos - average_pos
			end
		end

		function ENT:MoveToPoint(pos)
			if not self:InAir() then
				local vel = (pos - self:GetPos())
				vel.z = 0
				local len = vel:Length()

				vel:Normalize()

				self.Physics:SetDamping(5,5)

				if true or math.random() > 0.5 then
					local avoid = self:AvoidOthers()
					if avoid then
						avoid.z = 0
						vel = vel + avoid / self:GetSize()
					end
				end

				return vel * math.min(len, self:GetSize())
			else
				self.Physics:SetDamping(0,0)
			end
		end
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Size")
end

function ENT:Initialize()
	self.trace_tbl = {}
	self.trace_tbl.output = self.trace_tbl
	self.GravityDirection = physenv.GetGravity()
	self.GravityDirection:Normalize()

	self.Time = RealTime()

	self:DrawShadow(false)

	if CLIENT then
		self.model = ClientsideModel(self.Model, RENDERGROUP_OPAQUE)
		--self.model:SetParent(self)
	end

	self:SetSize(self.DefaultSize or math.Rand(15, 25))
end

function ENT:OnRemove()
	SafeRemoveEntity(self.weld)
	SafeRemoveEntity(self.model)
end

local util_TraceHull = util.TraceHull

function ENT:RayCast(a, b, filter)
	local tbl = self.trace_tbl

	tbl.start = a
	tbl.endpos = b
	tbl.filter = self
	tbl.collisiongroup = COLLISION_GROUP_INTERACTIVE

	util_TraceHull(tbl)

	--debugoverlay.Box(tbl.StartPos, tbl.mins, tbl.maxs, 0.1, tbl.Hit and Color(0, 255, 0) or Color(255, 255, 255))
	--debugoverlay.Line(tbl.StartPos, tbl.HitPos, 0.1, tbl.Hit and Color(0, 255, 0) or Color(255, 255, 255))
	--debugoverlay.Box(tbl.HitPos, tbl.mins, tbl.maxs, 0.1, tbl.Hit and Color(0, 255, 0) or Color(255, 255, 255))

	return tbl
end

local CONTENTS_SOLID = CONTENTS_SOLID
local util_PointContents = util.PointContents

function ENT:InAir()
	if not self.next_in_air or self.next_in_air < self.Time then
		local point = self:GetPos()
		local down = self.GravityDirection---self:GetUp()
		local size = self:GetSize()

		if bit.band(util_PointContents(point + down * size + down), CONTENTS_SOLID) == CONTENTS_SOLID then
			self.in_air = false
		else
			local res = self:RayCast(point-down*size, point+down*size*0.25)

			self.in_air = not res.Hit
		end

		self.next_in_air = self.Time + 0.1
	end

	return self.in_air
end

function ENT:GetGroundTrace(distance)
	self.ground_trace_cache = self.ground_trace_cache or {}
	distance = distance or 15
	self.ground_trace_cache[distance] = self.ground_trace_cache[distance] or {}

	if self.ground_trace_cache[distance].next and self.ground_trace_cache[distance].next > self.Time then
		return self.ground_trace_cache[distance].res
	end

	local bottom = self:GetPos() + self.GravityDirection * (self:GetSize() * 1.7)

	local res = {}

	for k,v in pairs(self:RayCast(self:GetPos(), bottom + self.GravityDirection * distance)) do
		res[k] = v
	end

	self.ground_trace_cache[distance].res = res
	self.ground_trace_cache[distance].next = self.Time + 0.2

	return res
end

if CLIENT then
	local no_texture = Material("vgui/white")

	function ENT:Draw()
		if creatures.DEBUG then
			render.SetBlend(1)
			render.SetMaterial(no_texture)
			render.DrawSphere(self:GetPos(), self:GetSize(), 16, 16, self:InAir() and Color(0, 0, 255, 128) or Color(255, 0, 0, 128), true)
		end
	end

	local eyepos = Vector()
	local time = RealTime()
	hook.Add("RenderScene", "creatures_eyepos", function(eye, ang)
		eyepos = eye
		time = RealTime()
	end)

	local max_dist = 5000^2
	local LerpVector = LerpVector
	local LerpAngle = LerpAngle
	local math_max = math.max
	local math_clamp = math.Clamp
	local CurTime = CurTime

	function ENT:Think()
		self.Time = time

		if self.next_think and self.next_think > self.Time then return end

		local last_pos = self:GetPos()
		local last_ang = self:GetAngles()
		--local last_pos, last_ang = self:GetBonePosition(0)

		local fps = math_max((((last_pos - eyepos):LengthSqr() + max_dist) / max_dist) * 120, 15)

		local size = self:GetSize()

		if size ~= self.last_size then
			local tbl = self.trace_tbl
			tbl.mins = Vector(0.6,0.6,1) * -size
			tbl.maxs = Vector(0.6,0.6,0) * size

			self:OnSizeChanged(size)
			self.last_size = size
		end

		if self.AlternateNetworking then
			if not self.next_vel or self.next_vel < self.Time then
				self.Velocity = (last_pos - (self.last_pos or last_pos)) * 12
				self.last_pos = last_pos
				self.next_vel = self.Time + 1/fps*2
			end
		else
			self.Velocity = self:GetVelocity()
		end

		self.model:SetPos(last_pos)
		self.model:SetAngles(last_ang)

		if self.net_pos then
			local dt = math_clamp(FrameTime() * 15, 0.0001, 0.5)

			self:SetPos(LerpVector(dt, last_pos, self.net_pos))
			self:SetAngles(LerpAngle(dt, last_ang, self.net_ang))
		end

		local time = CurTime()
		self:OnUpdate(time - (self.last_update or time))
		self.last_update = time

		self.next_think = self.Time + 1/fps
	end

	function ENT:SetAnim(anim)
		self.model:SetSequence(self.model:LookupSequence(anim))
	end
end

if SERVER then
	function ENT:Think()
		self.Time = RealTime()

		local size = self:GetSize()
		if size ~= self.last_size then
			self:PhysicsInitSphere(size, "gmod_silent")
			self:SetCollisionBounds(Vector(-size, -size, -size), Vector(size, size, size))
			self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)

			local tbl = self.trace_tbl
			tbl.mins = Vector(0.6,0.6,1) * -size
			tbl.maxs = Vector(0.6,0.6,0) * size

			self:OnSizeChanged(size)

			self.last_size = size
		end

		local phys = self:GetPhysicsObject()

		self.Physics = phys
		self.Velocity = phys:GetVelocity()
		self.NewVelocity = Vector()
		self.VelocityLength = self.Velocity:Length()

		self.AngleVelocity = phys:GetAngleVelocity()
		self.NewAngleVelocity = Vector()
		self.AngleVelocityLength = self.AngleVelocity:Length()

		self.Position = phys:GetPos()
		self.Radius = self:BoundingRadius()

		if self.TargetPosition then
			self.NewVelocity = self:MoveToPoint(self.TargetPosition) or self.NewVelocity
		end
		self:CalcUpright()
		if self:CalcStuck() then
			self.NewVelocity = VectorRand() * self:GetSize()
		end

		phys:AddVelocity(self.NewVelocity * self.VelocityForce)
		phys:AddAngleVelocity(-self.AngleVelocity + (self.NewAngleVelocity * self.VelocityForce))

		self:CalcMoveTo()

		if not self:InAir() and self.VelocityLength < 1 then
			phys:Sleep()
		end

		self:OnUpdate()

		self:NextThink(CurTime() + 1/self.PhysicsUpdateRate)
		return true
	end

	do -- move to a point
		function ENT:MoveTo(data)
			if data.check and not data.check() then if data.fail then data.fail() end return end

			self.TargetPositions = self.TargetPositions or {}
			self.reached_target = nil
			self.target_ids = self.target_ids or {}

			data.priority = data.priority or #self.TargetPositions + 1

			if data.trace then
				if data.trace.Entity:IsValid() then
					data.trace.HitPosLocal = data.trace.Entity:WorldToLocal(data.trace.HitPos)
				end
			end

			local id = data.id
			if id and self.target_ids[id] then
				table.Merge(self.target_ids[id], data)
				for i,v in ipairs(self.TargetPositions) do
					if v.id == id then
						table.insert(self.TargetPositions, data.priority, table.remove(self.TargetPositions, i))
						break
					end
				end
				return
			end

			table.insert(self.TargetPositions, data.priority, data)

			if id then
				self.target_ids[id] = data
			end
		end

		function ENT:CalcMoveTo()
			if not self.TargetPositions then return end

			local info = self.TargetPositions[1]

			if info then
				local ok = not info.check or info.check(self)

				if ok then
					local pos = info.pos

					if info.get_pos then
						pos = info.get_pos(self)
					end

					if info.trace then
						if info.trace.Entity:IsValid() then
							pos = info.trace.Entity:LocalToWorld(info.trace.HitPosLocal)
						else
							pos = info.trace.HitPos
						end
					end

					local dir = pos - self.Position
					local len = dir:Length()

					if len > self.Radius then
						self.TargetPosition = pos
						self.reached_target = nil
						self.standing_still = nil
					elseif (self.VelocityLength < 100 and self.AngleVelocityLength < 100) then
						if info.waiting_time then
							self.standing_still_timer = self.standing_still_timer or self.Time + info.waiting_time
						end
						if not info.waiting_time or (self.standing_still_timer < self.Time) then
							self.TargetPosition = nil
							self.standing_still = true

							table.remove(self.TargetPositions, 1)

							if info.id then
								self.target_ids[info.id] = nil
							end

							self.reached_target = true

							if info.finish then
								info.finish()
							end
						end
					end
				else
					if info.fail then
						info.fail()
					end

					table.remove(self.TargetPositions, 1)

					if info.id then
						self.target_ids[info.id] = nil
					end

					self.TargetPosition = nil
					self.reached_target = true
					self.standing_still = true
				end
			end
		end

		function ENT:CancelMoving()
			self.TargetPositions = {}

			local info = self.TargetPositions[1]

			if info then
				if info.fail then info.fail() end
			end

			self.target_ids = {}
			self.TargetPosition = nil
			self.reached_target = true
			self.standing_still = true
		end
	end

	function ENT:CalcStuck()
		if not self.standing_still then
			if not self.unstuck_timer and self.VelocityLength < self:GetSize()/2 then
				if creatures.DEBUG then
					debugoverlay.Text(self.Position, "STUCK?", 0.1)
				end

				self.stuck_timer = self.stuck_timer or self.Time + math.Rand(1.5,2)

				if self.stuck_timer < self.Time then
					self.Stuck = true
					if creatures.DEBUG then
						debugoverlay.Text(self.Position, "STUCK ", 1)
					end
					self.unstuck_timer = self.unstuck_timer or self.Time + math.Rand(0.5,1)
				end
			else
				self.stuck_timer = nil
			end

			if self.unstuck_timer and self.unstuck_timer < self.Time then
				self.Stuck = false
				self.stuck_timer = nil
				self.unstuck_timer = nil

				if creatures.DEBUG then
					debugoverlay.Text(self.Position, "UNSTUCK!", 1)
				end
			end

			if self.Stuck then
				return true
			end
		else
			self.stuck_timer = nil
		end
	end

	function ENT:CalcUpright()
		local len = self.VelocityLength
		local vel = self.Velocity * 1

		if not self:InAir() then
			vel.z = 0
		end

		local desired_ang = self.DesiredAngle or vel:Angle()
		local ang = self.Physics:GetAngles()

		local p = math.AngleDifference(desired_ang.p, ang.p)/180
		local y = math.AngleDifference(desired_ang.y, ang.y)/180
		local r = math.AngleDifference(desired_ang.r, ang.r)/180

		local force = 200

		if not self:InAir() then
			force = force * math.Clamp(len-1, 0, 1)

			if force == 0 then
				self.Physics:SetAngles(Angle(0,ang.y,0))
			end
		end

		self.NewAngleVelocity = Vector(force*r, force*p, force*y)
	end
end

scripted_ents.Register(ENT, ENT.ClassName)