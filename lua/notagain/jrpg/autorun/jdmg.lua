jdmg = jdmg or {}

local emitter
local create_material
local create_overlay_material
local draw_model

if CLIENT then
	draw_model = function(ent)
		if ent.pacDrawModel then
			ent:pacDrawModel(true)
		else
			ent:DrawModel()
		end
	end
	emitter = ParticleEmitter(vector_origin)

	create_material = function(data)
		if type(data) == "string" then
			return Material(data)
		end

		local name = (data.Name or "") .. tostring({})
		local shader = data.Shader
		data.Name = nil
		data.Shader = nil

		local params = {}

		for k, v in pairs(data) do
			if k == "Proxies" then
				params[k] = v
			else
				params["$" .. k] = v
			end
		end

		return CreateMaterial(name, shader, params)
	end

	create_overlay_material = function(tex, override)
		override = override or {}
		return create_material(table.Merge({
			Name = "fire",
			Shader = "VertexLitGeneric",
			Additive = 1,
			Translucent = 1,

			Phong = 1,
			PhongBoost = 0.5,
			PhongExponent = 0.4,
			PhongFresnelRange = Vector(0,0.5,1),
			PhongTint = Vector(1,1,1),


			Rimlight = 1,
			RimlightBoost = 50,
			RimlightExponent = 5,
			BaseTexture = tex,


			BaseTextureTransform = "center .5 .5 scale 0.25 0.25 rotate 90 translate 0 0",

			Proxies = {

				Equals = {
					SrcVar1 = "$color",
					ResultVar = "$phongtint",
				},
			},

			BumpMap = "dev/bump_normal",
		}, override))
	end

	do
		local temp_color = Color(255, 255, 255)

		function jdmg.DrawTrail(self, len, spc, pos, mat, start_color, end_color, start_size, end_size, stretch)
			self.trail_points = self.trail_points or {}
			self.trail_last_add = self.trail_last_add or 0

			local time = RealTime()

			if not self.trail_points[1] or self.trail_points[#self.trail_points].pos:Distance(pos) > spc then
				table.insert(self.trail_points, {pos = pos, life_time = time + len})
			end

			local count = #self.trail_points

			render.SetMaterial(mat)

			render.StartBeam(count)
				for i = #self.trail_points, 1, -1 do
					local data = self.trail_points[i]

					local f = (data.life_time - time)/len
					f = -f+1

					local width = f * start_size

					local coord = (1 / count) * (i - 1)

					temp_color.r = Lerp(coord, end_color.r, start_color.r)
					temp_color.g = Lerp(coord, end_color.g, start_color.g)
					temp_color.b = Lerp(coord, end_color.b, start_color.b)
					temp_color.a = Lerp(coord, end_color.a, start_color.a)

					render.AddBeam(data.pos, width, (stretch and (coord * stretch)) or width, temp_color)

					if f >= 1 then
						table.remove(self.trail_points, i)
					end
				end
			render.EndBeam()
		end
	end

	do
		jdmg.materials = jdmg.materials or {}

		jdmg.materials.refract = create_material("particle/warp5_warp")
		jdmg.materials.refract2 = create_material("particle/warp1_warp")
		jdmg.materials.refract3 = create_material("particle/warp2_warp")
		jdmg.materials.splash_disc = create_material("effects/splashwake3")
		jdmg.materials.beam = create_material("particle/warp3_warp_NoZ")

		jdmg.materials.trail = create_material({
			Shader = "UnlitGeneric",

			BaseTexture = "particle/smokesprites0331",
			Aditive = 1,
			GlowAlpha = 1,
			VertexColor = 1,
			VertexAlpha = 1,
			Translucent = 1,
		})

		jdmg.materials.hypno = create_material({
			Shader = "UnlitGeneric",
			BaseTexture = "effects/flashlight/circles",
			Aditive = 1,
			VertexColor = 1,
			VertexAlpha = 1,
			Translucent = 1,
		})

		jdmg.materials.ring = create_material({
			Shader = "UnlitGeneric",

			BaseTexture = "particle/particle_Ring_Wave_2",
			Aditive = 1,
			VertexColor = 1,
			VertexAlpha = 1,
		})

		jdmg.materials.glow = create_material({
			Shader = "UnlitGeneric",

			BaseTexture = "sprites/light_glow02",
			Additive = 1,
			VertexColor = 1,
			VertexAlpha = 1,
			Translucent = 1,
		})

		jdmg.materials.dark = Material("effects/bluespark")
		jdmg.materials.dark_trail = Material("sprites/scanner_bottom")


		jdmg.materials.glow2 = Material("sprites/light_ignorez")
	end
end


jdmg.statuses = {}
do
	do
		jdmg.statuses.error = {}
		if CLIENT then
			jdmg.statuses.error.icon = create_material({
				Shader = "UnlitGeneric",
				BaseTexture = "error",
				VertexAlpha = 1,
				VertexColor = 1,
				Additive = 1,
				BaseTextureTransform = "center .5 .5 scale 0.7 0.5 rotate 90 translate 0 0",
			})
		end
	end

	do
		jdmg.statuses.poison = {}
		jdmg.statuses.poison.negative = true
		if CLIENT then
			jdmg.statuses.poison.icon = create_material({
				Shader = "UnlitGeneric",
				BaseTexture = "sprites/greenspit1",
				VertexAlpha = 1,
				VertexColor = 1,
				Additive = 1,
				BaseTextureTransform = "center .5 .5 scale 0.7 0.7 rotate 0 translate 0 0",
			})
		end
	end

	do
		jdmg.statuses.fire = {}
		jdmg.statuses.fire.negative = true
		if CLIENT then
			jdmg.statuses.fire.icon = create_material({
				Shader = "UnlitGeneric",
				BaseTexture = "editor/env_fire",
				VertexAlpha = 1,
				VertexColor = 1,
				BaseTextureTransform = "center 0.45 .1 scale 0.75 0.75 rotate 0 translate 0 0",
			})
		end
	end

	do
		jdmg.statuses.confused = {}
		jdmg.statuses.confused.negative = true
		if CLIENT then
			jdmg.statuses.confused.icon = create_material({
				Shader = "UnlitGeneric",
				BaseTexture = "editor/choreo_manager",
				VertexAlpha = 1,
				VertexColor = 1,
				BaseTextureTransform = "center 0.45 .1 scale 0.9 0.9 rotate 0 translate 0 -0.05",
			})
		end
	end

	do
		jdmg.statuses.frozen = {}
		jdmg.statuses.frozen.negative = true
		if CLIENT then
			jdmg.statuses.frozen.icon = create_material({
				Shader = "UnlitGeneric",
				BaseTexture = "editor/env_particles",
				VertexAlpha = 1,
				VertexColor = 1,
				BaseTextureTransform = "center 0.45 .1 scale 0.9 0.9 rotate 0 translate 0 -0.05",
			})

			jdmg.statuses.frozen.on_set = function(self, ent, b)
				if ent ~= LocalPlayer() then return end
				local t = RealTime()
				if b then
					local time = 0
					hook.Add("RenderScreenspaceEffects", "jdmg_decay", function()
						time = time + FrameTime()
						local f = math.min(time, 1) ^ 0.5
						if f ~= 1 then return end

						local hm = math.abs(math.sin(RealTime())^50)
						DrawMaterialOverlay("models/shadertest/shader4", hm*0.02)
					end)
					local played = false
					local function setup_fog()
						local f = math.min(time, 1) ^ 0.5

						render.FogMode(1)
						render.FogStart(-7000*f)
						render.FogEnd(500*f)
						render.FogMaxDensity(0.995*f)
						local hm = Lerp(f, 100, math.abs(math.sin(time + 0.3)^50*100))

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
						for k,v in pairs(hook.GetTable().SetupWorldFog) do self.old_hooks_world[k] = v hook.Remove("SetupWorldFog", k,v) end
					end

					self.old_hooks_skybox = {}
					if hook.GetTable().SetupSkyboxFog then
						for k,v in pairs(hook.GetTable().SetupSkyboxFog) do self.old_hooks_skybox[k] = v hook.Remove("SetupSkyboxFog", k,v) end
					end

					hook.Add("SetupWorldFog", "jdmg_decay", setup_fog)
					hook.Add("SetupSkyboxFog", "jdmg_decay", setup_fog)
				else
					hook.Remove("RenderScreenspaceEffects", "jdmg_decay")
					hook.Remove("SetupWorldFog", "jdmg_decay")
					hook.Remove("SetupSkyboxFog", "jdmg_decay")

					for k, v in pairs(self.old_hooks_world) do hook.Add("SetupWorldFog", k, v) end
					for k, v in pairs(self.old_hooks_skybox) do hook.Add("SetupSkyboxFog", k, v) end
				end
			end
		end
	end
end

jdmg.types = {}

do
	jdmg.types.generic = {}

	if CLIENT then
		local mat = create_overlay_material("models/effects/portalfunnel2_sheet")

		jdmg.types.generic.draw = function(ent, f, s, t)
			render.ModelMaterialOverride(mat)
			render.SetColorModulation(s,s,s)
			render.SetBlend(f)

			local m = mat:GetMatrix("$BaseTextureTransform")
			m:Identity()
			m:Scale(Vector(1,1,1)*0.15)
			m:Translate(Vector(1,1,1)*t/5)
			mat:SetMatrix("$BaseTextureTransform", m)

			draw_model(ent)
		end

		function jdmg.types.generic.draw_projectile(ent, dmg)
			local color = Color(255, 255, 255)
			local size = dmg / 100

			render.SetMaterial(jdmg.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jdmg.materials.glow2)
			render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(color.r, color.g, color.b, 150))

			jdmg.DrawTrail(ent, 0.4, 0, ent:GetPos(), jdmg.materials.trail, Color(color.r, color.g, color.b, 50), Color(color.r, color.g, color.b, 0), 10, 0, 1)
		end
	end
