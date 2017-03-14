jeffects = {}

function jeffects.CreateMaterial(data)
	if type(data) == "string" then
		return Material(data)
	end

	local name = (data.Name or "") .. tostring({})
	local shader = data.Shader
	data.Name = nil
	data.Shader = nil

	local params = {}

	for k, v in pairs(data) do
		params["$" .. k] = v
	end

	return CreateMaterial(name, shader, params)
end

function jeffects.CreateModel(data)
	util.PrecacheModel(data.Path)
	local ent = ClientsideModel(data.Path)
	ent:SetNoDraw(true)

	if data.Scale then
		local m = Matrix()
		m:Scale(data.Scale)
		ent:EnableMatrix("RenderMultiply", m)
	end

	if data.NoCull then
		ent.Draw = function()
			render.CullMode(MATERIAL_CULLMODE_CW)
			ent:SetupBones()
			ent:DrawModel()

			render.CullMode(MATERIAL_CULLMODE_CCW)
			ent:SetupBones()
			ent:DrawModel()
		end
	else
		ent.Draw = function()
			ent:SetupBones()
			ent:DrawModel()
		end
	end

	if data.Material then
		ent:SetMaterial(data.Material)
	end

	return ent
end

do
	local temp_color = Color(255, 255, 255)

	function jeffects.DrawTrail(self, len, spc, pos, mat, start_color, end_color, start_size, end_size, stretch)
		self.trail_points = self.trail_points or {}
		self.trail_last_add = self.trail_last_add or 0

		local time = RealTime()

		if not self.trail_points[1] or self.trail_points[#self.trail_points].pos:Distance(pos) > spc then
			table.insert(self.trail_points, {pos = pos, life_time = time + len})
		end

		local count = #self.trail_points

		render.SetMaterial(mat)

		render.StartBeam(count)
			for i = #self.trail_points, 1, -1 do
				local data = self.trail_points[i]

				local f = (data.life_time - time)/len
				f = -f+1

				local width = f * start_size

				local coord = (1 / count) * (i - 1)

				temp_color.r = Lerp(coord, end_color.r, start_color.r)
				temp_color.g = Lerp(coord, end_color.g, start_color.g)
				temp_color.b = Lerp(coord, end_color.b, start_color.b)
				temp_color.a = Lerp(coord, end_color.a, start_color.a)

				render.AddBeam(data.pos, width, (stretch and (coord * stretch)) or width, temp_color)

				if f >= 1 then
					table.remove(self.trail_points, i)
				end
			end
		render.EndBeam()
	end
end

do
	jeffects.materials = jeffects.materials or {}

	jeffects.materials.refract = jeffects.CreateMaterial("particle/warp5_warp")
	jeffects.materials.refract2 = jeffects.CreateMaterial("particle/warp1_warp")
	jeffects.materials.splash_disc = jeffects.CreateMaterial("effects/splashwake3")
	jeffects.materials.beam = jeffects.CreateMaterial("particle/warp3_warp_NoZ")

	jeffects.materials.trail = jeffects.CreateMaterial({
		Shader = "UnlitGeneric",

		BaseTexture = "particle/smokesprites0331",
		Aditive = 1,
		GlowAlpha = 1,
		VertexColor = 1,
		VertexAlpha = 1,
		Translucent = 1,
	})

	jeffects.materials.hypno = jeffects.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "effects/flashlight/circles",
		Aditive = 1,
		VertexColor = 1,
		VertexAlpha = 1,
		Translucent = 1,
	})

	jeffects.materials.ring = jeffects.CreateMaterial({
		Shader = "UnlitGeneric",

		BaseTexture = "particle/particle_Ring_Wave_2",
		Aditive = 1,
		VertexColor = 1,
		VertexAlpha = 1,
	})

	jeffects.materials.glow = jeffects.CreateMaterial({
		Shader = "UnlitGeneric",

		BaseTexture = "sprites/light_glow02",
		Additive = 1,
		VertexColor = 1,
		VertexAlpha = 1,
		Translucent = 1,
	})


	jeffects.materials.glow2 = Material("sprites/light_ignorez")
