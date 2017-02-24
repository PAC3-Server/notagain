if CLIENT then
	local gradient = CreateMaterial(tostring({}), "UnlitGeneric", {
		["$BaseTexture"] = "gui/center_gradient",
		["$BaseTextureTransform"] = "center .5 .5 scale 1 1 rotate 90 translate 0 0",
		["$VertexAlpha"] = 1,
		["$VertexColor"] = 1,
		["$Additive"] = 0,
	})

	surface.CreateFont( "darksouls_death", {
		font = "georgia",
		size = 1000,
		weight = 0,
	} )

	local emitter = ParticleEmitter(vector_origin)

	net.Receive("darksouls_death", function()
		local ply = net.ReadEntity()
		local rag = net.ReadEntity()

		if ply == LocalPlayer() then
			LocalPlayer():EmitSound("pac_server/ds2death.ogg", 75, 100, 0.5)
		end

		timer.Simple(1, function()
			local rag = ply:GetRagdollEntity()
			if not rag then return end
			local time = RealTime() + 2
			rag:SetRenderMode(RENDERMODE_TRANSALPHA)
			local dir = VectorRand()*100
			dir.z = math.abs(dir.z)
			local gravity = VectorRand()*50
			gravity.z = math.abs(gravity.z)
			local bone = 0
			rag.RenderOverride = function()
				local f = math.min(time - RealTime(), 1)
				if f > 0 then
					render.SetBlend((f/3)^1.5)
					rag:DrawModel()
				end

				local pos = rag:GetBoneMatrix(math.ceil(bone))
				if pos then
					pos = pos:GetTranslation()

					local p = emitter:Add("effects/splash1", pos + VectorRand() * 10)
					p:SetStartSize(20)
					p:SetEndSize(20)
					p:SetStartAlpha(255)
					p:SetEndAlpha(0)
					p:SetVelocity(dir+VectorRand()*20)
					p:SetGravity(VectorRand()*10+gravity)
					p:SetColor(75, 100, 75)
					--p:SetLighting(tr ue)
					p:SetRoll(math.random()*360)
					p:SetAirResistance(100)
					p:SetLifeTime(1)
					p:SetDieTime(math.Rand(0.75,1.5))

					for i = 1, 1 do
						local p = emitter:Add("particle/fire", pos + VectorRand() * 10)
						p:SetStartSize(1)
						p:SetEndSize(0)
						p:SetStartAlpha(255)
						p:SetEndAlpha(0)
						p:SetVelocity(dir+VectorRand()*50)
						p:SetGravity(VectorRand()*50+gravity)
						--p:SetLighting(true)
						p:SetRoll(math.random()*360)
						p:SetAirResistance(100)
						p:SetLifeTime(1)
						p:SetDieTime(math.Rand(2.5,3.5))
					end
				end
				bone = bone + FrameTime() * 10
			end
		end)

		if ply == LocalPlayer() then
			local time = RealTime()
			hook.Add("HUDShouldDraw", "darksouls_death", function(str)
				if str == "CHudDamageIndicator" then
					return false
				end
			end)
			hook.Add("HUDPaintBackground", "darksouls_death", function()
				local f = math.min(RealTime() - time, 1)

				surface.SetDrawColor(0, 0, 0, math.max(255*f, 0, 255))
				surface.SetMaterial(gradient)
				local y = ScrH()/1.75
				local h = 300
				for i = 1, 6 do
					surface.DrawTexturedRect(-1000, y, ScrW()+2000, h)
				end

				local x, y = ScrW()/2, y + h/2

				local m = Matrix()
				m:Translate(Vector(x,y))
				m:Scale(Vector(1,1,1) * f^0.25)
				m:Translate(-Vector(x,y))
				cam.PushModelMatrix(m)
				draw.SimpleText("YOU DIED", "darksouls_death", x, y, Color(166, 0, 25, 255*(f^4)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				cam.PopModelMatrix()

				if ply:Alive() and f > 0.25 then
					hook.Remove("HUDPaintBackground", "darksouls_death")
					hook.Remove("HUDShouldDraw", "darksouls_death")
				end
			end)
		end
	end)
end

if SERVER then
	util.AddNetworkString("darksouls_death")

	hook.Add("RealisticFallDamage", "rockfall_death", function(ply, pos, dmg, speed, trace_res, trace_params)
		if trace_res.HitNormal.z ~= 1 then return end
		if dmg > ply:Health()*2 then return end

		ply:SetSequence(ply:LookupSequence("death_04"))
		ply:SetCycle(0.97)

		local info = DamageInfo()
		info:SetDamagePosition(pos)
		info:SetDamage(dmg)
		info:SetDamageType(DMG_FALL)
		info:SetAttacker(Entity(0))
		info:SetInflictor(Entity(0))
		info:SetDamageForce(Vector(0,0,0))
		ply:TakeDamageInfo(info)

		local rag = ply:GetNWEntity("serverside_ragdoll")
		if rag:IsValid() then
			local phys = rag:GetPhysicsObject()
			phys:SetVelocity(Vector(0,0,0))
			for i = 1, rag:GetPhysicsObjectCount() - 1 do
				local phys = rag:GetPhysicsObjectNum(i)
				phys:SetVelocity(Vector(0,0,0))
			end

			if ply:LookupBone("ValveBiped.Bip01_R_Latt") then
				ply:EmitSound("pac_server/darksouls2/death/female/"..math.random(1,4)..".ogg", 75, math.random(95,105))
			else
				ply:EmitSound("pac_server/darksouls2/death/male/"..math.random(1,5)..".ogg", 75, math.random(95,105))
			end

			net.Start("darksouls_death")
			net.WriteEntity(ply)
			net.WriteEntity(rag)
			net.Broadcast()
		end

		return true
	end)
end