local jfx = {}

local urlimage = requirex("urlimage")

do
	local min = math.min
	local max = math.max
	local abs = math.abs

	function jfx.HSV2RGB(h,s,v)
		local _, h = math.modf(h)
		return
			(min(max(abs(h * 6 - 3) - 1, 0), 1)*s + (-s+1)) * v * 255,
			(min(max(2-abs(h * 6 - 2), 0), 1)*s + (-s+1)) * v * 255,
			(min(max(2-abs(h * 6 - 4), 0), 1)*s + (-s+1)) * v * 255
	end

	function jfx.RGB2HSV(r,g,b)
		r = r / 255
		g = g / 255
		b = b / 255

		local minRGB = min(r, min(g, b))
		local maxRGB = max(r, max(g, b))

		if minRGB == maxRGB then
			return 0,0,minRGB
		end

		local h,d

		if r == minRGB then
			d = g - b
		elseif b == minRGB then
			d = r - g
		else
			d = b - r
		end

		if r == minRGB then
			h = 3/360
		elseif b == minRGB then
			h = 1/360
		else
			h = 5/360
		end

		local diff = (maxRGB - minRGB)

		return
			(60/360) * (h - d / diff),
			diff / maxRGB,
			maxRGB
	end
end

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
			if type(v) == "string" and v:StartWith("http") then
				v = "error" -- loading texture here?
			end
			params["$" .. k] = v
		end
	end

	local mat = CreateMaterial(name, shader, params)

	for k, v in pairs(data) do
		if type(v) == "string" and v:StartWith("http") then
			local id = tostring({})
			hook.Add("Think", id, function()
				if not LocalPlayer():IsValid() then return end

				local m,w,h = urlimage.GetURLImage(v)

				if m == nil then
					hook.Remove("Think", id)
				elseif m then
					mat:SetInt("$glowx", w)
					mat:SetInt("$glowy", h)
					mat:SetTexture("$" .. k, m:GetTexture("$BaseTexture"))
					hook.Remove("Think", id)
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

	function jfx.DrawTrail(self, len, spc, pos, mat, scr,scg,scb,sca, ecr,ecg,ecb,eca, start_size, end_size, stretch, brightness)
		brightness = brightness or 1
		self.trail_points = self.trail_points or {}

		local time = RealTime()

		if self.last_frame ~= FrameNumber() then
			if not self.trail_points[1] or self.trail_points[#self.trail_points].pos:Distance(pos) > spc then
				table.insert(self.trail_points, {pos = pos, life_time = time + len})
			end
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

				temp_color.r = math.min(Lerp(coord, ecr, scr)*brightness, 255)
				temp_color.g = math.min(Lerp(coord, ecg, scg)*brightness, 255)
				temp_color.b = math.min(Lerp(coord, ecb, scb)*brightness, 255)
				temp_color.a = math.min(Lerp(coord, eca, sca)*brightness, 255)

				render.AddBeam(data.pos, width, (stretch and (coord * stretch)) or width, temp_color)

				if f >= 1 then
					table.remove(self.trail_points, i)
				end
			end
		render.EndBeam()

		if self.last_frame ~= FrameNumber() then
			local center = Vector(0,0,0)
			for i, data in ipairs(self.trail_points) do
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

		self.last_frame = FrameNumber()
	end
end


do
    local mat = jfx.CreateMaterial({
        Shader = "refract",
        NormalMap = "effects/fisheyelens_normal",
        --NormalMap2 = "Models/effects/fisheyelens_normal",
        --DudvMap = "Models/effects/fisheyelens_dudv",
        VertexColorModulate = 1,
        VertexColor = 1,
        Translucent = 1,
        Model = 1,
        ForceRefract = 1
    })

    function jfx.DrawPointBlur(x, y, size, refract)
        render.UpdateScreenEffectTexture()

        render.SetMaterial(mat)

        render.SetColorModulation(0.5, 1, 0.4)
        render.SetBlend(0.1)

        surface.SetMaterial(mat)
        mat:SetVector( "$RefractTint", Vector(1,1,1) )

        local max = 3*20
        local r,g,b = 1,1,1

        for i = 1, max do
            local f = i/max
            f = f ^ 3
            mat:SetFloat( "$refractamount", f * 0.1 * refract)

            local r,g,b = r,g,b
            local a = f^5
            local i = i%3
            if i == 0 then
                r = r * 0.5
            elseif i == 1 then
                b = b * 0.5
            elseif i == 2 then
                g = g * 0.5
            end

            local size = size * f

            surface.SetDrawColor(r*255,g*255,b*255,a*70)
            surface.DrawTexturedRect(x-size/2,y-size/2,size,size)
        end
    end
end

do
	local c = Color(255,255,255,255)
	local EyeVector = EyeVector
	local render_DrawQuadEasy = render.DrawQuadEasy

	function jfx.DrawSprite(mat, pos, sx,sy, rot, r,g,b,a, brightness)
		sy = sy or sx
		rot = rot or 0
		r = r or 255
		g = g or 255
		b = b or 255
		a = a or 255

		brightness = brightness or 1
		render.SetMaterial(mat)

		local overdraw = 1

		if brightness > 1 and (r*brightness > 255 or g*brightness > 255 or b*brightness > 255) then
			overdraw = brightness
			brightness = 1
		end

		c.r = math.min(r*brightness, 255)
		c.g = math.min(g*brightness, 255)
		c.b = math.min(b*brightness, 255)
		c.a = math.min(a*brightness, 255)

		local eye_vec = -EyeVector()


		for i = 1, overdraw do
			render_DrawQuadEasy(pos, eye_vec, sx, sy, c, rot)
		end
	end
end

do
	local simplex = requirex("simplex")

	function jfx.GetRandomOffset(pos, seed, scale)
		scale = scale or 1
		local ix,iy,iz = pos.x, pos.y, pos.z
		ix = ((ix * seed) / 1000) * scale
		iy = ((iy * seed) / 1000) * scale
		iz = ((iz * seed) / 1000) * scale

		local x = simplex.Noise3D(ix, iy, iz)
		local y = simplex.Noise3D(0.5+ix, 0.5+iy, 0.5+iz)
		local z = simplex.Noise3D(0.5-ix, 0.5-iy, 0.5-iz)

		return x,y,z
	end
end

do
	local BASE = {}

	function BASE:Initialize() end
	function BASE:OnRemove() end
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

		if self.ent then
			if self.ent:IsValid() then
				local m = self.ent:GetBoneMatrix(self.ent:LookupBone("ValveBiped.Bip01_Pelvis"))
				if m then
					self.position = m:GetTranslation()
				else
					self.position = self.ent:GetPos() + self.ent:OBBCenter()
				end
				self.position2 = self.ent:GetPos() + self.ent:OBBCenter()
			else
				self:Remove()
			end
		end
		if how == "opaque" then
			self:DrawOpaque(time, f, f2)
		else
			self:DrawTranslucent(time, f, f2)
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

		self:OnRemove()
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
	jfx.materials.refract3 = jfx.CreateMaterial("particle/warp2_warp")

	jfx.materials.beam = jfx.CreateMaterial("particle/warp3_warp_NoZ")

	jfx.materials.trail = jfx.CreateMaterial({
		Shader = "UnlitGeneric",

		BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/trail.png",
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
	jfx.pixvis = util.GetPixelVisibleHandle()

end

function jfx.DrawModel(ent)
	ent = jrpg.GetActorBody(ent)

	if ent.pacDrawModel then
		ent:pacDrawModel(true)
	else
		ent:DrawModel()
	end
end

function jfx.DrawSunbeams(pos, size, mult, darken)
	local eye = EyePos()

	do return end

	local spos = pos:ToScreen()
	DrawSunbeams(
		darken,
		math.Clamp(mult * (math.Clamp(EyeVector():DotProduct((pos - eye):GetNormalized()) - 0.5, 0, 1) * 2) ^ 5, 0, 1),
		size,
		spos.x / ScrW(),
		spos.y / ScrH()
	)
end

jfx.emitter = ParticleEmitter(vector_origin)

function jfx.CreateOverlayMaterial(tex, override)
	override = override or {}
	return jfx.CreateMaterial(table.Merge({
		Name = "fire",
		Shader = "VertexLitGeneric",
		Additive = 1,
		Translucent = 1,

		Phong = 1,
		PhongBoost = 0.5,
		PhongExponent = 0.4,
		PhongFresnelRange = Vector(0,0.5,1),
		PhongTint = Vector(1,1,1),


		Rimlight = 1,
		RimlightBoost = 50,
		RimlightExponent = 5,
		BaseTexture = tex,


		BaseTextureTransform = "center .5 .5 scale 0.25 0.25 rotate 90 translate 0 0",

		Proxies = {

			Equals = {
				SrcVar1 = "$color",
				ResultVar = "$phongtint",
			},
		},

		BumpMap = "dev/bump_normal",
	}, override))
end

return jfx