local META = {}
META.Name = "frozen"
META.Negative = true

if CLIENT then
	local jfx = requirex("jfx")

	META.Icon = jfx.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "editor/env_particles",
		VertexAlpha = 1,
		VertexColor = 1,
		BaseTextureTransform = "center 0.45 .1 scale 0.75 0.75 rotate 0 translate 0 0",
	})

	local ice_mat = jfx.CreateMaterial({
		Name = "magic_ice",
		Shader = "VertexLitGeneric",
		CloakPassEnabled = 1,
		RefractAmount = 1,
	})

	function META:DrawOverlay(ent, f)
		f = f * 0.1
		local pos = ent:NearestPoint(ent:WorldSpaceCenter()+VectorRand()*100)

		local p = jfx.emitter:Add("effects/splash1", pos + VectorRand() * 20)
		p:SetStartSize(1)
		p:SetEndSize(0)
		p:SetStartAlpha(50*f)
		p:SetEndAlpha(0)
		p:SetVelocity(VectorRand()*5)
		p:SetGravity(VectorRand()*10)
		p:SetColor(255, 255, 255)
		--p:SetLighting(true)
		p:SetRoll(math.random()*360)
		p:SetGravity(physenv.GetGravity()*0.1)
		p:SetAirResistance(100)
		p:SetLifeTime(1)
		p:SetDieTime(math.Rand(0.75,1.5)*2)

		local c = Vector(0.25,0.5,1)*5*(f^0.15)
		ice_mat:SetVector("$CloakColorTint", c)
		ice_mat:SetFloat("$CloakFactor", f^0.4)
		ice_mat:SetFloat("$RefractAmount", (-f+1))
		render.ModelMaterialOverride(ice_mat)
		render.SetColorModulation(c.r*2, c.g*2, c.b*2)
		render.SetBlend(f)
		jfx.DrawModel(ent)
	end
end

if SERVER then
	function META:OnStart(ent)
		ent:EmitSound("weapons/icicle_freeze_victim_01.wav")

		if ent.SetLaggedMovementValue then
			ent:SetLaggedMovementValue(0)
		end
		if ent.Freeze then
			ent:Freeze(true)
		end

		if ent.SetCondition then
			ent:SetCondition(67) -- COND_NPC_FREEZE
			ent:SetPlaybackRate(0)
			ent:SetBloodColor(BLOOD_COLOR_MECH)
		end
	end

	function META:Think(ent)
		ent:SetPlaybackRate(0)
		ent:SetCycle(0.5)
		if SERVER then
			if ent.SetTarget then
				ent:SetTarget(game.GetWorld())
				ent:StopMoving()
				ent:SetEnemy(game.GetWorld(), true)
			end
		end
	end

	function META:OnStop(ent)
		ent:EmitSound("weapons/icicle_melt_01.wav")

		if ent.SetLaggedMovementValue then
			ent:SetLaggedMovementValue(1)
		end
		if ent.Freeze then
			ent:Freeze(false)
		end
		if ent.SetCondition then
			ent:SetCondition(68) -- COND_NPC_UNFREEZE
			ent:SetPlaybackRate(1)
		end

		ent.jdmg_freeze = nil
	end
end

jdmg.RegisterStatusEffect(META)