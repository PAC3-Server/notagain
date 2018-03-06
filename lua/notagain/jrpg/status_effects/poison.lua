local META = {}
META.Name = "poison"
META.Negative = true

if CLIENT then
	local jfx = requirex("jfx")

	META.Icon = jfx.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "http://wow.zamimg.com/images/wow/icons/large/ability_creature_poison_06.jpg",
		VertexAlpha = 1,
		VertexColor = 1,
	})

	local mat = jfx.CreateOverlayMaterial("effects/filmscan256")
	META.Sounds = {
		{
			path = "ambient/gas/cannister_loop.wav",
			pitch = 200,
		},
	}

	function META:SoundThink(ent)
		local f = self:GetAmount()
		if math.random() > 0.95 then
			ent:EmitSound("ambient/levels/canals/toxic_slime_sizzle"..math.random(2, 4)..".wav", 75, math.Rand(120,170), f)
		end
	end

	function META:DrawOverlay(ent)
		local f = self:GetAmount()
		local s = f
		local t = RealTime()
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

end

META.Rate = 1

if SERVER then
	function META:Think(target)
		local dmginfo = DamageInfo()
		dmginfo:SetDamage(1 + math.ceil(self:GetAmount() * 2))
		dmginfo:SetDamageCustom(JDMG_POISON)
		dmginfo:SetDamagePosition(target:WorldSpaceCenter())

		local attacker = self:GetAttacker()
		if attacker:IsValid() then
			dmginfo:SetAttacker(attacker)
			dmginfo:SetInflictor(attacker)
		end

		if self:GetAmount() > 0.75 then
			for _, ent in ipairs(ents.FindInSphere(target:GetPos(), math.min(target:BoundingRadius() * 3, 500))) do
				if ent ~= target and jrpg.IsActor(ent) then
					wepstats.TakeDamageInfo(ent, dmginfo)
				end
			end
		end

		wepstats.TakeDamageInfo(target, dmginfo)
	end
end

jdmg.RegisterStatusEffect(META)