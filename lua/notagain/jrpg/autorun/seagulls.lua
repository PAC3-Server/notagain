local DEBUG = false
local DEBUG2 = true

local ENT = {}

ENT.ClassName = "monster_seagull"
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.PrintName = "seagull mount"
ENT.Model = "models/seagull.mdl"

function ENT:GetScale()
	return self:GetNW2Float("scale", 1)
end

if CLIENT then
	local no_texture = Material("vgui/white")

	function ENT:Draw()
		if DEBUG then
			render.SetMaterial(no_texture)
			render.DrawSphere(self:GetPos(), self:GetScale(), 8, 8, self:InAir() and Color(0, 0, 255, 128) or Color(255, 0, 0, 128))
		end
		self.csmodel:SetLocalPos(self.local_pos)
	end

	function ENT:Think()
		self:AnimationThink()
		self:NextThink(CurTime())
		return true
	end
end

function ENT:SetSize2(scale)
	self:SetNW2Float("scale", scale)

	if SERVER then
		self:PhysicsInitSphere(scale, "gmod_ice")
		self:GetPhysicsObject():SetMass(scale * 20)
		self:SetCollisionBounds( Vector( -scale, -scale, -scale ) , Vector( scale, scale, scale ) )
	end

	--self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)

	self:DrawShadow( false )
end

function ENT:SetModel2(mdl)
	self:SetNW2String("model", mdl)
end

function ENT:StartTouch(ent)
	print("START TOUCH", ent)
end

function ENT:EndTouch(ent)
	print("END TOUCH", ent)
end

function ENT:Initialize()

	self:SetSize2(math.Rand(5,10))
	self:SetModel2(self.Model)

	if SERVER then
		self:SetTrigger(true)
	end

	if CLIENT then
		self.csmodel = ClientsideModel(self:GetNW2String("model"))
		self.csmodel:SetParent(self)
		self.local_pos = Vector(0, 0, -self:BoundingRadius()/2 - (self:GetScale()/10) - 1)
		self.csmodel:SetLocalPos(self.local_pos)
		self.csmodel:SetModelScale(self:GetScale() / self.csmodel:GetModelRadius() * 6)
		self.csmodel:SetLOD(0)
		local s = self:GetScale()
		self.csmodel:SetColor(Color(255, 255, Lerp(s/20, 100, 255), 255))
	end

	self.ground_trace_cache = {}
	self.standing_still = true
end


function ENT:InAir()
	if not self.next_in_air or self.next_in_air < RealTime() then
		local point = self:GetPos()
		local down = -self:GetUp()

		if bit.band(util.PointContents(point + down * self:BoundingRadius()), CONTENTS_SOLID ) == CONTENTS_SOLID then
			self.in_air = false
		else
			point = point + down

			self.tr_out = self.tr_out or {}
			self.tr_in = self.tr_in or {output = self.tr_out}

			self.tr_in.start = point
			self.tr_in.endpos = point

			util.TraceEntity(self.tr_in, self)

			if self.tr_out.Entity.ClassName == ENT.ClassName then
				self.tr_out.Hit = false
			end

			self.in_air = not self.tr_out.Hit
		end

		self.next_in_air = RealTime() + 0.1
	end

	return self.in_air
end

