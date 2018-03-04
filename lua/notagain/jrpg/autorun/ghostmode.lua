local Tag = "GhostMode"
local ghost_time = 8

if SERVER then
	jrpg.AddPlayerHook("PlayerDeath", Tag, function(ply)
		ply:SetNW2Float("ghost_timer", CurTime() + ghost_time)
		ply.ghost_spawn_pos = ply:GetPos()
		ply:SetDSP(0)
		SafeRemoveEntity(ply:GetNW2Entity("ghost_fairy"))
	end)

	jrpg.AddPlayerHook("PlayerSpawn", Tag, function(ply)
		SafeRemoveEntity(ply:GetNW2Entity("ghost_fairy"))
	end)

	jrpg.AddPlayerHook("Move", Tag, function(ply, mv)
		if ply:GetNW2Float("ghost_timer", 0) > CurTime() then
			return
		end

		local ent = ply:GetNW2Entity("ghost_fairy")

		if not ent:IsValid() then return end

		mv:SetOrigin(ent:GetPos())
		mv:SetVelocity(Vector(0,0,0))

		if not ent.GravityOn then
			local ang = ply:EyeAngles()
			ang.y = -ang.y
			local aim = ang:Forward()


			local vel = Vector(0,0,0)
			if ply:KeyDown(IN_FORWARD) then
				vel = aim*1
			elseif ply:KeyDown(IN_BACK) then
				vel = aim*-1
			end

			if ply:KeyDown(IN_MOVELEFT) then
				vel = ang:Right()*1
			elseif ply:KeyDown(IN_MOVERIGHT) then
				vel = ang:Right()*-1
			end

			if ply:KeyDown(IN_JUMP) then
				vel = vel + ply:GetUp()*1
			end

			if ply:KeyDown(IN_SPEED) then
				vel = vel * 5
			end

			if ply:KeyDown(IN_DUCK) then
				vel = vel * 0.25
			end

			if ply:KeyDown(IN_WALK) then
				vel = vel * 0.5
			end

			vel = vel * 5

			local phys = ent:GetPhysicsObject()

			phys:ComputeShadowControl({
				secondstoarrive = 0.9,
				pos = phys:GetPos() + vel,
				angle = ply:EyeAngles(),
				maxangular = 5000,
				maxangulardamp = 10000,
				maxspeed = 1000000,
				maxspeeddamp = 10000,
				dampfactor = 0.05,
				teleportdistance = 200,
				deltatime = FrameTime(),
			})

			local rag = ply:GetRagdollEntity()
			rag = rag and rag:IsValid() and rag or nil

			if rag then
				for i = 0, rag:GetPhysicsObjectCount() - 1 do
					local phys = rag:GetPhysicsObjectNum(i)
					phys:AddVelocity((ply:GetPos() - phys:GetPos()):GetNormalized() * 0.1)
				end
			end

		end

		return true
	end)

	jrpg.AddPlayerHook("PlayerDeathThink", Tag, function(ply)
		if ply:GetNW2Float("ghost_timer", 0) > CurTime() then
			return
		end

		if aowl then
			ply.aowl_predeathpos = ply:GetPos()
			ply.aowl_predeathangles = ply:GetAngles()
		end

		if ply.ghost_spawn_pos then
			local rag = ply:GetRagdollEntity()
			rag = rag and rag:IsValid() and rag or nil

			local pos =  rag and rag:GetPos() or ply.ghost_spawn_pos

			if rag then
				for i = 0, rag:GetPhysicsObjectCount() - 1 do
					local phys = rag:GetPhysicsObjectNum(i)
					phys:EnableGravity(false)
				end
			end

			local fairy = ents.Create("fairy")
			fairy:SetPos(pos)
			fairy:Spawn()
			if fairy.CPPISetOwner then fairy:CPPISetOwner(ply) end

			ply:CallOnRemove("ghost_fairy", function() SafeRemoveEntity(fairy) end)

			ply:SetOwner(fairy)

			ply:SetNW2Entity("ghost_fairy", fairy)
			ply.ghost_spawn_pos = nil
		end

		ply:SetDSP(130)

		if not ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_JUMP) then
			ply:SetMoveType(MOVETYPE_WALK)
			return false
		end
	end)
