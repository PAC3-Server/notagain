local META = {}
META.Name = "decay"
META.Negative = true

if CLIENT then
	local jfx = requirex("jfx")

	META.Icon = jfx.CreateMaterial({
		Shader = "UnlitGeneric",
		BaseTexture = "editor/env_particles",
		VertexAlpha = 1,
		VertexColor = 1,
		BaseTextureTransform = "center 0.45 .1 scale 0.9 0.9 rotate 0 translate 0 -0.05",
	})

	local jfx = requirex("jfx")
	local mat = jfx.CreateOverlayMaterial("effects/filmscan256", {Additive = 0, RimlightBoost = 1})
	local dark = Material("effects/bluespark")

	function META:DrawOverlay(ent)
		local f = self:GetAmount()
		local s = f
		local t = RealTime()

		render.ModelMaterialOverride(mat)
		render.SetColorModulation(-s,-s,-s)
		render.SetBlend(f)

		local m = mat:GetMatrix("$BaseTextureTransform")
		m:Identity()
		m:Scale(Vector(1,1,1)*0.15)
		m:Translate(Vector(1,1,1)*t/5)
		mat:SetMatrix("$BaseTextureTransform", m)

		jfx.DrawModel(ent)
	end

	function META:OnStart(ent)
		if ent ~= LocalPlayer() then return end

		jrpg.AddHook("RenderScreenspaceEffects", "jdmg_decay", function()
			local f = self:GetAmount()
			f = math.Clamp(math.sin(f * math.pi), 0, 1)

			local hm = math.abs(math.sin(RealTime())^50)
			DrawColorModify({
				[ "$pp_colour_brightness" ] = hm,
				[ "$pp_colour_colour" ] = -f+1,
				[ "$pp_colour_contrast" ] = 1,
			})
		end)
		local played = false
		local function setup_fog()
			local f = self:GetAmount()
			f = math.Clamp(math.sin(f * math.pi), 0, 1) ^ 0.5

			render.FogMode(1)
			render.FogStart(-7000*f)
			render.FogEnd(500*f)
			render.FogMaxDensity(0.995*f)
			local hm = Lerp(f, 100, math.abs(math.sin(RealTime() + 0.3)^50*100))

			if hm > 50 then
				if not played then
					ent:EmitSound("npc/strider/strider_step4.wav", 75, 70)
					played = true
				end
			else
				played = false
			end

			render.FogColor(hm,hm,hm)

			return true
		end

		self.old_hooks_world = {}
		if hook.GetTable().SetupWorldFog then
			for k,v in pairs(hook.GetTable().SetupWorldFog) do self.old_hooks_world[k] = v jrpg.RemoveHook("SetupWorldFog", k,v) end
		end

		self.old_hooks_skybox = {}
		if hook.GetTable().SetupSkyboxFog then
			for k,v in pairs(hook.GetTable().SetupSkyboxFog) do self.old_hooks_skybox[k] = v jrpg.RemoveHook("SetupSkyboxFog", k,v) end
		end

		jrpg.AddHook("SetupWorldFog", "jdmg_decay", setup_fog)
		jrpg.AddHook("SetupSkyboxFog", "jdmg_decay", setup_fog)
	end

	function META:OnStop(ent)
		if ent ~= LocalPlayer() then return end

		jrpg.RemoveHook("RenderScreenspaceEffects", "jdmg_decay")
		jrpg.RemoveHook("SetupWorldFog", "jdmg_decay")
		jrpg.RemoveHook("SetupSkyboxFog", "jdmg_decay")

		for k, v in pairs(self.old_hooks_world) do jrpg.AddHook("SetupWorldFog", k, v) end
		for k, v in pairs(self.old_hooks_skybox) do jrpg.AddHook("SetupSkyboxFog", k, v) end
	end
end

jdmg.RegisterStatusEffect(META)