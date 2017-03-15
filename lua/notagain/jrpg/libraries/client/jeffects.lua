local jeffects = {}

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
		if k == "Proxies" then
			params[k] = v
		else
			params["$" .. k] = v
		end
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

	function jeffects.DrawTrail(self, len, spc, pos, mat, start_color, end_color, start_size, end_size, stretch, gravity)
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

		if true or gravity then
			local center = Vector(0,0,0)
			for _, data in ipairs(self.trail_points) do
				center:Zero()
				for _, data in ipairs(self.trail_points) do
					center:Add(data.pos)
				end
				center:Mul(1 / #self.trail_points)
				center:Sub(data.pos)
				center:Mul(-FrameTime())

				data.pos:Add(center)
			end
		end
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
		Additive = 1,
		GlowAlpha = 1,
		VertexColor = 1,
		VertexAlpha = 1,
		Translucent = 1,
	})

	jeffects.materials.hypno = jeffects.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "effects/flashlight/circles",
		Additive = 1,
		VertexColor = 1,
		VertexAlpha = 1,
		Translucent = 1,
	})

	jeffects.materials.ring = jeffects.CreateMaterial({
		Shader = "UnlitGeneric",

		BaseTexture = "particle/particle_Ring_Wave_2",
		Additive = 1,
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

return jeffects