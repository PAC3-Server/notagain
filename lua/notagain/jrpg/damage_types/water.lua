local META = {}
META.Name = "water"
META.Adjectives =  {"soggy", "doused", "soaked", "rainy", "misty", "wet"}
META.Names = {"water", "rain", "aqua", "h2o"}
META.DamageTranslate = {
	DMG_DROWN = true,
}

if CLIENT then
	local jfx = requirex("jfx")
	local mat = jfx.CreateOverlayMaterial("effects/filmscan256")

	local water = {
		"particle/particle_noisesphere",
		"effects/splash1",
		"effects/splash2",
		"effects/splash4",
		"effects/blood",

	}

	function META:SoundThink(ent, f, s, t)
		if math.random() > 0.8 then
			ent:EmitSound("ambient/water/wave"..math.random(1,6)..".wav", 75, math.Rand(200,255), f)
		end
	end

	META.Color = Color(150, 200, 255)

	function META:DrawOverlay(ent, f, s, t)
		local pos = ent:GetBoneMatrix(math.random(1, ent:GetBoneCount()))
		if pos then
			pos = pos:GetTranslation()

			local p = jfx.emitter:Add(table.Random(water), pos + VectorRand() * 5)
			p:SetStartSize(20)
			p:SetEndSize(20)
			p:SetStartAlpha(50*f)
			p:SetEndAlpha(0)
			p:SetVelocity(VectorRand()*10)
			p:SetGravity(physenv.GetGravity()*0.025)
			p:SetColor(self.Color.r, self.Color.g, self.Color.b)
			--p:SetLighting(true)
			p:SetRoll(math.random())
			p:SetRollDelta(math.random()*2-1)
			p:SetLifeTime(1)
			p:SetDieTime(math.Rand(0.75,1.5)*2)
		end

		render.ModelMaterialOverride(mat)
		render.SetColorModulation(self.Color.r/255,self.Color.g/255,self.Color.b/255)
		render.SetBlend(f)

		local m = mat:GetMatrix("$BaseTextureTransform")
		m:Identity()
		m:Scale(Vector(1,1,1)*0.05)
		m:Translate(Vector(1,1,1)*t/20)
		mat:SetMatrix("$BaseTextureTransform", m)

		jfx.DrawModel(ent)
	end

	local refract = jfx.CreateMaterial({
		Shader = "Refract",
		NormalMap = "http://files.gamebanana.com/bitpit/psfixnormal.jpg",
		RefractAmount = -0.4,
		VertexColor = 1,
		VertexAlpha = 1,
		Translucent = 1,
		Additive = 1,
		ForceRefract = 1,
		BlurAmount = 1,
		NoFog = 1,
		VertexColorModulate = 1,
	})

	function META:DrawProjectile(ent, dmg, simple, vis)
		local size = dmg / 100

		render.SetMaterial(jfx.materials.glow)
		render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(self.Color.r, self.Color.g, self.Color.b, 255))

		render.SetMaterial(jfx.materials.glow2)
		render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(self.Color.r, self.Color.g, self.Color.b, 200))

		render.SetMaterial(jfx.materials.refract3)
		render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(255,255,255, 100))

		if simple then return end

		for i = 1, 2 do
			local pos = ent:GetPos()
			pos = pos + Vector(jfx.GetRandomOffset(pos, i, 2))*size*80

			math.randomseed(i+ent:EntIndex())
			local rand = (math.random()^2)*3


			ent.trail_data = ent.trail_data or {}
			ent.trail_data[i] = ent.trail_data[i] or {}
			--jfx.DrawTrail(ent.trail_data[i], 0.25*rand, 0, pos, jfx.materials.trail, color.r, color.g, color.b, 5, color.r*1.5, color.g*1.5, color.b*1.5, 0, 30*rand*size, 1)
			jfx.DrawTrail(ent.trail_data[i], 0.5*rand, 0, pos, refract, self.Color.r,self.Color.g,self.Color.b, 255, self.Color.r,self.Color.g,self.Color.b, 30*size, 15*rand*size,0)
		end

		math.randomseed(os.clock())

		local p = jfx.emitter:Add(refract, ent:GetPos())
		p:SetStartSize(0)
		p:SetEndSize(20)
		p:SetStartAlpha(30)
		p:SetEndAlpha(0)
		p:SetVelocity(VectorRand()*10)
		p:SetGravity(physenv.GetGravity()*0.05)
		p:SetColor(100, 200, 255)
		--p:SetLighting(true)
		p:SetRoll(math.random())
		p:SetRollDelta(math.random()*2-1)
		p:SetLifeTime(1)
		p:SetDieTime(math.Rand(0.75,1.5)*2)
	end
end

jdmg.RegisterDamageType(META)
