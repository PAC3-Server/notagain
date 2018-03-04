if CLIENT then
	local emitter = ParticleEmitter(vector_origin)
	local mat = Material("sprites/light_ignorez")
	local mat2 = CreateMaterial("teamrocket_" ..tostring({}), "UnlitGeneric", {
		["$BaseTexture"] = "particle/particle_glow_09",
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
		["$Additive"] = 1,
	})

	net.Receive("smash_death", function(len)
		if not LocalPlayer():IsValid() then return end
		local origin = net.ReadVector()
		local normal = net.ReadVector()


		local duration = 0.5
		local delay = 3.75
		local max_speed = 5000
		local sound_played = false
		local start = RealTime()

		local id = "teamrocket_"..tostring({})

		util.ScreenShake(origin, 50, 100, duration, 10)

		hook.Add("RenderScreenspaceEffects", id, function()
			local time = RealTime()
			local delta = time - start

			if delta > duration then
				hook.Remove("RenderScreenspaceEffects", id)
				return
			end

			for i = 1, 10 do
				local p = emitter:Add(mat, origin + VectorRand() * 50 - normal * 300)
				local s = math.Rand(30,130)
				p:SetStartSize(s)
				p:SetEndSize(s)
				p:SetStartAlpha(255)
				p:SetEndAlpha(255)
				--p:SetLighting(true)
				p:SetStartLength(400)
				p:SetEndLength(math.Rand(700,1500))
				p:SetVelocity(normal * 2000 + VectorRand()*100)
				--p:SetGravity(physenv.GetGravity()*0.05)
				p:SetRoll(math.random()*360)
				p:SetAirResistance(50)
				p:SetLifeTime(0.1)
				p:SetDieTime(math.Rand(0.1,0.25))
			end

			local size = math.sin((delta / duration) * math.pi) * 0.7
			local rotation = time * 100

			rotation = rotation ^ ((-(delta / duration)+1) * 0.5)

			local pos = origin:ToScreen()

			if pos.visible then
				surface.SetMaterial(mat2)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRectRotated(pos.x, pos.y, size * 128, size * 128, rotation)

				size = size * 6

				surface.SetMaterial(mat)
				surface.SetDrawColor(255, 255, 255, 255)
				local max = 8
				for i = 1, max do
					surface.DrawTexturedRectRotated(pos.x, pos.y, 10, size * 50 * math.sin(i), rotation + ((i / max) * math.pi * 2) * 360)
				end

				local max = 2
				for i = 1, max do
					surface.DrawTexturedRectRotated(pos.x, pos.y, 10, size * 50, -rotation - ((i / max) * math.pi * 2) * 360 - 45)
				end

				DrawSunbeams(0.3, math.abs(size)*0.025, 0.06, pos.x / ScrW(), pos.y / ScrH())
			end
		end)
	end)
end

if SERVER then
	util.AddNetworkString("smash_death")

	local suppress = false
	hook.Add("EntityTakeDamage", "smash_death", function(victim, info)
		if suppress or not victim:IsPlayer() then return end
		local force = info:GetDamageForce()

		local res = util.TraceLine({start = victim:WorldSpaceCenter(), endpos = victim:WorldSpaceCenter() + force:GetNormalized() * 200, mask =  MASK_SOLID_BRUSHONLY})

		if res.Hit and res.HitSky and victim:WorldSpaceCenter():Distance(res.HitPos) < 200 then
			suppress = true

			victim:EmitSound("chatsounds/autoadd/dbz_fx/strongpunch.ogg", 75, 100, 0.5)

			net.Start("smash_death")
			net.WriteVector(res.HitPos)
			net.WriteVector(res.HitNormal)
			net.Broadcast()

			suppress = false
		end
	end)
end