end

do
	local BASE = {}

	function BASE:Initialize() end
	function BASE:DrawTranslucent() end
	function BASE:DrawOpaque() end

	function BASE:StartEffect(time)
		self.time = RealTime() + time
		self.length = time
	end

	function BASE:Draw(how)
		local time = RealTime()
		local f = -math.max((self.time - RealTime())/self.length, 0)+1

		if f == 1 then
			self:Remove()
		end

		local f2 = math.sin(f*math.pi) ^ 0.5

		if self.ent:IsValid() then
			local m = self.ent:GetBoneMatrix(self.ent:LookupBone("ValveBiped.Bip01_Pelvis"))
			if m then
				self.position = m:GetTranslation()
			else
				self.position = self.ent:GetPos() + self.ent:OBBCenter()
			end
			self.position2 = self.ent:GetPos() + self.ent:OBBCenter()

			if how == "opaque" then
				self:DrawOpaque(time, f, f2)
			else
				self:DrawTranslucent(time, f, f2)
			end
		else
			self:Remove()
		end
	end

	local active = {}

	function BASE:Remove()
		for i, jeffects in ipairs(active) do
			if jeffects == self then
				table.remove(active, i)
				break
			end
		end
	end

	jeffects.effects = jeffects.effects or {}

	function jeffects.RegisterEffect(META)
		META.__index = function(self, key)
			if META[key] then return META[key] end
			if BASE[key] then return BASE[key] end
		end
		jeffects.effects[META.Name] = META
	end

	function jeffects.CreateEffect(name, tbl)
		local jeffects = setmetatable(tbl or {}, jeffects.effects[name])
		jeffects:Initialize()
		jeffects:StartEffect(tbl.length or 1)
		table.insert(active, jeffects)

		hook.Add("PostDrawOpaqueRenderables", "jeffects", function()
			for _, jeffects in ipairs(active) do
				jeffects:Draw("opaque")
			end
		end)

		hook.Add("PostDrawTranslucentRenderables", "jeffects", function()
			for _, jeffects in ipairs(active) do
				jeffects:Draw("translucent")
			end
		end)
	end
end

local feather_mat = jeffects.CreateMaterial({
	Name = "magic_feather_mat",
	Shader = "VertexLitGeneric",

	BaseTexture = "effects/spark",
	Additive = 1,
	VertexColor = 1,
	VertexAlpha = 1,
	Translucent = 1,
})

local spike_model = jeffects.CreateModel({
	Path = "models/props_combine/tprotato1.mdl",
	Scale = Vector(0.1, 0.02, 0.3),
	NoCull = true,
})
local m = Matrix()
m:Scale(Vector(0.1,0.02,0.3))
spike_model:EnableMatrix("RenderMultiply", m)

local ring_model = jeffects.CreateModel({
	Path = "models/props_combine/breentp_rings.mdl",
	Scale = Vector(1, 1, 4),
	Material = "models/gibs/combine_helicopter_gibs/combine_helicopter01",
})