end

do
	jdmg.types.heal = {}

	if CLIENT then
		local mat = create_overlay_material("effects/filmscan256")

		jdmg.types.heal.draw = function(ent, f, s, t)
			if math.random() > 0.99 then
				ent:EmitSound("items/smallmedkit1.wav", 75, math.Rand(230,235), f)
			end

			render.ModelMaterialOverride(mat)
			render.SetColorModulation(0.75, 1*s, 0.75)
			render.SetBlend(f)

			local m = mat:GetMatrix("$BaseTextureTransform")
			m:Identity()
			m:Scale(Vector(1,1,1)*0.05)
			m:Translate(Vector(1,1,1)*t/20)
			mat:SetMatrix("$BaseTextureTransform", m)

			draw_model(ent)
		end
	end
end

do
	jdmg.types.dark = {}

	if CLIENT then
		local mat = create_overlay_material("effects/filmscan256", {Additive = 0, RimlightBoost = 1})
		jdmg.types.dark.sounds = {
			{
				path = "ambient/atmosphere/tone_quiet.wav",
				pitch = 150,
			}
		}
		--jdmg.types.dark.sound_path = "music/stingers/hl1_stinger_song28.mp3"
		--jdmg.types.dark.sound_path = "ambient/levels/citadel/extract_loop1.wav"
		--jdmg.types.dark.sound_path = "ambient/machines/laundry_machine1_amb.wav"
		--jdmg.types.dark.sound_path = "npc/antlion_guard/confused1.wav"

		jdmg.types.dark.draw = function(ent, f, s, t)
			if math.random() > 0.5 then
				ent:EmitSound("hl1/fvox/buzz.wav", 75, math.Rand(175,255), f)
			end

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

			draw_model(ent)

			ent:DisableMatrix("RenderMultiply")
		end

		function jdmg.types.dark.draw_projectile(ent, dmg)
			local color = Color(255, 50, 200)
			local size = dmg / 100

			render.SetMaterial(jdmg.materials.dark)
			for i = 1, 20 do
				render.DrawQuadEasy(ent:GetPos(), -EyeVector(), 32*size * math.random(), 32*size * math.random(), Color(color.r, color.g, color.b, 255), (i/20)*360)
			end

			render.SetMaterial(jdmg.materials.refract3)
			render.DrawSprite(ent:GetPos(), 64*size + math.sin(RealTime()*4)*10, 64*size + math.cos(RealTime()*4)*10, Color(255,255,255, 150 + math.sin(RealTime()*4)*50))

			jdmg.DrawTrail(ent, 0.1, 0, ent:GetPos(), jdmg.materials.dark, Color(color.r, color.g, color.b, 50), Color(color.r, color.g, color.b, 0), 30, 0, 2)
		end
	end
