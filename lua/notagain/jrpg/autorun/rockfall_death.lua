if CLIENT then

	local rocks = {
		"models/props_wasteland/rockcliff01b.mdl",
		"models/props_wasteland/rockcliff01c.mdl",
		"models/props_wasteland/rockcliff01e.mdl",
		"models/props_wasteland/rockcliff01f.mdl",
		"models/props_wasteland/rockcliff01g.mdl",
		"models/props_wasteland/rockcliff01j.mdl",
		"models/props_wasteland/rockcliff01k.mdl",
	}

	for _, v in ipairs(rocks) do
		util.PrecacheModel(v)
	end

	local emitter = ParticleEmitter(vector_origin)

	function RockImpact(ply, origin, normal, scale)
		if not ply or not IsValid(ply) then return end
		normal = normal or Vector(0,0,1)
		scale = scale or 1

		for i = 1, 100 do
			local offset = VectorRand() * scale * 50
			local trace = util.TraceLine({start = origin + offset * scale, endpos = (origin + offset) + normal * -100, mask =  MASK_SOLID_BRUSHONLY })
			if trace.Hit then
				--offset:Rotate(normal:Angle() + Angle(90,0,0))

				local life_time = 2

				local ent = ents.CreateClientProp()
				if ent:IsValid() then
					SafeRemoveEntityDelayed(ent, life_time)

					local time = RealTime()
					local s
					local rand = math.random() * 500
					ent.RenderOverride = function()
						--s = s or ent:GetPos()
						s = s or ent:GetModelScale()
						local fade = RealTime() - time
						fade = math.Clamp((-fade + life_time) / life_time, 0, 1)

						local scale = (math.min((fade ^ 0.5) + 0.5, 1) - 0.5)

						ent:SetModelScale(scale * s)

						--s = s + normal * FrameTime() * ((-fade+1) ^ 10) * -(500 + rand)
						--ent:SetPos(s)
						ent:DrawModel()
					end

					ent:SetModel(table.Random(rocks))

					if math.random() > 0.7 then
						ent:SetPos(trace.HitPos)
						ent:SetAngles(trace.HitNormal:Angle() )

						ent:SetModelScale(scale * math.Rand(0.3, 0.5)/2)
						ent:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
						ent:PhysicsInitBox(Vector(1,1,1) * -5*scale, Vector(1,1,1) * 5*scale)

						local phys = ent:GetPhysicsObject()
						phys:Wake()
						phys:AddVelocity((normal*2 + VectorRand()) * 100 * scale)
						phys:AddAngleVelocity(VectorRand()*200)
						phys:SetMaterial("default_silent")
					else
						ent:SetAngles((trace.HitPos - origin):AngleEx(Vector(0,1,0)))
						ent:SetModelScale((math.Rand(0.25, 1) + (offset:Length()/200)) * scale * 0.35)
						ent:SetPos(trace.HitPos)
					end

					local trace_check = trace.Hit and trace.HitTexture ~= "**empty**" -- Check if we're actually hitting a texture that exists.
					local color = Vector(0,0,0)

					if trace_check then
						color = render.GetSurfaceColor(trace.HitPos + normal, trace.HitPos + (normal * -100))
					end

					ent:SetColor(Color(color.x*255, color.y*255, color.z*255))

					local p = emitter:Add("particle/smokesprites_000" .. math.random(1,6), trace.HitPos)
					local s = math.Rand(70,130)
					p:SetStartSize(s)
					p:SetEndSize(s)
					p:SetStartAlpha(math.random(100,200))
					p:SetEndAlpha(0)
					--p:SetLighting(true)
					p:SetVelocity(VectorRand()*100)
					--p:SetGravity(physenv.GetGravity()*0.05)
					p:SetRoll(math.random()*360)
					p:SetAirResistance(50)
					p:SetLifeTime(1)
					p:SetDieTime(math.Rand(2,5))
					p:SetColor(color.x*255, color.y*255, color.z*255)
				end
			end
		end

		util.ScreenShake(origin, scale, 1/scale, 1, 10 * scale)

		ply:EmitSound("physics/concrete/boulder_impact_hard"..math.random(1,4)..".wav", 60, 50 )
		ply:EmitSound("pac_server/groundhit.ogg", 100, math.random(90,110) )
	end

	net.Receive("rockfall_death", function(len)
		local ply = net.ReadEntity()
		local origin = net.ReadVector()
		local normal = net.ReadVector()
		local scale = net.ReadFloat()

		RockImpact(ply, origin, normal, scale)
	end)
end


if SERVER then
	util.AddNetworkString("rockfall_death")

	hook.Add("RealisticFallDamage", "rockfall_death", function(ply, info, speed, fall_dmg, trace_res, trace_params)
		if speed < 2000 then return end

		info:SetDamageForce(Vector(0,0,0))
		local pos = info:GetDamagePosition()

		net.Start("rockfall_death", true)
			net.WriteEntity(ply)
			net.WriteVector(pos)
			net.WriteVector(trace_res.HitNormal)
			net.WriteFloat(ply:GetModelScale() or 1)
		net.Broadcast()

		trace_params.mask =  MASK_SOLID_BRUSHONLY
		local res = util.TraceLine(trace_params)

		timer.Simple(0, function()
			local ent = ply:GetNWEntity("serverside_ragdoll")
			if ent:IsValid() then
				ply:SetMoveType(MOVETYPE_NONE)
				ply:SetPos(res.HitPos)

				local phys = ent:GetPhysicsObjectNum(10)
				if phys and phys:IsValid() then
					phys:SetPos(res.HitPos + res.HitNormal * -6)
					local ang = (-res.HitNormal):Angle()
					ang:RotateAroundAxis(res.HitNormal, math.random()*360)
					phys:SetAngles(ang)
					phys:EnableMotion(false)
				end
			end
		end)
	end)
end
