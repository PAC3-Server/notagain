local META = {}
META.Name = "generic"

if CLIENT then
	local jfx = requirex("jfx")
	local mat = jfx.CreateOverlayMaterial("models/effects/portalfunnel2_sheet")

	function META:DrawOverlay(ent, f, s, t)
		render.ModelMaterialOverride(mat)
		render.SetColorModulation(s,s,s)
		render.SetBlend(f)

		local m = mat:GetMatrix("$BaseTextureTransform")
		m:Identity()
		m:Scale(Vector(1,1,1)*0.15)
		m:Translate(Vector(1,1,1)*t/5)
		mat:SetMatrix("$BaseTextureTransform", m)

		jfx.DrawModel(ent)
	end

	META.Color = Color(255, 255, 255)

	function META:DrawProjectile(ent, dmg, simple)
		local size = dmg / 100

		render.SetMaterial(jfx.materials.glow)
		render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(self.Color.r, self.Color.g, self.Color.b, 255))

		render.SetMaterial(jfx.materials.glow2)
		render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(self.Color.r, self.Color.g, self.Color.b, 150))

		if not simple then
			jfx.DrawTrail(ent, 0.4, 0, ent:GetPos(), jfx.materials.trail, self.Color.r, self.Color.g, self.Color.b, 50, self.Color.r, self.Color.g, self.Color.b, 0, 10, 0, 1)
		end
	end
end

jdmg.RegisterDamageType(META)