end

do
	jdmg.types.holy = {}

	if CLIENT then
		local mat = create_overlay_material("effects/splash2", {Additive = 0, RimlightBoost = 1})

		local sounds = {
			"ambient/levels/coast/coastbird4.wav",
			"ambient/levels/coast/coastbird5.wav",
			"ambient/levels/coast/coastbird6.wav",
			"ambient/levels/coast/coastbird7.wav",
		}

		jdmg.types.holy.sounds = {
			{
				path = "music/hl2_song10.mp3",
				pitch = 230,
			},
			{
				path = "physics/cardboard/cardboard_box_scrape_smooth_loop1.wav",
				pitch = 200,
			}
		}

		jdmg.types.holy.draw = function(ent, f, s, t)
			if math.random() > 0.95 then
				ent:EmitSound(table.Random(sounds), 75, math.Rand(100,120), f)
				ent:EmitSound("friends/friend_join.wav", 75, 255, f)
			end

			render.ModelMaterialOverride(mat)
			render.SetColorModulation(s*6,s*6,s*6)
			render.SetBlend(f)

			draw_model(ent)
		end

		function jdmg.types.holy.draw_projectile(ent, dmg)
			local color = Color(255, 200, 150)
			local size = dmg / 100

			render.SetMaterial(jdmg.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jdmg.materials.glow2)
			render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(color.r, color.g, color.b, 200))

			render.SetMaterial(jdmg.materials.refract3)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(255,255,255, 150))

			jdmg.DrawTrail(ent, 0.4, 0, ent:GetPos(), jdmg.materials.trail, Color(color.r, color.g, color.b, 50), Color(color.r, color.g, color.b, 0), 10, 0, 1)
		end
	end