end

if CLIENT then
	hook.Add("EntityEmitSound", Tag, function(data)
		local ply = LocalPlayer()
		if not ply:Alive() then
			if ply:GetNW2Float("ghost_timer", 0) > CurTime() then
				return
			end

			local ent = ply:GetNW2Entity("ghost_fairy")

			if ent:IsValid() then
				data.Pitch = data.Pitch * 0.5
				return true
			end
		end
	end)

	local rand_ang = Vector()
	hook.Add("CalcView", Tag, function(ply)
		if not ply:Alive() then
			if ply:GetNW2Float("ghost_timer", 0) > CurTime() then
				return
			end

			local ent = ply:GetNW2Entity("ghost_fairy")

			if ent:IsValid() then
				rand_ang = rand_ang + ((((VectorRand()*math.random()^5)*10) - rand_ang) * FrameTime()*0.1)
				local ang = ply:EyeAngles()
				ang.y = -ang.y
				local aim = ang:Forward()

				local pos = ent:GetPos() + aim * -100

				local data = util.TraceLine({
					start = ent:GetPos(),
					endpos = pos,
					filter = ents.FindInSphere(ent:GetPos(), ent:BoundingRadius()),
					mask =  MASK_VISIBLE,
				})

				if data.Hit and data.Entity ~= ply and not data.Entity:IsPlayer() and not data.Entity:IsVehicle() then
					pos = data.HitPos + aim * 5
				end

				return {
					origin = pos,
					fov = 50,
					angles = ang + Angle(rand_ang.x, rand_ang.y, rand_ang.z)*5,
				}
			end
		end
	end)

    hook.Add("OnPlayerChat",Tag,function(ply, txt)
        if jrpg.IsEnabled(ply) and not ply:Alive() then
			local ent = ply:GetNW2Entity("ghost_fairy")
			if ent:IsValid() then
				ent.player = ply
				ent:PlayPhrase(txt)
			end
        end
    end)

	local emitter = ParticleEmitter(EyePos())
	emitter:SetNoDraw(true)

	local sound
	local windup_sound

    jrpg.AddPlayerHook("PrePlayerDraw",Tag,function(ply)
		if not ply:Alive() then
			return true
		end
	end)

	local temp_mat = CreateMaterial("fairy_mirror" .. os.clock(), "UnlitGeneric", {
		["$BaseTexture"] = render.GetScreenEffectTexture(),
		["$VertexAlpha"] = 0,
		["$VertexColor"] = 0,
	})

    hook.Add("RenderScene",Tag,function(pos, ang, fov)
		local ply = LocalPlayer()
		if not ply:Alive() then
			local ent = ply:GetNW2Entity("ghost_fairy")
			if ent:IsValid() then

				if not ply.ghostmode_hide_hud then
					ply.ghostmode_hide_hud = true
					ent:CallOnRemove(Tag, function()
						hook.Add("HUDShouldDraw", Tag)
						ply.ghostmode_hide_hud = nil
					end)
					hook.Add("HUDShouldDraw",Tag,function(name)
						if name == "CHudDamageIndicator" and jrpg.enabled and not LocalPlayer():Alive() then
							return false
						end
					end)
				end

				render.RenderView({
					drawhud = false,
					drawmonitors = true,
					dopostprocess = true,
					drawviewmodel = true,
				})

				cam.Start2D()
					temp_mat:SetTexture("$basetexture", render.GetScreenEffectTexture())
					surface.SetMaterial(temp_mat)
					surface.DrawTexturedRectUV(0,0,ScrW(),ScrH(),1,0,0,1)
					if jrpg.DrawFairySunbeams and render.SupportsPixelShaders_2_0() then
						jrpg.DrawFairySunbeams()
					end
				cam.End2D()

				return true
			end
		end
	end)

    hook.Add("RenderScreenspaceEffects",Tag,function()
		for _, ply in ipairs(player.GetAll()) do
			if not jrpg.IsEnabled(ply) then continue end

			if ply:GetNW2Float("ghost_timer", 0) > CurTime() then
				continue
			end

			local ent = ply:GetNW2Entity("ghost_fairy")

			if not ent:IsValid() then continue end

			ply:SetPos(ent:GetPos() - Vector(0,0,ply:BoundingRadius()+15))
			ply:SetupBones()
		end

		if jrpg.enabled and not LocalPlayer():Alive() then

			sound = sound or CreateSound(LocalPlayer(), "ambient/levels/citadel/citadel_hub_ambience1.mp3")
			sound:Play()
			sound:SetDSP(1)
			sound:ChangePitch(100 + math.sin(RealTime()/5)*5)

			local time = LocalPlayer():GetNW2Float("ghost_timer", 0) - CurTime()
			local f = time
			f = -math.Clamp(f / ghost_time, 0, 1)+1
			f = f ^ 5

			sound:ChangeVolume(f^5)

			if f == 1 then
				cam.Start3D()
					emitter:Draw()
				cam.End3D()
			end

			DrawToyTown(2*f, 500)

			windup_sound = windup_sound or CreateSound(LocalPlayer(), "ambient/levels/labs/teleport_mechanism_windup5.wav")
			windup_sound:PlayEx(1, 255)
			windup_sound:ChangeVolume(f)
			windup_sound:ChangePitch(math.min(100 + f*255, 255))

			if f == 1 then
				windup_sound:Stop()
			end

			if f < 0.99 then
				DrawColorModify({
					[ "$pp_colour_brightness" ] = f*0.5,
					[ "$pp_colour_contrast" ] = 1 + f*1,
				})
			end

			local tbl = {}
			tbl[ "$pp_colour_addr" ] = 0.08*f
			tbl[ "$pp_colour_addg" ] = 0.05*f
			tbl[ "$pp_colour_addb" ] = 0.13*f
			tbl[ "$pp_colour_brightness" ] = -0.2*f
			tbl[ "$pp_colour_contrast" ] = Lerp(f, 1, 0.9)
			tbl[ "$pp_colour_colour" ] = Lerp(f, 1, -1)
			tbl[ "$pp_colour_mulr" ] = 0
			tbl[ "$pp_colour_mulg" ] = 0
			tbl[ "$pp_colour_mulb" ] = 0
			DrawColorModify( tbl )

			DrawSharpen( math.sin(RealTime()*5+math.random()*0.1)*10*f, 0.1*f )

			for i = 1, 5 do
				local particle = emitter:Add("particle/fire", EyePos() + VectorRand() * 500)
				if particle then
					local col = HSVToColor(math.random()*30, 0.1, 1)
					particle:SetColor(col.r, col.g, col.b, 266)

					particle:SetVelocity(VectorRand() )

					particle:SetDieTime((math.random()+4)*3)
					--particle:SetDieTime(0.5)
					particle:SetLifeTime(0)

					local size = 1

					particle:SetAngles(AngleRand())
					particle:SetStartSize(1)
					particle:SetEndSize(0)

					particle:SetStartAlpha(0)
					particle:SetEndAlpha(255)

					particle:SetStartLength(particle:GetStartSize())
					particle:SetEndLength(math.random(50,250))

					--particle:SetRollDelta(math.Rand(-1,1)*20)
					particle:SetAirResistance(500)
					particle:SetGravity(VectorRand() * 10 + Vector(0,0,200))
				end
			end

			DrawBloom( 0.6, 1.2*f, 11.21, 9, 2, 1.96, 1, 1, 1)
			DrawMotionBlur(math.sin(RealTime()*10)*0.2 + 0.4, 0.5*f, 0)
		else
			if sound then
				sound:Stop()
			end
			if windup_sound then
				windup_sound:Stop()
			end
		end
    end)
end
