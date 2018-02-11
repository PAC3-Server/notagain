local META = {}
META.Name = "heal"
META.Names = {"health", "wellbeing", "healthiness"}
META.Adjectives = {"healing", "curative", "medicinal"}

function META:OnDamage(self, attacker, victim, dmginfo)
	local health = victim:Health()
	local max_health = victim:GetMaxHealth()
	if not attacker:IsNPC() or not attacker:IsPlayer() then
		if max_health == health or max_health == 0 or health == 0 then
			dmginfo:SetDamage(0)
			return
		end
	end
	local amt = dmginfo:GetDamage()
	victim:SetHealth(math.min(health + amt, victim:GetMaxHealth()))
	dmginfo:SetDamage(-amt)
end

if CLIENT then
	local jfx = requirex("jfx")
	local mat = jfx.CreateOverlayMaterial("effects/filmscan256")

	function META:SoundThink(ent, f, s, t)
		if math.random() > 0.9 then
			ent:EmitSound("items/smallmedkit1.wav", 75, math.Rand(230,235), f)
		end
	end

	function META:DrawOverlay(ent, f, s, t)
		render.ModelMaterialOverride(mat)
		render.SetColorModulation(0.75, 1*s, 0.75)
		render.SetBlend(f)

		local m = mat:GetMatrix("$BaseTextureTransform")
		m:Identity()
		m:Scale(Vector(1,1,1)*0.05)
		m:Translate(Vector(1,1,1)*t/20)
		mat:SetMatrix("$BaseTextureTransform", m)

		jfx.DrawModel(ent)
	end

	META.Color = Color(150, 255, 150)

	function META:DrawProjectile(ent, dmg, simple, vis)
		local size = dmg / 100

		render.SetMaterial(jfx.materials.glow)
		render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(self.Color.r, self.Color.g, self.Color.b, 255))

		render.SetMaterial(jfx.materials.glow2)
		render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(self.Color.r, self.Color.g, self.Color.b, 200))

		render.SetMaterial(jfx.materials.refract3)
		render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(255,255,255, 150))

		if not simple then

			for i = 1, 3 do
				local pos = ent:GetPos()
				pos = pos + Vector(jfx.GetRandomOffset(pos, i, 2))*size*10

				ent.trail_data = ent.trail_data or {}
				ent.trail_data[i] = ent.trail_data[i] or {}
				jfx.DrawTrail(ent.trail_data[i], 0.25, 0, pos, jfx.materials.trail, self.Color.r, self.Color.g, self.Color.b, 255, self.Color.r, self.Color.g, self.Color.b, 0, 15*size, 0)
			end

			render.SetMaterial(jfx.materials.glow)
			render.DrawSprite(ent:GetPos(), 200*size, 200*size, Color(self.Color.r, self.Color.g, self.Color.b, 50))
		end
	end
end

jdmg.RegisterDamageType(META)