end

do
	jdmg.types.lightning = {
		translate = {
			DMG_SHOCK = true,
		}
	}

	if CLIENT then
		local mat = create_overlay_material("sprites/lgtning")

		jdmg.types.lightning.draw = function(ent, f, s, t)
			if math.random() > 0.95 then
				ent:EmitSound("ambient/energy/zap"..math.random(1, 3)..".wav", 75, math.Rand(150,255), f)
			end

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

			draw_model(ent)
		end
	end
end

do
	jdmg.types.fire = {
		translate = {
			DMG_BURN = true,
			DMG_SLOWBURN = true,
		}
	}

	if CLIENT then
		local mat = create_overlay_material("models/props_lab/cornerunit_cloud")
		local flames ={}

		for i = 1, 5 do
			table.insert(flames, create_material({
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
			smoke[i] = create_material({
				Shader = "UnlitGeneric",
				BaseTexture = path,
				VertexAlpha = 1,
				VertexColor = 1,
			})
		end

		jdmg.types.fire.draw = function(ent, f, s, t)
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

				local p = emitter:Add(table.Random(flames), pos)
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
					local p = emitter:Add(table.Random(smoke), pos + VectorRand())
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


			render.ModelMaterialOverride(mat)
			render.SetColorModulation(2*s,1*s,0.5)
			render.SetBlend(f)

			local m = mat:GetMatrix("$BaseTextureTransform")
			m:Identity()
			m:Scale(Vector(1,1,1)*1.5)
			m:Translate(Vector(1,1,1)*t/5)
			mat:SetMatrix("$BaseTextureTransform", m)

			draw_model(ent)
		end

		function jdmg.types.fire.draw_projectile(ent, dmg)
			local color = Color(255, 130, 0)
			local size = dmg / 100

			render.SetMaterial(jdmg.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jdmg.materials.glow2)
			render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(color.r, color.g, color.b, 150))

			jdmg.DrawTrail(ent, 0.4, 0, ent:GetPos(), jdmg.materials.trail, Color(color.r, color.g, color.b, 50), Color(color.r, color.g, color.b, 0), 10, 0, 1)

			local p = emitter:Add(table.Random(flames), ent:GetPos())
			p:SetStartSize(math.Rand(5,10))
			p:SetEndSize(math.Rand(5,10))
			p:SetStartAlpha(255)
			p:SetEndLength(math.Rand(p:GetEndSize(),20))
			p:SetEndAlpha(0)
			p:SetColor(math.Rand(230,255),math.Rand(230,255),math.Rand(230,255))
			p:SetGravity(physenv.GetGravity()*-0.25)
			p:SetRoll(math.random()*360)
			p:SetAirResistance(5)
			p:SetLifeTime(0.25)
			p:SetDieTime(math.Rand(0.25,0.75))
		end
	end
end

do
	jdmg.types.water = {
		translate = {
			DMG_DROWN = true,
		}
	}

	if CLIENT then
		local mat = create_overlay_material("effects/filmscan256")

		local water = {
			"particle/particle_noisesphere",
			"effects/splash1",
			"effects/splash2",
			"effects/splash4",
			"effects/blood",

		}

		jdmg.types.water.draw = function(ent, f, s, t)
			if math.random() > 0.8 then
				ent:EmitSound("ambient/water/wave"..math.random(1,6)..".wav", 75, math.Rand(200,255), f)
			end

			local pos = ent:GetBoneMatrix(math.random(1, ent:GetBoneCount()))
			if pos then
				pos = pos:GetTranslation()

				local p = emitter:Add(table.Random(water), pos + VectorRand() * 5)
				p:SetStartSize(20)
				p:SetEndSize(20)
				p:SetStartAlpha(50*f)
				p:SetEndAlpha(0)
				p:SetVelocity(VectorRand()*10)
				p:SetGravity(physenv.GetGravity()*0.025)
				p:SetColor(100, 200, 255)
				--p:SetLighting(true)
				p:SetRoll(math.random())
				p:SetRollDelta(math.random()*2-1)
				p:SetLifeTime(1)
				p:SetDieTime(math.Rand(0.75,1.5)*2)
			end

			render.ModelMaterialOverride(mat)
			render.SetColorModulation(0.5,0.75,1*s)
			render.SetBlend(f)

			local m = mat:GetMatrix("$BaseTextureTransform")
			m:Identity()
			m:Scale(Vector(1,1,1)*0.05)
			m:Translate(Vector(1,1,1)*t/20)
			mat:SetMatrix("$BaseTextureTransform", m)

			draw_model(ent)
		end

		function jdmg.types.water.draw_projectile(ent, dmg)
			local p = emitter:Add(table.Random(water), ent:GetPos())
			p:SetStartSize(20)
			p:SetEndSize(20)
			p:SetStartAlpha(50)
			p:SetEndAlpha(0)
			p:SetVelocity(VectorRand()*10)
			p:SetGravity(physenv.GetGravity()*0.025)
			p:SetColor(100, 200, 255)
			--p:SetLighting(true)
			p:SetRoll(math.random())
			p:SetRollDelta(math.random()*2-1)
			p:SetLifeTime(1)
			p:SetDieTime(math.Rand(0.75,1.5)*2)
		end
	end
end

do
	jdmg.types.ice = {}

	if CLIENT then
		local mat = create_overlay_material("effects/filmscan256")

		local ice_mat = create_material({
			Name = "magic_ice",
			Shader = "VertexLitGeneric",
			CloakPassEnabled = 1,
			RefractAmount = 1,
		})
		local color = Color(100, 200, 255)

		jdmg.types.ice.draw = function(ent, f, s, t)
			local pos = ent:NearestPoint(ent:WorldSpaceCenter()+VectorRand()*100)

			local p = emitter:Add("effects/splash1", pos + VectorRand() * 20)
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

			local c = Vector(color.r/255, color.g/255, color.b/255)*5*(f^0.15)
			ice_mat:SetVector("$CloakColorTint", c)
			ice_mat:SetFloat("$CloakFactor", 0.5*(f))
			ice_mat:SetFloat("$RefractAmount", -f+1)
			render.ModelMaterialOverride(ice_mat)
			render.SetColorModulation(0.5,0.75, 1*s)
			render.SetBlend(f)
			draw_model(ent)
		end

		util.PrecacheModel("models/pac/default.mdl")

		local rocks = {
			"models/props_wasteland/rockcliff01b.mdl",
			"models/props_wasteland/rockcliff01c.mdl",
			"models/props_wasteland/rockcliff01e.mdl",
			"models/props_wasteland/rockcliff01f.mdl",
			"models/props_wasteland/rockcliff01g.mdl",
			"models/props_wasteland/rockcliff01j.mdl",
			"models/props_wasteland/rockcliff01k.mdl",
		}

		for i, v in ipairs(rocks) do
			util.PrecacheModel(v)
		end


		jdmg.types.ice.draw_projectile = function(ent, dmg)
			local size = dmg / 100

			render.SetMaterial(jdmg.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jdmg.materials.glow2)
			render.DrawSprite(ent:GetPos(), 128*size, 128*size, Color(color.r, color.g, color.b, 150))

			jdmg.DrawTrail(ent, 0.4, 0, ent:GetPos(), jdmg.materials.trail, Color(color.r, color.g, color.b, 50), Color(color.r, color.g, color.b, 0), 10, 0, 1)


			if not ent.next_emit or ent.next_emit < RealTime() then
				local life_time = 2

				local ice = ents.CreateClientProp()
				SafeRemoveEntityDelayed(ice, life_time)

				ice:SetModel(table.Random(rocks))

				ice:SetPos(ent:GetPos())
				ice:SetAngles(VectorRand():Angle())
				ice:SetModelScale(math.Rand(0.1, 0.2)*0.3)

				ice:SetRenderMode(RENDERMODE_TRANSADD)

				ice.life_time = RealTime() + life_time
				ice:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
				ice:PhysicsInitSphere(5)
				local phys = ice:GetPhysicsObject()
				phys:Wake()
				phys:EnableGravity(false)
				phys:AddVelocity(VectorRand()*20)
				phys:AddAngleVelocity(VectorRand()*20)

				ice.RenderOverride = function()

					local f = (ice.life_time - RealTime()) / life_time
					local f2 = math.sin(f*math.pi) ^ 0.5

					local c = Vector(color.r/255, color.g/255, color.b/255)*5*(f2^0.5)
					ice_mat:SetVector("$CloakColorTint", c)
					ice_mat:SetFloat("$CloakFactor", 0.5*(f2))
					ice_mat:SetFloat("$RefractAmount", -f+1)

					render.MaterialOverride(ice_mat)
						render.SetBlend(f2)
							render.SetColorModulation(c.x, c.y, c.z)
								ice:DrawModel()
							render.SetColorModulation(1,1,1)
						render.SetBlend(1)
					render.MaterialOverride()

					local phys = ice:GetPhysicsObject()
					phys:AddVelocity(phys:GetVelocity()*-FrameTime()*2 + Vector(0,0,-FrameTime()*(-f+1)*30))
				end

				ent.next_emit = RealTime() + 0.02
			end
		end
	end
end

do
	jdmg.types.poison = {
		translate = {
			DMG_RADIATION = true,
			DMG_NERVEGAS = true,
			DMG_ACID = true,
		},
	}

	if CLIENT then
		local mat = create_overlay_material("effects/filmscan256")
		jdmg.types.poison.sounds = {
			{
				path = "ambient/gas/cannister_loop.wav",
				pitch = 200,
			},
		}

		jdmg.types.poison.draw = function(ent, f, s, t)
			if math.random() > 0.95 then
				ent:EmitSound("ambient/levels/canals/toxic_slime_sizzle"..math.random(2, 4)..".wav", 75, math.Rand(120,170), f)
			end

			local pos = ent:GetBoneMatrix(math.random(1, ent:GetBoneCount()))
			if pos then
				pos = pos:GetTranslation()

				local p = emitter:Add("effects/splash1", pos + VectorRand() * 20)
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

			draw_model(ent)
		end
		local color = Color(0,255,0)
		jdmg.types.poison.draw_projectile = function(ent, dmg)
			local size = dmg / 100

			render.SetMaterial(jdmg.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jdmg.materials.glow2)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 150))

			--jdmg.DrawTrail(ent, 1, 0, ent:GetPos(), jdmg.materials.trail, Color(color.r, color.g, color.b, 50), Color(color.r, color.g, color.b, 0), 10, 0, 1)

			local p = emitter:Add("effects/bubble", ent:GetPos() + VectorRand() * 5)
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
end