function ENT:GetGroundTrace(distance)
	distance = distance or 15
	self.ground_trace_cache[distance] = self.ground_trace_cache[distance] or {}

	if self.ground_trace_cache[distance].next and self.ground_trace_cache[distance].next > RealTime() then
		return self.ground_trace_cache[distance].res
	end

	local gravity_dir = physenv.GetGravity():GetNormalized()
	local bottom = self:NearestPoint(self:GetPos() + gravity_dir * self:BoundingRadius() * 2)
	local info = {
		start = self:GetPos(),
		endpos =  bottom + gravity_dir * distance,
		filter = {self},
	}

	local res = util.TraceLine(info)

	--debugoverlay.Line(bottom, res.HitPos, 0, nil, true)

	self.ground_trace_cache[distance].res = res
	self.ground_trace_cache[distance].next = RealTime() + 0.2

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
		self.csmodel:SetSequence(self.csmodel:LookupSequence(self.Animations[anim]))
	end

	function ENT:AnimationThink()
		local scale = self:GetScale()

		local vel = self:GetVelocity() / scale
		local len = vel:Length()
		local ang = vel:Angle()
		local siz = scale*0.05
		len = len / siz

		if not self:InAir() then
			self.takeoff = false

			local mult = 1

			if len < 1 / siz then
				self:SetAnim("Idle")
				len = 15 / siz * (self.Noise * 0.25)
			else
				if CLIENT then
					self:StepSoundThink()
				end

				if len > 50 / siz then
					self:SetAnim("Run")
				else
					self:SetAnim("Walk")
				end
				mult = math.Clamp(self:GetForward():Dot(vel), -1, 1)
			end

			self.Noise = (self.Noise + (math.Rand(-1,1) - self.Noise) * FrameTime())
			self.Cycle = (self.Cycle + (len / (2.5 / siz)) * FrameTime() * mult) % 1
			self.csmodel:SetCycle(self.Cycle)
		else

			local ground = self:GetGroundTrace(self:BoundingRadius() - 4)

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

				self.csmodel:SetCycle(f)
				return
			else
				self.takeoff = true
			end

			if len < 50 then
				self:SetAnim("Fly")
				self.Cycle = self.Cycle + FrameTime() * 3.5 * (math.Rand(1, 1.1))
			else

				local fvel = self:GetRight():Dot(self:GetVelocity())
				if math.abs(fvel) > 50 then
					self:SetAnim("Fly")
					self.Cycle = self.Cycle + FrameTime() * 0.5 * (math.Rand(1, 1.1))
				else

					if vel.z < 0 then
						self:SetAnim("Soar")
						self.Cycle = math.random()
					else
						self:SetAnim("Fly")

						if vel.z > 0 then
							self.Cycle = self.Cycle + FrameTime() * 2
						else
							self.Cycle = Lerp(math.Clamp((-vel.z/100), 0, 1), 0.1, 1)
						end
					end
				end
			end

			self.csmodel:SetCycle(self.Cycle)
		end
	end

	if CLIENT then
		local sounds = {
			"npc/fast_zombie/foot2.wav",
		}
		for i = 1, 5 do
			sounds[i] = "seagull_step_" .. i .. "_" .. util.CRC(os.clock())
			sound.Generate(sounds[i], 22050, 0.25, function(t)
				local f = (t/22050) * (1/0.25)
				f = -f + 1
				f = f ^ 10
				return ((math.random()*2-1) * math.sin(t*1005) * math.cos(t*0.18)) * f
			end)
		end
		function ENT:StepSoundThink() do return end
			local siz = self:GetScale()
			local stepped = self.Cycle%0.5
			if stepped  < 0.3 then
				if not self.stepped then
					--[[sound.Play(
						table.Random(sounds),
						self:GetPos(),
						math.Clamp(10 * siz, 70, 160),
						math.Clamp(100 / (siz/3) + math.Rand(-20,20), 40, 255)
					)]]



					EmitSound(
						table.Random(sounds),
						self:GetPos(),
						self:EntIndex(),
						CHAN_AUTO,
						1,
						--math.Clamp(10 * siz, 70, 160),
						55,
						0,
						--math.Clamp(100 / (siz/3) + math.Rand(-20,20), 40, 255)
						100/siz + math.Rand(-15, 15)
					)

					self.stepped = true
				end
			else
				self.stepped = false
			end
		end
	end
end

