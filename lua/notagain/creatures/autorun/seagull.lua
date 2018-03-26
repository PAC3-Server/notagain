local ENT = {}
ENT.Type = "anim"
ENT.ClassName = "creature_seagull"
ENT.Base = "creature_base"
ENT.PrintName = "seagull"
ENT.Model = "models/seagull.mdl"
ENT.DefaultSize = 50
ENT.AlternateNetworking = true

function ENT:OnSizeChanged(size)
	if CLIENT then
		self.model:SetColor(Color(255, 255, Lerp(size/20, 100, 255), 255))

		local m = Matrix()
		m:Translate(Vector(0,0,-size))
		m:Scale(Vector(1,1,1) * size / self.model:GetModelRadius() * 4)
		self.model:SetLOD(8)
		self.model:EnableMatrix("RenderMultiply", m)
	end
end

if CLIENT then
	ENT.Cycle = 0
	ENT.Noise = 0

	local ambient_sounds = {
		"ambient/creatures/seagull_idle1.wav",
		"ambient/creatures/seagull_idle2.wav",
		"ambient/creatures/seagull_idle3.wav",
	}

	local footstep_sounds = {}

	for i = 1, 5 do
		footstep_sounds[i] = "seagull_step_" .. i .. "_" .. util.CRC(os.clock())
		sound.Generate(footstep_sounds[i], 22050, 0.25, function(t)
			local f = (t/22050) * (1/0.25)
			f = -f + 1
			f = f ^ 10
			return ((math.random()*2-1) * math.sin(t*1005) * math.cos(t*0.18)) * f
		end)
	end

	function ENT:OnUpdate(dt)
		local scale = self:GetSize()

		local vel = self.Velocity / scale
		local len = vel:Length()

		if not self:InAir() then
			self.takeoff = false

			local mult = 1

			if len < 1 then
				self:SetAnim("Idle01")
				len = 15 * (self.Noise * 0.25)
			else
				if CLIENT then
					self:StepSoundThink()
				end

				if len > 4 then
					self:SetAnim("Run")
				else
					self:SetAnim("Walk")
				end

				mult = math.Clamp(self:GetForward():Dot(vel), -1, 1) * 0.25
			end

			self.Noise = (self.Noise + (math.Rand(-1,1) - self.Noise) * dt)
			self.Cycle = (self.Cycle + len * dt * mult) % 1
			self.model:SetCycle(self.Cycle)
		else
			local len2d = vel:Length2D()

			if len2d < 10 and vel.z < 0 then
				self:SetAnim("Land")
				self.Cycle = Lerp(RealTime()%1, 0.3, 0.69)
			elseif vel.z < 0 then
				self:SetAnim("Soar")
				self.Cycle = RealTime()
			else
				self:SetAnim("Fly")

				if vel.z > 0 then
					self.Cycle = self.Cycle + FrameTime() * 2
				else
					self.Cycle = Lerp(math.Clamp((-vel.z/100), 0, 1), 0.1, 1)
				end
			end

			self.Cycle = self.Cycle%1
			self.model:SetCycle(self.Cycle)
		end

		if math.random() > 0.999 then
			sound.Play(ambient_sounds[math.random(1, #ambient_sounds)], self:GetPos(), 75, math.Clamp((1000 / self:GetSize()) + math.Rand(-10, 10), 1, 255), 1)
		end
	end

	function ENT:StepSoundThink()
		local siz = self:GetSize()
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
					table.Random(footstep_sounds),
					self:GetPos(),
					self:EntIndex(),
					CHAN_AUTO,
					1,
					--math.Clamp(10 * siz, 70, 160),
					55,
					0,
					--math.Clamp(100 / (siz/3) + math.Rand(-20,20), 40, 255)
					math.Clamp(700/siz + math.Rand(-15, 15), 10, 255)
				)

				self.stepped = true
			end
		else
			self.stepped = false
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
	local food = {}
	local tallest_points = {}
	local all_seagulls = ents.FindByClass(ENT.ClassName)

	local function global_update()
		all_seagulls = ents.FindByClass(ENT.ClassName)

		local found = all_seagulls
		local count = #found
		local pos = VectorTemp(0,0,0)

		for _, ent in ipairs(found) do
			local p = ent.Position or ent:GetPos()
			pos = pos + p
		end

		if count > 1 then
			pos = pos / count

			flock_vel = (flock_pos or pos) - pos

			flock_pos = pos

			if creatures.DEBUG then
				debugoverlay.Sphere(pos, flock_radius, 1, Color(0, 255, 0, 5))
				if me:KeyDown(IN_JUMP) then
					tallest_points = {}
				end
			end

			local up = physenv.GetGravity():GetNormalized()
			local top = util.QuickTrace(pos + Vector(0,0,flock_radius/2), up*-10000).HitPos
			top.z = math.min(pos.z + flock_radius, top.z)
			local bottom = util.QuickTrace(top, up*10000).HitPos

			if creatures.DEBUG then
				debugoverlay.Text(top, "TOP", 1)
				debugoverlay.Text(bottom, "BOTTOM", 1)
				debugoverlay.Text(LerpVector(0.5, top, bottom), "POINTS: " .. #tallest_points, 1)
			end

			top.z = math.min(flock_pos.z + flock_radius, top.z)

			local max = 30

			if not tallest_points[max] then
				for i = 1, max do
					if tallest_points[max] then
						break
					end

					local start_pos = LerpVector(i/max, bottom, top)

					if DBEUG then
						debugoverlay.Cross(start_pos, 100, 1)
					end

					--if not util.IsInWorld(start_pos) then break end
					local tr = util.TraceLine({
						start = start_pos,
						endpos = start_pos + VectorTemp(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(-1, -0.2))*flock_radius,
					})

					if tr.Hit and math.abs(tr.HitNormal.z) > 0.8 and (not tr.Entity:IsValid() or tr.Entity.ClassName ~= ENT.ClassName) then
						if tr.HitPos.z > flock_pos.z then
							for _,v in ipairs(tallest_points) do
								if v:Distance(tr.HitPos) < 50 then
									return
								end
							end

							table.insert(tallest_points, tr.HitPos)
						end
					end

					if creatures.DEBUG then
						debugoverlay.Line(tr.StartPos, tr.HitPos, 1, tr.Hit and Color(0,255,0, 255) or Color(255,0,0, 255))
					end
				end

				if creatures.DEBUG then
					for _,v in ipairs(tallest_points) do
						debugoverlay.Cross(v, 5, 1, Color(0,0,255, 255))
					end
				end

				table.sort(tallest_points, function(a, b) return a.z > b.z end)

				for i = #tallest_points, 1, -1 do
					local v = tallest_points[i]
					if v:Distance(flock_pos) > flock_radius then
						table.remove(tallest_points, i)
					end
				end
			end
		else
			flock_pos = nil
		end
	end

	local function entity_create(ent)
		timer.Simple(0.25, function()
			if not ent:IsValid() then return end

			local phys = ent:GetPhysicsObject()
			if phys:IsValid() and (
				phys:GetMaterial():lower():find("flesh") or
				phys:GetMaterial() == "watermelon" or
				phys:GetMaterial() == "antlion"
			) then
				ent.seagull_food = true
				table.insert(food, ent)
			end
		end)
	end

	local function entity_remove(ent)
		if ent.seagull_food then
			for i,v in ipairs(food) do
				if v == ent then
					table.remove(food, i)
				end
			end
		end
	end


	timer.Create(ENT.ClassName, 1, 0, function()
		global_update()
	end)

	hook.Add("OnEntityCreated", ENT.ClassName, function(ent)
		entity_create(ent)
	end)

	hook.Add("EntityRemoved", ENT.ClassName, function(ent)
		entity_remove(ent)
	end)

	function ENT:OnUpdate()

		if not self.standing_still then
			local avoid = self:AvoidOthers()
			if avoid then
				local mult = self:InAir() and 0.25 or 0.25
				self.Physics:AddVelocity(avoid*self:GetSize() * mult)
			end
		end

		if flock_pos then

			if not self.tallest_point_target or (self.reached_target and math.random() > 0.2 and self.tallest_point_target.z < flock_pos.z - 100) then
				if tallest_points[1] then
					local point = table.remove(tallest_points, 1)

					self.tallest_point_target = point
					self:MoveTo({
						pos = point,
						waiting_time = 0.25,
						finish = function()
							self:GetPhysicsObject():Sleep()
						end
					})
				end
			end

			if math.random() > 0.9 and flock_pos:Distance(self:GetPos()) > flock_radius then
				self:MoveTo({
					get_pos = function()
						return flock_pos
					end,
					check = function()
						return flock_pos:Distance(self:GetPos()) > flock_radius
					end,
					id = "flock",
				})
			end
		end

		if math.random() > 0.9 and not self.finding_food and not IsValid(self.weld) then
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
							(ent.seagull_weld.seagull ~= self and ent.seagull_weld.seagull:GetSize() < self:GetSize())
						)
					end,
					get_pos = function()
						return ent:GetPos()
					end,
					priority = 1,
					id = "food",
					fail = function()
						self.finding_food = nil
					end,
					finish = function()
						self.finding_food = nil

						local s = self:GetSize()
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
	end

	function ENT:AvoidOthers()
		if self.TargetPosition then return end

		local pos = self.Position
		local radius = self:GetSize() * (self:InAir() and 3 or 0.6)
		local average_pos = Vector()
		local count = 0

		for _, v in ipairs(ents.FindInSphere(pos, radius)) do
			if v.ClassName == self.ClassName and v ~= self then
				average_pos = average_pos + (v.Position or v:GetPos())
				count = count + 1
			end
		end

		if count > 1 then
			average_pos = average_pos / count

			return pos - average_pos
		end
	end

	function ENT:MoveToPoint(pos)
		if creatures.DEBUG then
			debugoverlay.Line(pos, self.Position, 0.1)
		end

		local size = self:GetSize()

		local dir = pos - self.Position
		local len = dir:Length()
		local len2d = dir:Length2D()

		local vel = dir:GetNormalized()
		vel.z = 0
		vel = vel * size * 0.8

		local what = math.min(dir.z + (size * 3) / len, 30)

		if what > 0 then
			vel.z = vel.z + what *2
		end

		if dir.z > -size*2 and len2d > size*2 then
			vel.z = vel.z + size
		end

		self.DesiredAngle = nil

		local m = self.Physics:GetMass()

		if self:InAir() then
			if len2d < size*5 then
				self.DesiredAngle = vel:Angle()
			end

			self.Physics:SetDamping(m * (1/len) * 100 + 2,0)
		else
			self.Physics:SetDamping(m * 7, m * 5)
		end


		return vel
	end
end

scripted_ents.Register(ENT, ENT.ClassName)