if CLIENT then
	for k,v in pairs(jdmg.types) do
		if not v.draw_projectile then
			v.draw_projectile = jdmg.types.generic.draw_projectile
		end
	end
end

function jdmg.BuildEnums()
	local magic = 2523

	local list = {}
	for k,v in pairs(jdmg.types) do
		table.insert(list, k)
	end

	jdmg.enums = {}
	jdmg.enums_lookup = {}

	for i, name in ipairs(list) do
		local val = magic + i - 1
		jdmg.enums[name] = val
		jdmg.enums_lookup[val] = name
		_G["JDMG_" .. name:upper()] = val
	end
end

function jdmg.GetDamageType(dmginfo)
	return jdmg.enums_lookup[dmginfo:GetDamageCustom()]
end

jdmg.BuildEnums()

do -- status
	for name, status in pairs(jdmg.statuses) do
		status.name = name
		status.__index = status
	end

	for _, ent in pairs(ents.GetAll()) do
		if ent.jdmg_statuses then
			for i, v in ipairs(ent.jdmg_statuses) do
				if ent.jdmg_statuses[i].on_set then
					ent.jdmg_statuses[i]:on_set(ent, false)
				end
				ent.jdmg_statuses[i] = setmetatable({}, jdmg.statuses[v.name])

				if ent.jdmg_statuses[i].on_set then
					ent.jdmg_statuses[i]:on_set(ent, true)
				end
			end
		end
	end

	function jdmg.GetStatuses(ent)
		ent.jdmg_statuses = ent.jdmg_statuses or {}
		return ent.jdmg_statuses
	end

	if CLIENT then
		net.Receive("jdmg_status", function()
			local ent = net.ReadEntity()
			if not ent:IsValid() then return end
			local status = net.ReadString()
			local b = net.ReadBool()

			ent.jdmg_statuses = ent.jdmg_statuses or {}

			if b then
				for i, v in ipairs(ent.jdmg_statuses) do
					if v.name == status then
						return
					end
				end

				local status = jdmg.statuses[status]
				if status then
					status.__index = status
					status = setmetatable({}, status)

					if status.on_set then
						status:on_set(ent, true)
					end

					table.insert(ent.jdmg_statuses, status)
				end
			else
				for i, v in ipairs(ent.jdmg_statuses) do
					if v.name == status then
						if v.on_set then
							v:on_set(ent, false)
						end
						table.remove(ent.jdmg_statuses, i)
						break
					end
				end
			end
		end)
	end

	if SERVER then
		util.AddNetworkString("jdmg_status")

		function jdmg.SetStatus(ent, status, b)

			net.Start("jdmg_status", true)
				net.WriteEntity(ent)
				net.WriteString(status)
				net.WriteBool(b)
			net.Broadcast()
		end
	end
