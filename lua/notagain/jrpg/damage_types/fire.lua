local META = {}
META.Name = "fire"

function META:OnDamage(self, attacker, victim, dmginfo)
	jdmg.AddStatus(victim, "fire", dmginfo:GetDamage()/100)
end

META.Adjectives = {"hot", "molten", "burning", "flaming"}
META.Names = {"fire", "flames"}

META.DamageTranslate = {
	DMG_BURN = true,
	DMG_SLOWBURN = true,
}

if CLIENT then
	local jfx = requirex("jfx")
	local mat = jfx.CreateOverlayMaterial("models/props_lab/cornerunit_cloud")
	local flames ={}

	for i = 1, 5 do
		table.insert(flames, jfx.CreateMaterial({
			Shader = "UnlitGeneric",
			BaseTexture = "sprites/flamelet" .. i,
			VertexAlpha = 1,
			VertexColor = 1,
			Additive = 1,
			NoCull = 1,
		}))
	end

	local smoke = {
		"particle/smokesprites0001",
		"particle/smokesprites0067",
		"particle/smokesprites0133",
		"particle/smokesprites0199",
		"particle/smokesprites0265",
		"particle/smokesprites0331",
	}
	for i, path in ipairs(smoke) do
		smoke[i] = jfx.CreateMaterial({
			Shader = "UnlitGeneric",
			BaseTexture = path,
			VertexAlpha = 1,
			VertexColor = 1,
		})
	end

	function META:SoundThink(ent, f, s, t)
		if math.random() > 0.98 then
			ent:EmitSound("ambient/fire/mtov_flame2.wav", 75, math.Rand(50,100), f)
		end

		for i = 1, 1 do
			local pos
			local mat = ent:GetBoneMatrix(math.random(1, ent:GetBoneCount()))

			if mat then
				pos = mat:GetTranslation()
			else
				pos = ent:NearestPoint(ent:WorldSpaceCenter()+VectorRand()*100)
			end

			local p = jfx.emitter:Add(table.Random(flames), pos)
			p:SetStartSize(math.Rand(5,20))
			p:SetEndSize(math.Rand(5,20))
			p:SetStartAlpha(255*f)
			p:SetEndLength(math.Rand(p:GetEndSize(),20))
			p:SetEndAlpha(0)
			p:SetColor(math.Rand(230,255),math.Rand(230,255),math.Rand(230,255))
			p:SetGravity(physenv.GetGravity()*-0.25)
			p:SetRoll(math.random()*360)
			p:SetAirResistance(5)
			p:SetLifeTime(0.25)
			p:SetDieTime(math.Rand(0.25,0.75))

			if math.random() > 0.95 then
				local p = jfx.emitter:Add(table.Random(smoke), pos + VectorRand())
				p:SetStartSize(0)
				p:SetEndSize(math.Rand(50,200))
				p:SetStartAlpha(255*f)
				p:SetEndAlpha(0)
				p:SetVelocity(VectorRand()*5)
				p:SetGravity(physenv.GetGravity()*-0.1)
				p:SetColor(20, 20, 20)
				--p:SetLighting(true)
				p:SetRoll(math.random()*360)
				p:SetAirResistance(100)
				p:SetLifeTime(1)
				p:SetDieTime(math.Rand(0.3,1.5)*5)
			end
		end
	end

	function META:DrawOverlay(ent, f, s, t)
		render.ModelMaterialOverride(mat)
		render.SetColorModulation(2*s,1*s,0.5)
		render.SetBlend(f)

		local m = mat:GetMatrix("$BaseTextureTransform")
		m:Identity()
		m:Scale(Vector(1,1,1)*1.5)
		m:Translate(Vector(1,1,1)*t/5)
		mat:SetMatrix("$BaseTextureTransform", m)

		jfx.DrawModel(ent)
	end

	local trail = jfx.CreateMaterial({
		Shader = "UnlitGeneric",

		BaseTexture = "particle/fire",
		Additive = 1,
		VertexColor = 1,
		VertexAlpha = 1,
	})

	META.Color = Color(255, 125, 25)
	function META:DrawProjectile(ent, dmg, simple)
		local size = dmg / 200


		jfx.DrawSprite(jfx.materials.glow, ent:GetPos(), 100*size, nil, 0, self.Color.r,self.Color.g,self.Color.b,255, 2)
		jfx.DrawSprite(jfx.materials.refract2, ent:GetPos(), 32*size, nil,0, 10,2,0, 255)


		jfx.DrawSprite(jfx.materials.glow, ent:GetPos(), 256*size, nil, 0, self.Color.r, self.Color.g, self.Color.b, 20)

		if not simple then
			for i = 1, 7 do
				local pos = ent:GetPos()
				pos = pos + Vector(jfx.GetRandomOffset(pos, i, 2))*size*40

				math.randomseed(i+ent:EntIndex())
				local rand = (math.random()^2)*3

				ent.trail_data = ent.trail_data or {}
				ent.trail_data[i] = ent.trail_data[i] or {}
				jfx.DrawTrail(ent.trail_data[i], 0.2*rand, 0, pos, jfx.materials.trail, self.Color.r, self.Color.g, self.Color.b, 255, self.Color.r*1.5, self.Color.g*1.5, self.Color.b*1.5, 0, 7*rand*size, 0)
			end

			math.randomseed(os.clock())
		end

	end
end

jdmg.RegisterDamageType(META)