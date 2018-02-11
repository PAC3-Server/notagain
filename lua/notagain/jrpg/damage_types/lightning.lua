local META = {}
META.Name = "lightning"
META.Adjectives = {"shocking", "electrical", "electrifying"}
META.Names = {"lightning", "thunder", "zeus"}
META.DamageTranslate = {
	DMG_SHOCK = true,
}
function META:OnDamage(self, attacker, victim, dmginfo)
	jdmg.SetStatus(victim, "lightning", true)

	local time = CurTime() + 5

	local id = "poison_"..tostring(attacker)..tostring(victim)

	timer.Create(id, 0.2, 0, function()
		if not victim:IsValid() then
			timer.Remove(id)
			return
		end

		if victim.GetActiveWeapon then
			local wep = victim:GetActiveWeapon()
			if wep and wep:IsValid() then
				wep:SetNextPrimaryFire(CurTime()+math.random())
				wep:SetNextSecondaryFire(CurTime()+math.random())
			end
		end

		if (not victim:IsPlayer() or not victim:Alive()) or time < CurTime() then
			timer.Remove(id)
			jdmg.SetStatus(victim, "lightning", false)
		end
	end)
end

if CLIENT then
	local jfx = requirex("jfx")
	local mat = jfx.CreateOverlayMaterial("sprites/lgtning")

	function META:SoundThink(ent, f, s, t)
		if math.random() > 0.95 then
			ent:EmitSound("ambient/energy/zap"..math.random(1, 3)..".wav", 75, math.Rand(150,255), f)
		end
	end

	META.Color = Color(230, 230, 255)

	function META:DrawOverlay(ent, f, s, t)
		f = 0.1 * f + (f * math.random() ^ 5)

		--t = t + math.Rand(0,0.25)
		f = f + math.Rand(0,1)*f
		s = s + math.Rand(0,1)*f
		t = t + math.Rand(0, 0.25)

		render.ModelMaterialOverride(mat)
		render.SetColorModulation(1*s,1*s,1*s)
		render.SetBlend(f)

		local m = mat:GetMatrix("$BaseTextureTransform")
		m:Identity()
		m:Scale(Vector(1,1,1)*math.Rand(5,20))
		m:Translate(Vector(1,1,1)*t/5)
		m:Rotate(VectorRand():Angle())
		mat:SetMatrix("$BaseTextureTransform", m)

		jfx.DrawModel(ent)
	end

	local arc = jfx.CreateMaterial({
		Shader = "UnlitGeneric",

		BaseTexture = "https://cdn.discordapp.com/attachments/273575417401573377/291918796027985920/lightning.png",
		BaseTextureTransform = "center .5 .5 scale 2 2 rotate 0 translate -0.45 -0.45",
		Additive = 1,
		VertexColor = 1,
		VertexAlpha = 1,
	})

	function META:DrawProjectile(ent, dmg, simple, vis)
		local size = dmg / 100

		render.SetMaterial(jfx.materials.glow)
		render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(self.Color.r, self.Color.g, self.Color.b, 255))

		render.SetMaterial(jfx.materials.glow2)
		render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(self.Color.r, self.Color.g, self.Color.b, 200))

		render.SetMaterial(jfx.materials.refract3)
		render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(255,255,255, 150))
		if not simple then

			render.SetMaterial(jfx.materials.glow)
			render.DrawSprite(ent:GetPos(), 200*size, 200*size, Color(self.Color.r, self.Color.g, self.Color.b, 50))



			if not ent.next_emit or ent.next_emit < RealTime() then
				jfx.DrawSprite(arc, ent:GetPos(), 25*size + math.random(-20,20), 25*size + math.random(-20,20) * (math.random()^4*10), math.random(360), self.Color.r,self.Color.g,self.Color.b,255)
				ent.next_emit = RealTime() + math.random()*0.05
			end
		end
	end
end

jdmg.RegisterDamageType(META)