end

if CLIENT then
	local active = {}

	local aaaaa

	local function render_jdmg()
		cam.Start3D()
		local time = RealTime()
		for i = #active, 1, -1 do
			local data = active[i]

			local f = (data.time - time) / data.duration
			f = f ^ data.pow

			if f <= 0 or not data.ent:IsValid() then
				table.remove(active, i)
			else
				if data.ent.pac_parts then
					for k,v in pairs(data.ent.pac_parts) do
						for _, part in ipairs(v:GetChildrenList()) do
							if part.ClassName == "model" and not part:IsHidden() and part:GetEntity():IsValid() then
								data.type.draw(part:GetEntity(), f, data.strength, time + data.time_offset)
							end
						end
					end
				end

				if data.ent:IsPlayer() and not data.ent:Alive() then
					local rag = data.ent:GetRagdollEntity()
					if rag then
						data.type.draw(data.ent, f, data.strength, time + data.time_offset)
					end
				else
					data.type.draw(data.ent, f, data.strength, time + data.time_offset)
				end
			end
		end

		render.SetColorModulation(1,1,1)
		render.ModelMaterialOverride()
		render.SetBlend(1)

		if not active[1] then
			hook.Remove("RenderScreenspaceEffects", "jdmg")
		end
		cam.End3D()
	end

	function jdmg.DamageEffect(ent, type, duration, strength, pow)
		type = jdmg.types[type] or types.generic
		duration = duration or 1
		strength = strength or 1
		pow = pow or 3

		table.insert(active, {
			ent = ent,
			type = type,
			duration = duration,
			strength = strength,
			pow = pow,
			time = RealTime() + duration,
			time_offset = math.random(),
		})

		if #active == 1 then
			hook.Add("RenderScreenspaceEffects", "jdmg", render_jdmg)
		end
	end

	net.Receive("jdmg", function()
		local ent = net.ReadEntity() -- todo use enums lol
		local type = net.ReadString()
		local duration = net.ReadFloat()
		local strength = net.ReadFloat()
		local pos = net.ReadVector()

		if ent:IsPlayer() then
			local name = "flinch_stomach_0" .. math.random(2)
			local bone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Neck")

			if bone and pos:Distance(ent:WorldToLocal(ent:GetBonePosition(bone))) < 20 or pos:Distance(ent:WorldToLocal(ent:EyePos())) < 20 then
				name = "flinch_head_0" .. math.random(2)
			elseif strength > 0.5 then
				name = "flinch_phys_0" .. math.random(2)
			end

			local seq = ent:GetSequenceActivity(ent:LookupSequence(name))
			ent:AnimRestartGesture(GESTURE_SLOT_FLINCH, seq, true)
		end

		jdmg.DamageEffect(ent, type, duration, strength)
	end)
