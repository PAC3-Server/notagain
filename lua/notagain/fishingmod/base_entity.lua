fishing.Entities = {}

function fishing.CreateEntity(class)
	return fishing.Entities[class] and ents.Create(fishing.Entities[class])
end

local ENT
do -- base
	ENT = {}

	ENT.ClassName = "base"

	ENT.Type = "anim"
	ENT.Base = "base_anim"

	ENT.hook = NULL

	ENT.Model = Model("models/dav0r/hoverball.mdl")
	ENT.PositionOffset = Vector(0, 0, 0)
	ENT.AngleOffset = Angle(0, 0, 0)

	ENT.CamPos2D = Vector(50, 50, 50)
	ENT.CamAng2D = Angle(0, 0, 0)

	if CLIENT then
		function ENT:On2DDraw()
			self:DrawModel()
		end

		function ENT:On3DDraw()
			self:DrawModel()
		end

		function ENT:DrawRect(x, y, w, h)
			cam.Start3D(self.CamPos2D, self.CamAng2D, 70, x, y, w, h, 5, 4096)
				cam.IgnoreZ(true)
					render.SuppressEngineLighting(true)

						render.SetLightingOrigin(self:GetPos())

						render.ResetModelLighting(1, 1, 1)
						render.SetColorModulation(1, 1, 1)
						render.SetBlend(1)

						self:SetRenderOrigin(Vector(0,0,0))
						self:SetupBones()

						self:On2DDraw()

						self:SetRenderOrigin()

				render.SuppressEngineLighting(false)
				cam.IgnoreZ(false)
			cam.End3D()
		end

		ENT.Draw = ENT.On3DDraw -- consistency
	end

	function ENT:Initialize()

		self:SetModel(self.Model)
		
		if SERVER then
			self:PhysicsInit(SOLID_VPHYSICS)
		end

		self.rand_size = fishing.GetRandomSize(self.spot_depth)

		self:PostInit(self.rand_size)
	end

	if SERVER then

		ENT.Mass = 99

		function ENT:SetSize(num)
			self:SetModelScale(num, 0)
			
			--[[local phys = self:GetPhysicsObject()
			local mdl = phys:GetMesh()

			for key, vtx in pairs(mdl) do
				vtx.pos = vtx.pos * (num ^ 1.25)
			end

			self:PhysicsFromMesh(mdl)
			self:EnableCustomCollisions(true)]]

			self.Size = num

			local phys = self:GetPhysicsObject()

			phys:SetMass(self.Mass * num)
			self:StartMotionController(true)
		end

		function ENT:GetSize()
			return self.Size or 1
		end

		function ENT:Attach(hook)
			if self:PreAttach(hook) == false then return end

			self:SetParent()

			self:SetPos(hook:LocalToWorld(self.PositionOffset))
			self:SetAngles(hook:LocalToWorldAngles(self.AngleOffset))

			self:SetParent(hook)

			hook.attached[self.FishingType] = self
			self.hook = hook

			self:DelayRemove(100)

			self:OnAttach(hook)
		end

		function ENT:Detach()
			if self.hook:IsValid() then
				self:SetParent()

				self:SetPos(self.hook:LocalToWorld(self.PositionOffset))
				self:SetAngles(self.hook:LocalToWorldAngles(self.AngleOffset))
				
				local phys = self:GetPhysicsObject()
				phys:Wake()
				phys:SetVelocity(self.hook:GetVelocity())

				local hook = self.hook
				hook.attached[self.FishingType] = NULL
				self.hook = NULL

				self:OnDetach(hook)
			end
		end

		function ENT:PostEntityPaste()
			self:Remove()
		end

		ENT.player_owner = NULL

		function ENT:SetPlayerOwner(ply)
			self.player_owner = ply

			if self.CPPISetOwner then
				self:CPPISetOwner(ply)
			end
		end

		function ENT:GetPlayerOwner()
			return self.player_owner
		end

		function ENT:DelayRemove(sec)
			self.fishing_delay_remove = CurTime() + sec
		end

		timer.Create("fishing_garbage_collect_fish", 1, 0, function()
			for key, ent in pairs(ents.GetAll()) do
				if ent.IsFishingEntity then
					if
						ent.player_owner and
						not ent.player_owner:IsValid() and
						ent.fishing_delay_remove and
						ent.fishing_delay_remove < CurTime()
					then
						if not fishing.IsPosVisible(ent:GetPos()) then
							ent:Remove()
						end
					end
				end
			end
		end)
	end

	function ENT:PreAttach(hook) end
	function ENT:OnAttach(hook) end
	function ENT:OnDetach(hook) end
	function ENT:PostInit() end

end

do -- bait
	local function SETUP_TYPE(TYPE, META)
		local classes = {}
		local registered = {}
		fishing["Registered" .. TYPE] = registered
		fishing[TYPE .. "EntityClasses"] = classes

		fishing["Create"..TYPE] = function(class, pos, depth)
			local class = ("fishing_" .. TYPE .. "_" .. class):lower()
			local ent

			if not pos and easylua and there then
				ent = create(class)
				ent:SetPlayerOwner(me)
			else
				ent = ents.Create(class)

				if pos then
					ent:SetPos(pos)
					ent:Spawn()
				end
			end

			ent.spot_depth = depth or 20
			ent.fishing_rand = math.random()

			return ent
		end

		fishing["Register" .. TYPE] = function(META)
			META.Base = META.Base or "fishing_" .. TYPE:lower() .. "_base"

			META["IsFishing" .. TYPE] = true
			META.IsFishingEntity = true
			META.FishingType = TYPE
			META.FishingClassName = META.ClassName
			if not META.Description then
				META.Description =  "no description ..."
			end

			if not META.Name then
				META.Name = META.ClassName:gsub("_", " ")
			end
			
			local class = "fishing_" .. TYPE:lower() .. "_" .. META.ClassName

			fishing.Entities[META.ClassName] = class
			registered[META.ClassName] = META

			if not META.ClassName:find("base") then
				table.insert(classes, {real = class, short = META.ClassName})
			end

			scripted_ents.Register(META, class, true)
		end

		fishing["RemoveAll" .. TYPE] = function()
			for key, ent in pairs(ents.GetAll()) do
				if ent["IsFishing" .. TYPE] then
					ent:Remove()
				end
			end
		end

		fishing["GetAll" .. TYPE .. "Classes"] = function()
			return classes
		end

		fishing["Register" .. TYPE](table.Copy(ENT))
	end

	SETUP_TYPE("Bait")
	SETUP_TYPE("Fish")
end