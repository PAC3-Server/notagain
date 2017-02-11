if CLIENT then
	local r,g,b = 3, 0.75, 0.5

	local glare_mat = Material("sprites/light_ignorez")
	local warp_mat = Material("particle/warp2_warp")

	local shiny = CreateMaterial(tostring({}) .. os.clock(), "VertexLitGeneric", {
		["$Additive"] = 1,
		["$Translucent"] = 1,

		["$Phong"] = 1,
		["$PhongBoost"] = 10,
		["$PhongExponent"] = 5,
		["$PhongFresnelRange"] = Vector(0,0.5,1),
		["$PhongTint"] = Vector(1,1,1),


		["$Rimlight"] = 1,
		["$RimlightBoost"] = 50,
		["$RimlightExponent"] = 5,

		["$BaseTexture"] = "models/debug/debugwhite",
		["$BumpMap"] = "dev/bump_normal",
	})

	local smoke_mat = CreateMaterial(tostring{}, "UnlitGeneric", {
		["$BaseTexture"] = "particle/particle_smokegrenade",
		["$Additive"] = 1,
		["$Translucent"] = 1,
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
		["$IgnoreZ"] = 1,

	})

	local smoke2_mat = CreateMaterial(tostring{}, "UnlitGeneric", {
		["$BaseTexture"] = "effects/blood_core",
		["$Additive"] = 1,
		["$Translucent"] = 1,
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
		["$IgnoreZ"] = 1,
	})

	local glare2_mat = CreateMaterial(tostring{}, "UnlitGeneric", {
		["$BaseTexture"] = "particle/fire",
		["$Additive"] = 1,
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
	})

	local fire_mat = CreateMaterial(tostring{}, "UnlitGeneric", {
		["$BaseTexture"] = "particle/water/watersplash_001a",
		["$Additive"] = 1,
		["$Translucent"] = 1,
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
	})

	local emitter2d = ParticleEmitter(vector_origin)
	emitter2d:SetNoDraw(true)

	local entities = {}
	local done = {}

	local function add_ent(ent)
		if not done[ent] then
			table.insert(entities, ent)
			done[ent] = true
		end
	end

	local function remove_ent(ent)
		if done[ent] then
			done[ent] = nil
			for i, v in ipairs(entities) do
				if v == ent then
					table.remove(entities, i)
					break
				end
			end
		end
	end

	hook.Add("OnEntityCreated", "jrpg_items", function(ent)
		local name = ent:GetClass()
		if (name:StartWith("weapon_") or name:StartWith("item_")) then
			add_ent(ent)
		end
	end)

	hook.Add("EntityRemoved", "jrpg_items", remove)

	hook.Add("PostDrawTranslucentRenderables", "jrpg_items", function()
		render.SetColorModulation(r, g, b)
		render.MaterialOverride(shiny)
		for _, ent in ipairs(entities) do
			if not ent:IsValid() then
				remove_ent(ent)
				return
			end

			if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then continue end

			local pos = ent:WorldSpaceCenter()
			ent.jrpg_items_pixvis = ent.jrpg_items_pixvis or util.GetPixelVisibleHandle()
			ent.jrpg_items_pixvis2 = ent.jrpg_items_pixvis2 or util.GetPixelVisibleHandle()
			local radius = ent:BoundingRadius()
			local vis = util.PixelVisible(pos, radius*0.5, ent.jrpg_items_pixvis)

			if vis == 0 and util.PixelVisible(pos, radius*5, ent.jrpg_items_pixvis2) == 0 then continue end

			local time = RealTime()

			ent.jrpg_items_random = ent.jrpg_items_random or {}
			ent.jrpg_items_random.rotation = ent.jrpg_items_random.rotation or math.random()*360

			render.SetMaterial(warp_mat)
			cam.IgnoreZ(true)
			render.DrawSprite(pos, 50, 50, Color(r*255*2, g*255*2, b*255*2, vis*20), ent.jrpg_items_random.rotation)

			render.SetMaterial(glare2_mat)

			local glow = math.sin(time*5)*0.5+0.5
			local r = radius/8
			render.DrawSprite(pos, r*10, r*10, Color(255, 225, 200, vis*170*glow))
			render.DrawSprite(pos, r*20, r*20, Color(255, 225, 150, vis*170*(glow+0.25)))
			render.DrawSprite(pos, r*30, r*30, Color(255, 200, 100, vis*120*(glow+0.5)))

			cam.IgnoreZ(false)

			ent:DrawModel()

			render.SetMaterial(glare_mat)
			render.DrawSprite(pos, r*180, r*50, Color(r*255, g*255, b*255, vis*20))

			if not ent.jrpg_items_next_emit2 or ent.jrpg_items_next_emit2 < time then

				local p = emitter2d:Add(glare2_mat, pos + (VectorRand()*radius*0.5))
				p:SetDieTime(math.Rand(2,4))
				p:SetLifeTime(1)

				p:SetStartSize(math.Rand(2,4))
				p:SetEndSize(0)

				p:SetStartAlpha(0)
				p:SetEndAlpha(255)

				p:SetColor(255, 230, 150)

				p:SetVelocity(VectorRand()*5)
				p:SetGravity(Vector(0,0,3))
				p:SetAirResistance(30)

				ent.jrpg_items_next_emit2 = time + 0.1

				if math.random() > 0.2 then
					local p = emitter2d:Add(glare2_mat, pos + (VectorRand()*radius*0.5))
					p:SetDieTime(math.Rand(1,3))
					p:SetLifeTime(1)

					p:SetStartSize(math.Rand(2,4))
					p:SetEndSize(0)

					p:SetStartAlpha(255)
					p:SetEndAlpha(255)

					p:SetVelocity(VectorRand()*3)
					p:SetGravity(Vector(0,0,math.Rand(3,5)))
					p:SetAirResistance(30)

					p:SetNextThink(CurTime())

					local seed = math.random()
					local seed2 = math.Rand(-4,4)

					p:SetThinkFunction(function(p)
						p:SetStartSize(math.abs(math.sin(seed+time*seed2)*3+math.Rand(0,2)))
						p:SetColor(math.Rand(200, 255), math.Rand(200, 255), math.Rand(200, 255))
						p:SetNextThink(CurTime())
					end)

				end
			end

			if not ent.jrpg_items_next_emit or ent.jrpg_items_next_emit < time then
				local p = emitter2d:Add(math.random() > 0.5 and smoke_mat or smoke2_mat, pos)
				p:SetDieTime(3)
				p:SetLifeTime(1)

				p:SetStartSize(1)
				p:SetEndSize(15)

				p:SetStartAlpha(255*vis)
				p:SetEndAlpha(0)

				p:SetColor(255,150,50)

				p:SetVelocity(VectorRand()*3)

				p:SetRoll(math.random()*360)

				p:SetAirResistance(30)
				ent.jrpg_items_next_emit = time + 0.2
			end

			render.SetMaterial(fire_mat)

			for i2 = 1, 5 do
				ent.jrpg_items_random[i2] = ent.jrpg_items_random[i2] or math.Rand(-1,1)
				local f2 = i2/4
				f2=f2*5+ent.jrpg_items_random[i2]
				local max = 5
				render.StartBeam(max)
				for i = 1, max do
					local f = i/max
					local s = math.sin(f*math.pi*2)

					local offset = Vector(
						math.sin(f2+time+s*30/max*ent.jrpg_items_random[i2]),
						math.cos(f2+time+s*30/max*ent.jrpg_items_random[i2]),
						(radius/8)*math.abs(math.sin(f2 + time/5)*100)*f*0.5
					)
					if i == 1 then
						offset = offset * 0
					end

					render.AddBeam(
						pos + offset,
						(-f+1)*radius,
						f*0.3-time*0.1 + ent.jrpg_items_random[i2],
						Color(200, 150, 0, 255*f)
					)
				end
				render.EndBeam()
			end
		end

		emitter2d:Draw()

		render.SetColorModulation(1,1,1)
		render.MaterialOverride()
	end)
end

if SERVER then
	local function disallow(ply, ent)
		if ent:GetPos() == ply:GetPos() then
			return
		end

		if not (ply:KeyDown(IN_USE) and ply:GetEyeTrace().Entity == ent) then
			return false
		end
	end

	hook.Add("PlayerCanPickupItem", "jrpg_items", disallow)
	hook.Add("PlayerCanPickupWeapon", "jrpg_items", disallow)
end