end

if SERVER then
	function jdmg.DamageEffect(ent, type, duration, strength, pos)
		type = type or "generic"
		duration = duration or 1
		strength = strength or 1

		net.Start("jdmg", true)
			net.WriteEntity(ent)
			net.WriteString(type)
			net.WriteFloat(duration)
			net.WriteFloat(strength)
			net.WriteVector(pos or vector_origin)
		net.Broadcast()
	end

	util.AddNetworkString("jdmg")

	local lookup = {}
	local enums = {}

	for key, val in pairs(_G) do
		if type(key) == "string" and key:StartWith("DMG_") and type(val) == "number" then
			lookup[val] = key
			enums[key] = val
		end
	end

	hook.Add("EntityTakeDamage", "jdmg", function(ent, dmginfo)
		if ent:GetNoDraw() then return end

		local pos = ent:WorldToLocal(dmginfo:GetDamagePosition())
		local type = dmginfo:GetDamageType()
		local dmg = dmginfo:GetDamage()
		local max_health = math.max(ent:GetMaxHealth(), 1)
		local fraction = dmg/max_health

		local duration = math.Clamp(dmg/50, 0.5, 4)
		local strength = math.max((fraction^0.5) * 2, 0.5)

		local override = jdmg.GetDamageType(dmginfo)

		if override then
			jdmg.DamageEffect(ent, override, duration, strength, pos)
			if override == "lightning" then
				dmginfo:SetDamageType(DMG_DISSOLVE)
			end
		else
			local done = {}
			for k, v in pairs(enums) do
				if bit.band(type, v) > 0 and not done[lookup[v]] then
					local hl2_name = lookup[v]
					local jdmg_name = "generic"

					for name, info in pairs(jdmg.types) do
						if info.translate and info.translate[hl2_name] then
							jdmg_name = name
							break
						end
					end

					jdmg.DamageEffect(ent, jdmg_name, duration, strength, pos)

					done[hl2_name] = true
				end
			end
		end
	end)
end