do
	local META = {}
	META.Name = "something"

	function META:Initialize()
		self.pixvis = util.GetPixelVisibleHandle()

		self.color = self.color or Color(255, 217, 104, 255)
		self.size = self.size or self.ent:BoundingRadius() / 70
		self.something = self.something or 1
	end

	function META:DrawSprites(time, f, f2)
		local s = self.size
		local c = Color(self.color.r, self.color.g, self.color.b)
		c.a = 200*f2^5

		cam.Start3D(EyePos(), EyeAngles())
			render.SetMaterial(jeffects.materials.splash_disc)
			render.DrawQuadEasy(self.position, -EyeVector(), (80*s) - f*5, (80*s) - f*5, c, f*45)

			render.SetMaterial(jeffects.materials.splash_disc)
			render.DrawQuadEasy(self.position, Vector(0,0,1), (100*s) - f*5, (100*s) - f*5, c, f*45)

			render.SetMaterial(jeffects.materials.ring)
			render.DrawQuadEasy(self.position, -EyeVector(), 100*s, 100*s, c, f*-45)

			render.SetMaterial(jeffects.materials.glow)
			render.DrawQuadEasy(self.position, -EyeVector(), 64*s, 64*s, c, f*-45)
		cam.End3D()
	end

	function META:DrawGlow(time, f, f2)
		local s = self.size
		local c = Color(self.color.r, self.color.g, self.color.b)
		c.a = 30*f2*self.visible

		cam.Start3D(EyePos(), EyeAngles())
		cam.IgnoreZ(true)
			render.SetMaterial(jeffects.materials.glow)
			local size = 500*s
			render.DrawSprite(self.position, size, size, c)
		cam.IgnoreZ(false)
		cam.End3D()
	end

	function META:DrawRefraction(time, f, f2)
		local s = self.size
		local c = Color(self.color.r, self.color.g, self.color.b)
		c.a = 200*f2*self.something

		cam.Start3D(EyePos(), EyeAngles())
			render.SetMaterial(jeffects.materials.refract)
			render.DrawQuadEasy(self.position, -EyeVector(), 128*s, 128*s, c, f*45)
		cam.End3D()
	end

	function META:DrawRefraction2(time, f, f2)
		local s = self.size
		local c = Color(self.color.r, self.color.g, self.color.b)
		c.a = (self.something*255)*f2

		cam.Start3D(EyePos(), EyeAngles())
			render.SetMaterial(jeffects.materials.refract2)
			render.DrawQuadEasy(self.position, -EyeVector(), 130*s, 130*s, c, f*45)
		cam.End3D()
	end

	function META:DrawSunbeams(time, f, f2)
		local s = self.size
		local pos = self.position
		local screen_pos = pos:ToScreen()

		DrawSunbeams(0, (f2*self.visible*0.1)*self.something, 30 * (1/pos:Distance(EyePos()))*s, screen_pos.x / ScrW(), screen_pos.y / ScrH())
	end

	function META:DrawSpikes(time, f, f2)
		local s = self.size
		render.SetColorModulation(0,0,0)
		render.SuppressEngineLighting(true)
		render.SetBlend(f2 * (self.something)^6)

		spike_model:SetModelScale(1)

		local max = 10
		for i = 1, max do
			local p = (i / max) * math.pi * 2
			p = p + f
			local dist = 30*s
			local offset = Vector(math.sin(p+i+time)*dist, math.cos(p+i+time)*dist, math.sin(p+time)*dist)
			spike_model:SetPos(self.position + offset)
			spike_model:SetAngles(offset:Angle() + Angle(-90,0,0))
			spike_model:Draw()
		end

		render.SuppressEngineLighting(false)
	end

	function META:DrawRing(time, f, f2)
		local s = self.size
		render.SetColorModulation(self.color.r/255*5,self.color.g/255*5,self.color.b/255*5)
		render.SuppressEngineLighting(true)
		render.SetBlend(f2^3)
		ring_model:ManipulateBoneScale(0, Vector(0,0,0))

		for i = 1, 10 do
			ring_model:ManipulateBoneAngles(i, Angle(0,((i/5)*2-1)*RealTime()*500,0))
			ring_model:ManipulateBoneScale(i, Vector(1,1,math.max(self.something,0.2)))
		end

		ring_model:SetModelScale(0.75*s)
		ring_model:SetPos(self.position)
		ring_model:Draw()

		render.SuppressEngineLighting(false)
	end

	function META:EmitParticle()
		local s = self.size
		local ent = ents.CreateClientProp()
		ent:SetModel("models/pac/default.mdl")
		ent:SetPos(self.position + (VectorRand()*10*s))
		ent:SetAngles(VectorRand():Angle())
		ent:SetModelScale(s)

		local m = Matrix()
		m:Translate(Vector(0,20,0)*s)
		m:Scale(Vector(1,0.25,1))
		ent:EnableMatrix("RenderMultiply", m)

		ent.RenderOverride = function()
			local f = (ent.life_time - RealTime()) / 5

			do
				local h,s,v = ColorToHSV(self.color)
				s = s / 2
				local c = HSVToColor(h,s,v)
				render.SetColorModulation(2*c.r/255, 2*c.g/255, 2*c.b/255)
			end

			render.SetBlend(f^0.5)

			render.SuppressEngineLighting(true)
			render.MaterialOverride(feather_mat)
			render.SetMaterial(feather_mat)
			render.CullMode(MATERIAL_CULLMODE_CW)
			ent:DrawModel()
			render.CullMode(MATERIAL_CULLMODE_CCW)
			ent:DrawModel()
			render.MaterialOverride()
			render.SuppressEngineLighting(false)

			local phys = ent:GetPhysicsObject()
			phys:AddVelocity(Vector(0,0,-FrameTime()*100)*s)

			local vel = phys:GetVelocity()

			if vel.z < 0 then
				local delta= FrameTime()*2
				phys:AddVelocity(Vector(-vel.x*delta,-vel.y*delta,-vel.z*delta*2)*s)
			end
		end

		ent:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
		ent:PhysicsInitSphere(5)

		local phys = ent:GetPhysicsObject()
		phys:EnableGravity(false)
		phys:AddVelocity(Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(1, 2))*80*s)
		phys:AddAngleVelocity(VectorRand()*50)
		ent:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
		ent.life_time = RealTime() + 5

		SafeRemoveEntityDelayed(ent, 5)
	end

	function META:DrawDownBeam(time, f, f2)
		local s = self.size
		local c = Color(self.color.r, self.color.g, self.color.b)
		c.a = 150*f2*self.something

		--cam.Start3D(EyePos(), EyeAngles())
			local ang = EyeAngles()
			ang.p = 0

			render.SetMaterial(jeffects.materials.beam)
			render.DrawQuadEasy(self.position+ Vector(0,0,300), -ang:Forward(), 100*s, 2500, Color(255,255,255,100*f2*self.something), 0)

			render.SetMaterial(jeffects.materials.glow)
			render.DrawQuadEasy(self.position+ Vector(0,0,300*f2), -ang:Forward(), 200*f2*s, 2500/f, c, 0)
		--cam.End3D()
	end

	function META:DrawTranslucent(time, f, f2)
		if f < 0.25 and self.something == 1 then
			if not self.emitted then
				for i = 1, math.random(5,10) do
					self:EmitParticle()
				end
				self.emitted = true
			end
		else
			self.emitted = false
		end

		self.visible = util.PixelVisible(self.position, 50, self.pixvis)
		self:DrawDownBeam(time, f, f2)
		self:DrawSprites(time, f, f2)

		self:DrawRefraction(time, f, f2)
		self:DrawRefraction2(time, f, f2)
		self:DrawGlow(time, f, f2)
		self:DrawSunbeams(time, f, f2)
	end

	function META:DrawOpaque(time, f, f2)
		self:DrawSpikes(time, f, f2)
		self:DrawRefraction2(time, f, f2)
		self:DrawRing(time, f, f2)
	end

	jeffects.RegisterEffect(META)
end

do
	local META = {}
	META.Name = "trails"

	function META:DrawTranslucent(time, f, f2)
		self.trails = self.trails or {}
		for i = 1, 5 do
			self.trails[i] = self.trails[i] or {data = {}}
			self.trails[i].vec = self.trails[i].vec or VectorRand()
			self.trails[i].vec2 = self.trails[i].vec2 or VectorRand()
			local v = self.trails[i].vec
			local v2 = self.trails[i].vec2

			local s = (i/8) * math.pi * 2
			local offset = Vector(math.sin(s+v.x), math.cos(s+v.y), math.sin(-s+v.z)) * 30
			local t = RealTime()*500
			offset:Rotate(Angle(t*v2.x, t*v2.y, t*v2.z))

			jeffects.DrawTrail(self.trails[i], 1, 2, self.position2 + offset, jeffects.materials.trail, Color(self.color.r, self.color.g, self.color.b, 255*(f2^2)), Color(255, 255, 255, 0), 10, 10, f2)
		end
	end

	jeffects.RegisterEffect(META)
end