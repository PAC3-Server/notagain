local META = {}

META.Name = "poison"
META.Adjectives = {"poisonous", "venomous", "toxic", "infected", "diseased"}
META.Names = {"poison", "venom", "infection", "illness", "sickness"}

META.DamageTranslate = {
	DMG_RADIATION = true,
	DMG_NERVEGAS = true,
	DMG_ACID = true,
}

if CLIENT then
	local jfx = requirex("jfx")
	local mat = jfx.CreateOverlayMaterial("effects/filmscan256")
	META.Sounds = {
		{
			path = "ambient/gas/cannister_loop.wav",
			pitch = 200,
		},
	}

	function META:SoundThink(ent, f, s, t)
		if math.random() > 0.95 then
			ent:EmitSound("ambient/levels/canals/toxic_slime_sizzle"..math.random(2, 4)..".wav", 75, math.Rand(120,170), f)
		end
	end

	function META:DrawOverlay(ent, f, s, t)
		local pos = ent:GetBoneMatrix(math.random(1, ent:GetBoneCount()))
		if pos then
			pos = pos:GetTranslation()

			local p = jfx.emitter:Add("effects/splash1", pos + VectorRand() * 20)
			p:SetStartSize(30)
			p:SetEndSize(30)
			p:SetStartAlpha(50*f)
			p:SetEndAlpha(0)
			p:SetVelocity(VectorRand()*20)
			p:SetGravity(VectorRand()*10)
			p:SetColor(0, 150, 0)
			--p:SetLighting(true)
			p:SetRoll(math.random()*360)
			p:SetAirResistance(100)
			p:SetLifeTime(1)
			p:SetDieTime(math.Rand(0.75,1.5)*2)
		end

		render.ModelMaterialOverride(mat)
		render.SetColorModulation(0,1*s,0)
		render.SetBlend(f)

		local m = mat:GetMatrix("$BaseTextureTransform")
		m:Identity()
		m:Scale(Vector(1,1,1)*0.05)
		m:Translate(Vector(1,1,1)*t/20)
		mat:SetMatrix("$BaseTextureTransform", m)

		jfx.DrawModel(ent)
	end

	META.Color = Color(100,255,100)

	function META:DrawProjectile(ent, dmg, simple)
		local size = dmg / 100


		render.SetMaterial(jfx.materials.refract)
		render.DrawSprite(ent:GetPos(), 20*size, 20*size, Color(self.Color.r/4, self.Color.g/4, self.Color.b/4, 255))

		if simple then return end

		--jfx.DrawTrail(ent, 1, 0, ent:GetPos(), jfx.materials.trail, color.r, color.g, color.b, 50, color.r, color.g, color.b, 0, 10, 0, 1)

		local p = jfx.emitter:Add("effects/bubble", ent:GetPos() + VectorRand() * 5)
		local size = math.Rand(1,4)
		p:SetStartSize(size)
		p:SetEndSize(size)
		p:SetStartAlpha(50)
		p:SetEndAlpha(0)
		p:SetVelocity(VectorRand()*20)
		p:SetGravity(VectorRand()*10)
		p:SetColor(100, 255, 100)
		--p:SetLighting(true)
		p:SetRoll(math.random()*360)
		p:SetAirResistance(100)
		p:SetLifeTime(1)
		p:SetDieTime(math.Rand(0.75,1.5)*2)
	end
end

if SERVER then
	function META:OnDamage(self, attacker, victim, dmginfo)
		jdmg.AddStatus(victim, "poison", dmginfo:GetDamage()/100, {
			attacker = dmginfo:GetAttacker(),
			weapon = dmginfo:GetInflictor(),
		})
	end
end

jdmg.RegisterDamageType(META)