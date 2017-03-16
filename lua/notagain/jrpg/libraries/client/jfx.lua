local jfx = {}

local urlimage = requirex("urlimage")

function jfx.CreateMaterial(data)
	if type(data) == "string" then
		return Material(data)
	end

	local name = (data.Name or "") .. tostring({})
	local shader = data.Shader
	data.Name = nil
	data.Shader = nil

	local params = {}
	local mat

	for k, v in pairs(data) do
		if k == "Proxies" then
			params[k] = v
		else
			params["$" .. k] = v
		end
	end

	local mat = CreateMaterial(name, shader, params)

	for k, v in pairs(data) do
		if type(v) == "string" and v:StartWith("http") then
			hook.Add("Think", v, function()
				local m,w,h = urlimage.GetURLImage(v)
				if m == nil then
					print(m,w,h)
					hook.Remove("Think", v)
				elseif m then
					mat:SetTexture("$" .. k, m:GetTexture("$BaseTexture"))
					hook.Remove("Think", v)
				end
			end)
		end
	end

	return mat
end

function jfx.CreateModel(data)
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

	function jfx.DrawTrail(self, len, spc, pos, mat, start_color, end_color, start_size, end_size, stretch)
		self.trail_points = self.trail_points or {}

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
		for i, jfx in ipairs(active) do
			if jfx == self then
				table.remove(active, i)
				break
			end
		end
	end

	jfx.effects = jfx.effects or {}

	function jfx.RegisterEffect(META)
		META.__index = function(self, key)
			if META[key] then return META[key] end
			if BASE[key] then return BASE[key] end
		end
		jfx.effects[META.Name] = META
	end

	function jfx.CreateEffect(name, tbl)
		local jfx = setmetatable(tbl or {}, jfx.effects[name])
		jfx:Initialize()
		jfx:StartEffect(tbl.length or 1)
		table.insert(active, jfx)

		hook.Add("RenderScreenspaceEffects", "jfx", function()
			render.UpdateScreenEffectTexture()
			cam.Start3D()
			for _, jfx in ipairs(active) do
				local ok, err = pcall(jfx.Draw, jfx, "opaque")
				if not ok then
					jfx:Remove()
					print(err)
				end
			end

			for _, jfx in ipairs(active) do
				local ok, err = pcall(jfx.Draw, jfx, "translucent")
				if not ok then
					jfx:Remove()
					print(err)
				end
			end
			cam.End3D()
		end)
	end
end


do
	jfx.materials = jfx.materials or {}

	jfx.materials.refract = jfx.CreateMaterial("particle/warp5_warp")
	jfx.materials.refract2 = jfx.CreateMaterial("particle/warp1_warp")
	jfx.materials.beam = jfx.CreateMaterial("particle/warp3_warp_NoZ")

	jfx.materials.trail = jfx.CreateMaterial({
		Shader = "UnlitGeneric",

		BaseTexture = "https://cdn.discordapp.com/attachments/273575417401573377/291702123689934849/trail.png",
		Additive = 1,
		GlowAlpha = 1,
		VertexColor = 1,
		VertexAlpha = 1,
		Translucent = 1,
	})


	jfx.materials.glow = jfx.CreateMaterial({
		Shader = "UnlitGeneric",

		BaseTexture = "sprites/light_glow02",
		Additive = 1,
		VertexColor = 1,
		VertexAlpha = 1,
		Translucent = 1,
	})

	jfx.materials.glow2 = Material("sprites/light_ignorez")
end

return jfx