if SERVER then
	local temp_vec = Vector()
	local function VectorTemp(x,y,z)
		temp_vec.x = x
		temp_vec.y = y
		temp_vec.z = z
		return temp_vec
	end

	local flock_radius = 2000

	local flock_pos
	local food_pos
	local flock_vel = Vector()
	local food = {}
	local tallest_points = {}
	local all_seagulls

	timer.Create(ENT.ClassName, 0, 0.1, function()
		all_seagulls = ents.FindByClass(ENT.ClassName)

		if DEBUG2 then
			if me:KeyDown(IN_RELOAD) then
				for i,v in ipairs(all_seagulls) do
					v:Remove()
				end
			end
		end

		local found = all_seagulls
		local count = #found
		local pos = VectorTemp(0,0,0)

		for _, ent in ipairs(found) do
			local p = ent:GetPos()
			pos = pos + p
		end

		if count > 1 then
			local pos = pos / count

			flock_vel = (flock_pos or pos) - pos

			flock_pos = pos

			if DEBUG then
				debugoverlay.Sphere(pos, flock_radius, 0, Color(0, 255, 0, 5))
				if me:KeyDown(IN_JUMP) then
					tallest_points = {}
				end
			end


			local up = physenv.GetGravity():GetNormalized()
			local top = util.QuickTrace(pos, up*-10000).HitPos
			local bottom = util.QuickTrace(top, up*10000).HitPos

			top.z = math.min(flock_pos.z + flock_radius, top.z)

			local bias = Vector()
			local count = 0
			for i = 1, 5 do
				local p = tallest_points[i]
				if not p then break end
				bias = bias + p
				count = count + 1
			end
			if count > 1 then
				bias = bias / count
			end

			local max = 3

			for i = 1, max do
				local start_pos = LerpVector(i/max, bottom, top)

				if DBEUG then
					debugoverlay.Cross(start_pos,100, 0.1)
				end
				--if not util.IsInWorld(start_pos) then break end
				local bias = count > 1 and (pos - bias):GetNormalized() or up
				local tr = util.TraceLine({
					start = start_pos,
					endpos = start_pos + VectorTemp(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(-1, -0.2))*flock_radius,
				})

				if tr.Hit and math.abs(tr.HitNormal.z) > 0.8 and (not tr.Entity:IsValid() or tr.Entity.ClassName ~= ENT.ClassName) then
					if tr.HitPos.z > flock_pos.z then
						for i,v in ipairs(tallest_points) do
							if v:Distance(tr.HitPos) < 50 then
								return
							end
						end

						table.insert(tallest_points, tr.HitPos)

						table.sort(tallest_points, function(a, b) return a.z > b.z end)

						if #tallest_points > 50 then
							table.remove(tallest_points, 50)
						end

						if DEBUG then
							for i,v in ipairs(tallest_points) do
								debugoverlay.Cross(v, 5, 0.1, Color(0,0,255, 255))
							end
						end
					end
				else
					if DEBUG then
						debugoverlay.Line(tr.StartPos, tr.HitPos, 0.1, Color(255,255,255, 1))
					end
				end
			end

			for i = #tallest_points, 1, -1 do
				local v = tallest_points[i]
				if v:Distance(flock_pos) > flock_radius then
					table.remove(tallest_points, i)
				end
			end
		else
			flock_pos = nil
		end

		food = {}
		for _, ent in ipairs(ents.GetAll()) do
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() and (
				phys:GetMaterial():lower():find("flesh") or
				phys:GetMaterial() == "watermelon" or
				phys:GetMaterial() == "antlion"
			) then
				table.insert(food, ent)
			end
		end
	end)

	function ENT:OnTakeDamage(info)
		print(info:GetDamage(), info:GetAttacker())
	end

	function ENT:Think()
		if DEBUG2 then
			if me:KeyDown(IN_ATTACK) then
				self:MoveTo({
					pos = me:GetEyeTrace().HitPos,
					priority = 1,
					id = "test"
				})
			end

			if me:KeyDown(IN_ATTACK2) then
				self:CancelMoving()
			end
		end

		if flock_pos then

			if not self.tallest_point_target or (self.reached_target and math.random() > 0.8 and self.tallest_point_target.z < flock_pos.z - 100) then
				if tallest_points[1] then
					local point = table.remove(tallest_points, 1)

					self.tallest_point_target = point
					self:MoveTo({
						pos = point,
					})
				end
			end

			if math.random() > 0.9 and flock_pos:Distance(self:GetPos()) > flock_radius then
				self:MoveTo({
					get_pos = function(self)
						return flock_pos
					end,
					check = function()
						return flock_pos:Distance(self:GetPos()) > flock_radius
					end,
					id = "flock",
				})
			end

		end

		if not self.finding_food and not IsValid(self.weld) then
			local ent = food[math.random(1, #food)] or NULL
			if ent:IsValid() then
				self.finding_food = true

				local radius = self:BoundingRadius()
				self:MoveTo({
					check = function()
						return
						ent:IsValid() and
						(
							not IsValid(ent.seagull_weld) or
							not IsValid(ent.seagull_weld.seagull) or
							(ent.seagull_weld.seagull ~= self and ent.seagull_weld.seagull:GetScale() < self:GetScale())
						)
					end,
					get_pos = function(self)
						return ent:GetPos()
					end,
					priority = 1,
					id = "food",
					fail = function()
						self.finding_food = nil
					end,
					finish = function()
						self.finding_food = nil

						local s = self:GetScale()
						ent:SetPos(self:GetPos() + self:GetForward() * (s + 2) + self:GetUp() * s)
						ent:GetPhysicsObject():EnableMotion(true)

						local weld = constraint.Weld(self, ent, 0, 0, radius*500, true, false)

						if weld then

							ent:SetOwner(self)

							self.weld = weld
							self.weld.seagull = self
							self.food = ent

							ent.seagull_weld = weld
						end
					end,
				})
			end
		end


		local phys = self:GetPhysicsObject()

		if self.reached_target and not self:InAir() then
			phys:SetVelocity(vector_origin)
			--phys:Sleep()
		else
			self:PhysWake()
		end

		self:CalcMoveTo()
	end

	function ENT:AvoidOthers()
		--if self.TargetPosition then return end

		if not self.next_avoid or self.next_avoid < self.Time then
			self.next_avoid = self.Time + math.random()*0.01

			local pos = self.Position
			local in_air = self:InAir()
			local radius = self.Radius * (in_air and 5 or 3)
			local average_pos = Vector()
			local count = 0

			for i, v in ipairs(all_seagulls) do
				local pos2 = v.Position or v:GetPos()
				if ((in_air and v:InAir()) or (not in_air and not v:InAir())) and pos2:Distance(pos) < radius then
					average_pos = average_pos + pos2
					count = count + 1
				end
			end
			if count > 1 then
				average_pos = average_pos / count
				local vel = pos - average_pos
				if not in_air then
					vel.z = 0
				end
				self.NewVelocity = self.NewVelocity + (vel*3)
			end
		end
	end

	do -- move to a point
		function ENT:MoveTo(data)
			if data.check and not data.check() then if data.fail then data.fail() end return end

			self.TargetPositions = self.TargetPositions or {}
			self.reached_target = nil
			self.target_ids = self.target_ids or {}

			data.priority = data.priority or #self.TargetPositions + 1
			local id = data.id

			if id and self.target_ids[id] then
				table.Merge(self.target_ids[id], data)
				for i,v in ipairs(self.TargetPositions) do
					if v.id == id then
						local v = table.remove(self.TargetPositions, i)
						table.insert(self.TargetPositions, data.priority, v)
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
				local phys = self:GetPhysicsObject()
				self.Velocity = phys:GetVelocity()
		self.NewVelocity = Vector()
		self.VelocityLength = self.Velocity:Length()

		self.AngleVelocity = phys:GetAngleVelocity()
		self.NewAngleVelocity = Vector()
		self.AngleVelocityLength = self.AngleVelocity:Length()

		self.Position = phys:GetPos()
		self.Radius = self:BoundingRadius()
		self.Time = RealTime()

				local ok = not info.check or info.check(self)

				if ok then
					local pos = info.pos

					if info.get_pos then
						pos = info.get_pos(self)
					end

					local reached = false

					local dir = pos - self.Position
					local len2d = dir:Length2D()
					local len = dir:Length()
					local phys = self:GetPhysicsObject()

					if len > self.Radius then
						self.TargetPosition = pos
						self.reached_target = nil
						self.standing_still = nil
					elseif (self.VelocityLength < 100 and self.AngleVelocityLength < 100) then
						if info.waiting_time then
							self.standing_still = self.standing_still or self.Time + info.waiting_time
						end
						if not info.waiting_time or (self.standing_still < self.Time) then
							self.TargetPosition = nil
							self.standing_still = true

							--phys:Sleep()

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
			if not self.unstuck_timer and self.VelocityLength < 20 then
				if DEBUG then
					debugoverlay.Text(self.Position, "STUCK?", 0.1)
				end

				self.stuck_timer = self.stuck_timer or self.Time + math.Rand(0.5,1)

				if self.stuck_timer < self.Time then
					self.Stuck = true
					if DEBUG then
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

				if DEBUG then
					debugoverlay.Text(self.Position, "UNSTUCK!", 1)
				end
			end

			if self.Stuck then
				self:GetPhysicsObject():AddVelocity(VectorRand() * 50)
				return
			end
		end
	end


	function ENT:CalcUpright()
		-- Get angle difference of the prop and up right and facing away from the camera
		local vel = self.Velocity
		local len = self.VelocityLength
		local desired_ang = self.Velocity:Angle()
		local ang = self:GetAngles()

		if self.TargetPosition and self:InAir() then
			local vel = self.TargetPosition - self.Position
			desired_ang = vel:Angle()
		end


		local p = -math.AngleDifference(desired_ang.p, ang.p)
		local y = -math.AngleDifference(desired_ang.y, ang.y)
		local r = -math.AngleDifference(desired_ang.r, ang.r)

		local force = len/40
		local z = 0
		local roll = 0


		if self.TargetPosition and self:InAir() then
			force = 2
		end

		self.NewAngleVelocity = -VectorTemp(force*r, force*p, force*y)
	end

	function ENT:CalcTargetPosition()
		if self.TargetPosition then
			if DEBUG then
				debugoverlay.Line(self.TargetPosition, self.Position, 0)
			end

			local vel = self.TargetPosition - self.Position
			local len2d = vel:Length2D()
			local len = self.VelocityLength

			vel:Normalize()
			vel = vel * 20

			local tr = util.TraceLine({
				start = self:WorldSpaceCenter(),
				endpos = self.TargetPosition,
				filter = self,
			}, self)

			if tr.Hit then
				vel.z = vel.z + 2
			end

			if math.abs(vel.z) < 10 and not self:InAir() then
				if len > 1000 then
					vel.z = vel.z + 10
				end
			end

			if vel.z > 0 then
				vel.z = vel.z * 5
			else
				vel.z = vel.z * 0.5
			end

			if self:InAir() then
				local forward = self:GetForward() * math.max(self:GetForward():Dot(vel), 0)
				local up = self:GetUp() * math.max(self:GetUp():Dot(vel), 0)

				self.NewVelocity = self.NewVelocity + (forward + up)
			else
				self.NewVelocity = self.NewVelocity + vel
			end
		end
	end

	function ENT:CalcAir()
		if self:InAir() then
			self.efficiency = 0.5

			local curvel = self.Velocity
			local curup = self:GetUp()

			local vec1 = curvel
			local vec2 = curup
			vec1 = vec1 - 2*(vec1:Dot(vec2))*vec2
			local sped = vec1:Length()

			local nrm = curvel:GetNormalized()
			local finalvec = curvel
			local modf = math.abs(curup:DotProduct(nrm))
			local nvec = curup:DotProduct(nrm)

			if nvec > 0 then
				vec1 = vec1 + (curup * 10)
			else
				vec1 = vec1 + (curup * -10)
			end

			finalvec = vec1:GetNormalized() * (math.pow(sped, modf) - 1)
			finalvec = finalvec:GetNormalized()
			finalvec = (finalvec * self.efficiency) + self.Velocity

			local liftmul = 1 - math.abs(nvec)
			finalvec = finalvec + (curup * liftmul * self.VelocityLength * self.efficiency) / 3000
			finalvec = finalvec:GetNormalized()
			finalvec = finalvec * self.VelocityLength

			self.NewVelocity = self.NewVelocity - (self.Velocity - finalvec)

			-- tilt
			local vel = self:GetRight():Dot(curvel)

			self.NewAngleVelocity = self.NewAngleVelocity + VectorTemp(vel*0.5,vel*-2.9,0)
			self.NewVelocity = self.NewVelocity + (VectorTemp(0,0,math.sin(self.Time * vel)*vel*0.01) + (self:GetRight() * vel * -0.4))
		end
	end

	function ENT:CalcDamping()
		-- damping
		if self:InAir() then
			local vel = self.Velocity
			self.NewVelocity = self.NewVelocity + (-vel * 0.02)

			-- slow down before hitting the ground
			if vel.z < 0 and self:GetGroundTrace(5).Hit then
				self.NewVelocity = self.Velocity * 0.5
			end
		else
			self.NewVelocity = self.NewVelocity + (-self.Velocity * 0.1)
		end
	end

	function ENT:PhysicsUpdate(phys)

		self.Velocity = phys:GetVelocity()
		self.NewVelocity = Vector()
		self.VelocityLength = self.Velocity:Length()

		self.AngleVelocity = phys:GetAngleVelocity()
		self.NewAngleVelocity = Vector()
		self.AngleVelocityLength = self.AngleVelocity:Length()

		self.Position = phys:GetPos()
		self.Radius = self:BoundingRadius()
		self.Time = RealTime()


		self:CalcStuck()
		self:CalcUpright()
		self:AvoidOthers(phys)
		self:CalcTargetPosition()
		self:CalcAir()
		self:CalcDamping()


		phys:AddVelocity(self.NewVelocity)
		phys:AddAngleVelocity(-self.AngleVelocity + self.NewAngleVelocity)
	end
end

function ENT:OnRemove()
	SafeRemoveEntity(self.weld)
	SafeRemoveEntity(self.csmodel)
end

scripted_ents.Register(ENT, ENT.ClassName, true)

function SEAGULLS(where, max)
	for i = 1, max or 30 do
		local ent = ents.Create("monster_seagull")
		ent:SetPos(where + Vector(math.Rand(-1,1), math.Rand(-1,1), 0)*1000 + Vector(0,0,50))
		ent:Spawn()
	end
end