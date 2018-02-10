local META = {}
META.Name = "dark"
META.Color = Color(255, 50, 200)

META.Adjectives = {
	"eerie",
	"ghastly",
	"cursed",
	"evil",
	"darkened",
	"haunted",
	"scary",
	"corrupt",
	"malicious",
	"unpleasant",
	"hateful",
	"wrathful",
	"ill"
}

META.Names = {
	"misery",
	"sin",
	"suffering",
	"darkness",
	"evil",
	"hades",
	"corruption",
	"heinousness"
}

META.Sounds = {
	{
		path = "ambient/atmosphere/tone_quiet.wav",
		pitch = 150,
	}
}

if CLIENT then
	local jfx = requirex("jfx")
	local mat = jfx.CreateOverlayMaterial("effects/filmscan256", {Additive = 0, RimlightBoost = 1})
	local dark = Material("effects/bluespark")

	function META:SoundThink(ent, f, s, t)
		if math.random() > 0.5 then
			ent:EmitSound("hl1/fvox/buzz.wav", 75, math.Rand(175,255), f)
		end
	end

	function META:DrawOverlay(ent, f, s, t)
		local m = Matrix()
		m:Scale(Vector(1,1,1) + (VectorRand()*0.1) * f)
		ent:EnableMatrix("RenderMultiply", m)

		render.ModelMaterialOverride(mat)
		render.SetColorModulation(-s,-s,-s)
		render.SetBlend(f)

		local m = mat:GetMatrix("$BaseTextureTransform")
		m:Identity()
		m:Scale(Vector(1,1,1)*0.15)
		m:Translate(Vector(1,1,1)*t/5)
		mat:SetMatrix("$BaseTextureTransform", m)

		jfx.DrawModel(ent)

		ent:DisableMatrix("RenderMultiply")
	end

	function META:DrawProjectile(ent, dmg, simple)
		local size = dmg / 100

		jfx.DrawSprite(jfx.materials.refract2, ent:GetPos(), 60*size, nil,0, 10,2,0, 255)

		render.SetMaterial(dark)
		for i = 1, 20 do
			render.DrawQuadEasy(ent:GetPos(), -EyeVector(), 32*size * math.random(), 32*size * math.random(), Color(self.Color.r, self.Color.g, self.Color.b, 255), (i/20)*360)
		end

		render.SetMaterial(jfx.materials.refract3)
		render.DrawSprite(ent:GetPos(), 60*size + math.sin(RealTime()*4)*3, 60*size + math.cos(RealTime()*4)*3, Color(255,255,255, 30 + (math.sin(RealTime()*4)*0.5+0.5)*50))

		if not simple then
			jfx.DrawTrail(ent, 0.1, 0, ent:GetPos(), dark, self.Color.r, self.Color.g, self.Color.b, 50, self.Color.r, self.Color.g, self.Color.b, 0, 30, 0, 2)
		end
	end
end

jdmg.RegisterDamageType(META)