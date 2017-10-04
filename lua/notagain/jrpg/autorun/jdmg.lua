jdmg = jdmg or {}

local emitter
local create_overlay_material
local draw_model
local jfx

if CLIENT then
	jfx = requirex("jfx")

	draw_model = function(ent)
		if ent.pacDrawModel then
			ent:pacDrawModel(true)
		else
			ent:DrawModel()
		end
	end
	emitter = ParticleEmitter(vector_origin)

	create_overlay_material = function(tex, override)
		override = override or {}
		return jfx.CreateMaterial(table.Merge({
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
end


jdmg.statuses = {}
do
	do
		jdmg.statuses.error = {}
		if CLIENT then
			jdmg.statuses.error.icon = jfx.CreateMaterial({
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
			jdmg.statuses.poison.icon = jfx.CreateMaterial({
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
			jdmg.statuses.fire.icon = jfx.CreateMaterial({
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
			jdmg.statuses.confused.icon = jfx.CreateMaterial({
				Shader = "UnlitGeneric",
				BaseTexture = "editor/choreo_manager",
				VertexAlpha = 1,
				VertexColor = 1,
				BaseTextureTransform = "center 0.45 .1 scale 0.9 0.9 rotate 0 translate 0 -0.05",
			})
		end
	end

	do
		jdmg.statuses.lightning = {}
		jdmg.statuses.lightning.negative = true
		if CLIENT then
			jdmg.statuses.lightning.icon = jfx.CreateMaterial({
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
			jdmg.statuses.frozen.icon = jfx.CreateMaterial({
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

		local color = Color(255, 255, 255)
		jdmg.types.generic.color = color

		function jdmg.types.generic.draw_projectile(ent, dmg, simple)
			local size = dmg / 100

			render.SetMaterial(jfx.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jfx.materials.glow2)
			render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(color.r, color.g, color.b, 150))

			if not simple then
				jfx.DrawTrail(ent, 0.4, 0, ent:GetPos(), jfx.materials.trail, color.r, color.g, color.b, 50, color.r, color.g, color.b, 0, 10, 0, 1)
			end
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

		jdmg.types.dark.think = function(ent, f, s, t)
				if math.random() > 0.5 then
				ent:EmitSound("hl1/fvox/buzz.wav", 75, math.Rand(175,255), f)
			end
		end
		jdmg.types.dark.draw = function(ent, f, s, t)
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

		local dark = Material("effects/bluespark")

		local color = Color(255, 50, 200)
		jdmg.types.dark.color = color
		function jdmg.types.dark.draw_projectile(ent, dmg, simple)
			local size = dmg / 100

			jfx.DrawSprite(jfx.materials.refract2, ent:GetPos(), 60*size, nil,0, 10,2,0, 255)

			render.SetMaterial(dark)
			for i = 1, 20 do
				render.DrawQuadEasy(ent:GetPos(), -EyeVector(), 32*size * math.random(), 32*size * math.random(), Color(color.r, color.g, color.b, 255), (i/20)*360)
			end

			render.SetMaterial(jfx.materials.refract3)
			render.DrawSprite(ent:GetPos(), 60*size + math.sin(RealTime()*4)*3, 60*size + math.cos(RealTime()*4)*3, Color(255,255,255, 30 + (math.sin(RealTime()*4)*0.5+0.5)*50))

			if not simple then
				jfx.DrawTrail(ent, 0.1, 0, ent:GetPos(), dark, color.r, color.g, color.b, 50, color.r, color.g, color.b, 0, 30, 0, 2)
			end
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

		jdmg.types.holy.think = function(ent, f, s, t)
			if math.random() > 0.95 then
				ent:EmitSound(table.Random(sounds), 75, math.Rand(100,120), f)
				ent:EmitSound("friends/friend_join.wav", 75, 255, f)
			end
		end
		jdmg.types.holy.draw = function(ent, f, s, t)
			render.ModelMaterialOverride(mat)
			render.SetColorModulation(s*6,s*6,s*6)
			render.SetBlend(f)

			draw_model(ent)
		end

		local color = Color(255, 200, 150)
		jdmg.types.holy.color = color

		local feather_mat = jfx.CreateMaterial({
			Shader = "VertexLitGeneric",

			BaseTexture = "https://cdn.discordapp.com/attachments/273575417401573377/291905352876687360/feather.png",
			VertexColor = 1,
			VertexAlpha = 1,
		})

		function jdmg.types.holy.draw_projectile(ent, dmg, simple, vis)
			local size = dmg / 100

			render.SetMaterial(jfx.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jfx.materials.glow2)
			render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(color.r, color.g, color.b, 200))

			render.SetMaterial(jfx.materials.refract3)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(255,255,255, 150))

			if not simple then

				for i = 1, 3 do
					local pos = ent:GetPos()
					pos = pos + Vector(jfx.GetRandomOffset(pos, i, 2))*size*10

					ent.trail_data = ent.trail_data or {}
					ent.trail_data[i] = ent.trail_data[i] or {}
					jfx.DrawTrail(ent.trail_data[i], 0.25, 0, pos, jfx.materials.trail, color.r, color.g, color.b, 255, color.r, color.g, color.b, 0, 15*size, 0)
				end

				render.SetMaterial(jfx.materials.glow)
				render.DrawSprite(ent:GetPos(), 200*size, 200*size, Color(color.r, color.g, color.b, 50))


				if not ent.next_emit or ent.next_emit < RealTime() then
					local life_time = 2

					local feather = ents.CreateClientProp()
					SafeRemoveEntityDelayed(feather, life_time)

					feather:SetModel("models/pac/default.mdl")
					feather:SetPos(ent:GetPos() + (VectorRand()*size))
					feather:SetAngles(VectorRand():Angle())
					feather:SetModelScale(size)

					feather:SetRenderMode(RENDERMODE_TRANSADD)

					feather.life_time = RealTime() + life_time
					feather:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
					feather:PhysicsInitSphere(5)
					local phys = feather:GetPhysicsObject()
					phys:Wake()
					phys:EnableGravity(false)
					phys:AddVelocity(VectorRand()*20)
					phys:AddAngleVelocity(VectorRand()*20)

					local m = Matrix()
					m:Translate(Vector(0,20,0)*size)
					m:Scale(Vector(1,1,1))
					feather:EnableMatrix("RenderMultiply", m)

					feather.RenderOverride = function()
						local f = (feather.life_time - RealTime()) / 2
						if f <= 0 then return end
						local f2 = math.sin((-f+1)*math.pi)


						render.SuppressEngineLighting(true)
						render.SetColorModulation(color.r/200, color.g/200, color.b/200)
						render.SetBlend(f2)

						render.MaterialOverride(feather_mat)
						render.SetMaterial(feather_mat)
						render.CullMode(MATERIAL_CULLMODE_CW)
						feather:DrawModel()
						render.CullMode(MATERIAL_CULLMODE_CCW)
						feather:DrawModel()
						render.MaterialOverride()
						render.SuppressEngineLighting(false)

						local phys = feather:GetPhysicsObject()
						phys:AddVelocity(Vector(0,0,-FrameTime()*100)*size)

						local vel = phys:GetVelocity()

						if vel.z < 0 then
							local delta= FrameTime()*2
							phys:AddVelocity(Vector(-vel.x*delta,-vel.y*delta,-vel.z*delta*2)*size)
						end
					end

					feather:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
					feather:PhysicsInitSphere(5)

					local phys = feather:GetPhysicsObject()
					phys:EnableGravity(false)
					phys:AddVelocity(Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(1, 2))*20*size)
					phys:AddAngleVelocity(VectorRand()*50)
					feather:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

					ent.next_emit = RealTime() + math.random()*0.25
				end
			end
		end
	end
end


do
	jdmg.types.heal = {}

	if CLIENT then
		local mat = create_overlay_material("effects/filmscan256")

		jdmg.types.heal.think = function(ent, f, s, t)
			if math.random() > 0.9 then
				ent:EmitSound("items/smallmedkit1.wav", 75, math.Rand(230,235), f)
			end
		end
		jdmg.types.heal.draw = function(ent, f, s, t)
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

		local color = Color(150, 255, 150)
		jdmg.types.heal.color = color

		function jdmg.types.heal.draw_projectile(ent, dmg, simple, vis)
			local size = dmg / 100

			render.SetMaterial(jfx.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jfx.materials.glow2)
			render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(color.r, color.g, color.b, 200))

			render.SetMaterial(jfx.materials.refract3)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(255,255,255, 150))

			if not simple then

				for i = 1, 3 do
					local pos = ent:GetPos()
					pos = pos + Vector(jfx.GetRandomOffset(pos, i, 2))*size*10

					ent.trail_data = ent.trail_data or {}
					ent.trail_data[i] = ent.trail_data[i] or {}
					jfx.DrawTrail(ent.trail_data[i], 0.25, 0, pos, jfx.materials.trail, color.r, color.g, color.b, 255, color.r, color.g, color.b, 0, 15*size, 0)
				end

				render.SetMaterial(jfx.materials.glow)
				render.DrawSprite(ent:GetPos(), 200*size, 200*size, Color(color.r, color.g, color.b, 50))
			end
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

		jdmg.types.lightning.think = function(ent, f, s, t)
			if math.random() > 0.95 then
				ent:EmitSound("ambient/energy/zap"..math.random(1, 3)..".wav", 75, math.Rand(150,255), f)
			end
		end

		local color = Color(230, 230, 255)
		jdmg.types.lightning.color = color

		jdmg.types.lightning.draw = function(ent, f, s, t)
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

		local arc = jfx.CreateMaterial({
			Shader = "UnlitGeneric",

			BaseTexture = "https://cdn.discordapp.com/attachments/273575417401573377/291918796027985920/lightning.png",
			BaseTextureTransform = "center .5 .5 scale 2 2 rotate 0 translate -0.45 -0.45",
			Additive = 1,
			VertexColor = 1,
			VertexAlpha = 1,
		})

		function jdmg.types.lightning.draw_projectile(ent, dmg, simple, vis)
			local size = dmg / 100

			render.SetMaterial(jfx.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jfx.materials.glow2)
			render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(color.r, color.g, color.b, 200))

			render.SetMaterial(jfx.materials.refract3)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(255,255,255, 150))
			if not simple then

				render.SetMaterial(jfx.materials.glow)
				render.DrawSprite(ent:GetPos(), 200*size, 200*size, Color(color.r, color.g, color.b, 50))



				if not ent.next_emit or ent.next_emit < RealTime() then
					jfx.DrawSprite(arc, ent:GetPos(), 25*size + math.random(-20,20), 25*size + math.random(-20,20) * (math.random()^4*10), math.random(360), color.r,color.g,color.b,255)
					ent.next_emit = RealTime() + math.random()*0.05
				end
			end
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

		jdmg.types.fire.think = function(ent, f, s, t)
			if math.random() > 0.98 then
				ent:EmitSound("ambient/fire/mtov_flame2.wav", 75, math.Rand(50,100), f)
			end
		end

		jdmg.types.fire.draw = function(ent, f, s, t)
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

		local trail = jfx.CreateMaterial({
			Shader = "UnlitGeneric",

			BaseTexture = "particle/fire",
			Additive = 1,
			VertexColor = 1,
			VertexAlpha = 1,
		})

		local color = Color(255, 125, 25)
		jdmg.types.fire.color = color
		function jdmg.types.fire.draw_projectile(ent, dmg, simple)
			local size = dmg / 200


			jfx.DrawSprite(jfx.materials.glow, ent:GetPos(), 100*size, nil, 0, color.r,color.g,color.b,255, 2)
			jfx.DrawSprite(jfx.materials.refract2, ent:GetPos(), 32*size, nil,0, 10,2,0, 255)


			jfx.DrawSprite(jfx.materials.glow, ent:GetPos(), 256*size, nil, 0, color.r, color.g, color.b, 20)

			if not simple then
				for i = 1, 7 do
					local pos = ent:GetPos()
					pos = pos + Vector(jfx.GetRandomOffset(pos, i, 2))*size*40

					math.randomseed(i+ent:EntIndex())
					local rand = (math.random()^2)*3

					ent.trail_data = ent.trail_data or {}
					ent.trail_data[i] = ent.trail_data[i] or {}
					jfx.DrawTrail(ent.trail_data[i], 0.2*rand, 0, pos, jfx.materials.trail, color.r, color.g, color.b, 255, color.r*1.5, color.g*1.5, color.b*1.5, 0, 7*rand*size, 0)
				end

				math.randomseed(os.clock())
			end

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

		jdmg.types.water.think = function(ent, f, s, t)
			if math.random() > 0.8 then
				ent:EmitSound("ambient/water/wave"..math.random(1,6)..".wav", 75, math.Rand(200,255), f)
			end
		end

		local color = Color(50, 200, 255)
		jdmg.types.water.color = color

		jdmg.types.water.draw = function(ent, f, s, t)
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
				p:SetColor(color.r, color.g, color.b)
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

		local refract = jfx.CreateMaterial({
			Shader = "Refract",
			NormalMap = "http://files.gamebanana.com/bitpit/psfixnormal.jpg",
			RefractAmount = -0.4,
			VertexColor = 1,
			VertexAlpha = 1,
			Translucent = 1,
			Additive = 1,
			ForceRefract = 1,
			BlurAmount = 1,
			NoFog = 1,
			VertexColorModulate = 1,
		})

		function jdmg.types.water.draw_projectile(ent, dmg, simple, vis)
			local size = dmg / 100

			render.SetMaterial(jfx.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jfx.materials.glow2)
			render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(color.r, color.g, color.b, 200))

			render.SetMaterial(jfx.materials.refract3)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(255,255,255, 100))

			if simple then return end

			for i = 1, 2 do
				local pos = ent:GetPos()
				pos = pos + Vector(jfx.GetRandomOffset(pos, i, 2))*size*80

				math.randomseed(i+ent:EntIndex())
				local rand = (math.random()^2)*3


				ent.trail_data = ent.trail_data or {}
				ent.trail_data[i] = ent.trail_data[i] or {}
				--jfx.DrawTrail(ent.trail_data[i], 0.25*rand, 0, pos, jfx.materials.trail, color.r, color.g, color.b, 5, color.r*1.5, color.g*1.5, color.b*1.5, 0, 30*rand*size, 1)
				jfx.DrawTrail(ent.trail_data[i], 0.5*rand, 0, pos, refract, color.r,color.g,color.b, 255, color.r,color.g,color.b, 30*size, 15*rand*size,0)
			end

			math.randomseed(os.clock())

			local p = emitter:Add(refract, ent:GetPos())
			p:SetStartSize(0)
			p:SetEndSize(20)
			p:SetStartAlpha(30)
			p:SetEndAlpha(0)
			p:SetVelocity(VectorRand()*10)
			p:SetGravity(physenv.GetGravity()*0.05)
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
	jdmg.types.wind = {}

	if CLIENT then
		local mat = create_overlay_material("effects/filmscan256")

		local wind = {
			"particle/particle_noisesphere",
			"effects/splash1",
			"effects/splash2",
			"effects/splash4",
			"effects/blood",

		}

		jdmg.types.wind.think = function(ent, f, s, t)
			if math.random() > 0.8 then
				ent:EmitSound("ambient/wind/wind_hit"..math.random(1,3)..".wav", 75, math.Rand(150,180), f)
			end
		end

		local color = Color(255, 255, 255)
		jdmg.types.wind.color = color

		jdmg.types.wind.draw = function(ent, f, s, t)
			render.ModelMaterialOverride(mat)
			render.SetColorModulation(1,1,1*s)
			render.SetBlend(f)

			local m = mat:GetMatrix("$BaseTextureTransform")
			m:Identity()
			m:Scale(Vector(1,1,1)*0.05)
			m:Translate(Vector(1,1,1)*t/20)
			mat:SetMatrix("$BaseTextureTransform", m)

			draw_model(ent)
		end
		local trail = Material("particle/smokesprites_0009")


		local trail = jfx.CreateMaterial({
			Shader = "UnlitGeneric",

			BaseTexture = "particle/particle_smokegrenade",
			Additive = 0,
			VertexColor = 1,
			VertexAlpha = 1,
		})

		function jdmg.types.wind.draw_projectile(ent, dmg, simple)
			local size = dmg / 100

			render.SetMaterial(jfx.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jfx.materials.glow2)
			render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(color.r, color.g, color.b, 200))

			render.SetMaterial(jfx.materials.refract3)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(255,255,255, 100))

			if simple then return end

			for i = 1, 4 do
				local pos = ent:GetPos()
				pos = pos + Vector(jfx.GetRandomOffset(pos, i, 1))*size*50

				math.randomseed(i+ent:EntIndex())
				local rand = (math.random()^2) + 1

				ent.trail_data = ent.trail_data or {}
				ent.trail_data[i] = ent.trail_data[i] or {}
				jfx.DrawTrail(ent.trail_data[i], 0.4*rand, 0, pos, trail, color.r, color.g, color.b, 50, color.r, color.g, color.b, 0, 60*size, 0, 1)
			end
			math.randomseed(os.clock())
		end
	end
end

do
	jdmg.types.ice = {}

	if CLIENT then
		local mat = create_overlay_material("effects/filmscan256")

		local ice_mat = jfx.CreateMaterial({
			Name = "magic_ice",
			Shader = "VertexLitGeneric",
			CloakPassEnabled = 1,
			RefractAmount = 1,
		})
		local color = Color(100, 200, 255)
		jdmg.types.ice.color = color
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


		jdmg.types.ice.draw_projectile = function(ent, dmg, simple)
			local size = dmg / 100

			render.SetMaterial(jfx.materials.glow)
			render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(color.r, color.g, color.b, 255))

			render.SetMaterial(jfx.materials.glow2)
			render.DrawSprite(ent:GetPos(), 128*size, 128*size, Color(color.r, color.g, color.b, 150))

			if not simple then

				jfx.DrawTrail(ent, 0.4, 0, ent:GetPos(), jfx.materials.trail, color.r, color.g, color.b, 50, color.r, color.g, color.b, 0, 10, 0, 1)


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

		jdmg.types.poison.think = function(ent, f, s, t)
			if math.random() > 0.95 then
				ent:EmitSound("ambient/levels/canals/toxic_slime_sizzle"..math.random(2, 4)..".wav", 75, math.Rand(120,170), f)
			end
		end

		jdmg.types.poison.draw = function(ent, f, s, t)
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
		local color = Color(100,255,100)
		jdmg.types.poison.color = color
		jdmg.types.poison.draw_projectile = function(ent, dmg, simple)
			local size = dmg / 100


			render.SetMaterial(jfx.materials.refract)
			render.DrawSprite(ent:GetPos(), 20*size, 20*size, Color(color.r/4, color.g/4, color.b/4, 255))

			if simple then return end

			--jfx.DrawTrail(ent, 1, 0, ent:GetPos(), jfx.materials.trail, color.r, color.g, color.b, 50, color.r, color.g, color.b, 0, 10, 0, 1)

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
				if data.type.think then
					data.type.think(data.ent, f, data.strength, time + data.time_offset)
				end

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

		if ent:IsPlayer() and type ~= "heal" then
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
		local fraction = math.abs(dmg)/max_health

		local duration = math.Clamp(math.abs(dmg)/50, 0.5, 4)
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