local META = {}
META.Name = "wind"
META.Adjectives = {"windy", "stormy", "gusty", "drafty", "airy", "windswept"}
META.Names = {"wind", "ozone", "breath", "whiff"}

if CLIENT then
	local jfx = requirex("jfx")
	local mat = jfx.CreateOverlayMaterial("effects/filmscan256")

	local wind = {
		"particle/particle_noisesphere",
		"effects/splash1",
		"effects/splash2",
		"effects/splash4",
		"effects/blood",

	}

	function META:SoundThink(ent, f, s, t)
		if math.random() > 0.8 then
			ent:EmitSound("ambient/wind/wind_hit"..math.random(1,3)..".wav", 75, math.Rand(150,180), f)
		end
	end

	META.Color = Color(255, 255, 255)

	function META:DrawOverlay(ent, f, s, t)
		render.ModelMaterialOverride(mat)
		render.SetColorModulation(1,1,1*s)
		render.SetBlend(f)

		local m = mat:GetMatrix("$BaseTextureTransform")
		m:Identity()
		m:Scale(Vector(1,1,1)*0.05)
		m:Translate(Vector(1,1,1)*t/20)
		mat:SetMatrix("$BaseTextureTransform", m)

		jfx.DrawModel(ent)
	end

	local trail = Material("particle/smokesprites_0009")

	local trail = jfx.CreateMaterial({
		Shader = "UnlitGeneric",

		BaseTexture = "particle/particle_smokegrenade",
		Additive = 0,
		VertexColor = 1,
		VertexAlpha = 1,
	})

	function META:DrawProjectile(ent, dmg, simple)
		local size = dmg / 100

		render.SetMaterial(jfx.materials.glow)
		render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(self.Color.r, self.Color.g, self.Color.b, 255))

		render.SetMaterial(jfx.materials.glow2)
		render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(self.Color.r, self.Color.g, self.Color.b, 200))

		render.SetMaterial(jfx.materials.refract3)
		render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(255,255,255, 100))

		if simple then return end

		for i = 1, 4 do
			local pos = ent:GetPos()
			pos = pos + Vector(jfx.GetRandomOffset(pos, i, 1))*size*50

			math.randomseed(i+ent:EntIndex())
			local rand = (math.random()^2) + 1

			ent.trail_data = ent.trail_data or {}
			ent.trail_data[i] = ent.trail_data[i] or {}
			jfx.DrawTrail(ent.trail_data[i], 0.4*rand, 0, pos, trail, self.Color.r, self.Color.g, self.Color.b, 50, self.Color.r, self.Color.g, self.Color.b, 0, 60*size, 0, 1)
		end
		math.randomseed(os.clock())
	end
end

jdmg.RegisterDamageType(META)
