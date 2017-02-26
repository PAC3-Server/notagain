jdmg = jdmg or {}

if CLIENT then
	local function create_material(data)
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

	local types = {}

	do
		--[[
			models/weapons/v_smg1/noise
			particle/particle_smokegrenade
			effects/filmscan256
			effects/splash2
			effects/combineshield/comshieldwall
			models/brokenglass/glassbroken_piece1_mask
			models/alyx/emptool_glow
			models/effects/dust01
			models/effects/portalfunnel2_sheet
			models/effects/comball_sphere
			models/effects/com_shield001a
			models/effects/splode_sheet
			models/player/player_chrome1
			models/props_combine/pipes01
			models/props_combine/introomarea_glassmask
			models/props_combine/tprings_globe_dx70
			models/props_combine/stasisshield_dx7
			models/props_lab/warp_sheet
		]]

		local function create_mat(tex, override)
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
			local mat = create_mat("models/effects/portalfunnel2_sheet")

			types.generic = {
				draw = function(ent, f, s, t)
					render.ModelMaterialOverride(mat)
					render.SetColorModulation(s,s,s)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*0.15)
					m:Translate(Vector(1,1,1)*t/5)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end


		do
			local mat = create_mat("effects/filmscan256", {Additive = 0, RimlightBoost = 1})

			types.dark = {
				draw = function(ent, f, s, t)
					render.ModelMaterialOverride(mat)
					render.SetColorModulation(-s,-s,-s)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*0.15)
					m:Translate(Vector(1,1,1)*t/5)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end

		do
			local mat = create_mat("models/props_lab/cornerunit_cloud")

			types.fire = {
				draw = function(ent, f, s, t)
					render.ModelMaterialOverride(mat)
					render.SetColorModulation(2*s,1*s,0.5)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*1.5)
					m:Translate(Vector(1,1,1)*t/5)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end

		do
			local mat = create_mat("effects/filmscan256")

			local emitter = ParticleEmitter(vector_origin)

			types.poison = {
				draw = function(ent, f, s, t)
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

					ent:DrawModel()
				end,
			}
		end

		do
			local mat = create_mat("effects/filmscan256")

			local emitter = ParticleEmitter(vector_origin)

			types.ice = {
				draw = function(ent, f, s, t)
					local pos = ent:GetBoneMatrix(math.random(1, ent:GetBoneCount()))
					if pos then
						pos = pos:GetTranslation()

						local p = emitter:Add("effects/splash1", pos + VectorRand() * 5)
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
					end

					render.ModelMaterialOverride(mat)
					render.SetColorModulation(0,0.5, 1*s)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*0.05)
					m:Translate(Vector(1,1,1)*t/20)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end


		do
			local mat = create_mat("effects/filmscan256")

			local emitter = ParticleEmitter(vector_origin)

			types.heal = {
				draw = function(ent, f, s, t)

					if math.random() > 0.8 then
						local pos = ent:GetBoneMatrix(math.random(1, ent:GetBoneCount()))
						if pos then
							pos = pos:GetTranslation()

							local p = emitter:Add("gui/html/stop", pos + VectorRand())
							p:SetStartSize(1)
							p:SetEndSize(1)
							p:SetStartAlpha(255*f)
							p:SetEndAlpha(0)
							p:SetVelocity(VectorRand()*5)
							p:SetGravity(VectorRand()*10)
							p:SetColor(100, 255, 100)
							--p:SetLighting(true)
							p:SetRoll(math.rad(45))
							p:SetAirResistance(100)
							p:SetLifeTime(1)
							p:SetDieTime(math.Rand(0.75,1.5)*2)
						end
					end

					render.ModelMaterialOverride(mat)
					render.SetColorModulation(0.75, 1*s, 0.75)
					render.SetBlend(f)

					local m = mat:GetMatrix("$BaseTextureTransform")
					m:Identity()
					m:Scale(Vector(1,1,1)*0.05)
					m:Translate(Vector(1,1,1)*t/20)
					mat:SetMatrix("$BaseTextureTransform", m)

					ent:DrawModel()
				end,
			}
		end
	end

	local active = {}

	local function render_jdmg()
		local time = RealTime()
		for i = #active, 1, -1 do
			local data = active[i]

			local f = (data.time - time) / data.duration
			f = f ^ data.pow

			if f <= 0 or not data.ent:IsValid() or data.ent:Health() <= 0 then
				table.remove(active, i)
			else
				data.type.draw(data.ent, f, data.strength, time + data.time_offset)
			end
		end

		render.SetColorModulation(1,1,1)
		render.ModelMaterialOverride()
		render.SetBlend(1)

		if not active[1] then
			hook.Remove("PostDrawTranslucentRenderables", "jdmg")
		end
	end

	function jdmg.DamageEffect(ent, type, duration, strength, pow)
		type = types[type] or types.generic
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
			hook.Add("PostDrawTranslucentRenderables", "jdmg", render_jdmg)
		end
	end

	net.Receive("jdmg", function()
		local ent = net.ReadEntity() -- todo use enums lol
		local type = net.ReadString()
		local duration = net.ReadFloat()
		local strength = net.ReadFloat()

		jdmg.DamageEffect(ent, type, duration, strength)
	end)
end

if SERVER then
	function jdmg.DamageEffect(ent, type, duration, strength)
		type = type or "generic"
		duration = duration or 1
		strength = strength or 1

		net.Start("jdmg", true)
			net.WriteEntity(ent)
			net.WriteString(type)
			net.WriteFloat(duration)
			net.WriteFloat(strength)
		net.Broadcast()
	end

	util.AddNetworkString("jdmg")

	local lookup = {}
	local enums = {}

	for key, val in pairs(_G) do
		if type(key) == "string" and key:StartWith("DMG_") and type(val) == "number" then
			lookup[val] = key:match("^DMG_(.+)"):lower()
			enums[key] = val
		end
	end

	lookup[DMG_BURN] = "fire"
	lookup[DMG_SLOWBURN] = "fire"
	lookup[DMG_SHOCK] = "lightning"
	lookup[DMG_ACID] = "poison"

	hook.Add("EntityTakeDamage", "jdmg", function(ent, dmginfo)
		local type = dmginfo:GetDamageType()

		local done = {}
		for k, v in pairs(enums) do
			if bit.band(type, v) > 0 and not done[lookup[v]] then
				local str = lookup[v]
				jdmg.DamageEffect(ent, str)
				done[str] = true
			end
		end
	end)
end