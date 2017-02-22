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
		normal = normal or Vector(0,0,1)
		scale = scale or 1

		for i = 1, 100 do
			local offset = VectorRand() * scale * 50
			local trace = util.TraceLine({start = origin + offset * scale, endpos = (origin + offset) + normal * -100, mask =  MASK_SOLID_BRUSHONLY })
			if trace.Hit then
				--offset:Rotate(normal:Angle() + Angle(90,0,0))

				local life_time = 2

				local ent = ents.CreateClientProp()
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

				local color = render.GetSurfaceColor(trace.HitPos + normal, trace.HitPos + (normal * -100))
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

		util.ScreenShake(origin, scale, 1/scale, 1, 10 * scale)

		ply:EmitSound("physics/concrete/boulder_impact_hard"..math.random(1,4)..".wav", 75, 50 )
	end

	net.Receive("anime_death", function(len)
		local ply = net.ReadEntity()
		local origin = net.ReadVector()
		local normal = net.ReadVector()
		local scale = net.ReadFloat()

		RockImpact(ply, origin, normal, scale)
	end)
end

if SERVER then
	util.AddNetworkString("anime_death")

	hook.Add("Move", "realistic_falldamage", function(ply, data)
		local vel = data:GetVelocity()

		if ply.fdmg_last_vel and ply:GetMoveType() == MOVETYPE_WALK then
			local diff = vel - ply.fdmg_last_vel
			local len = diff:Length()
			if len > 500 then
				local params = {}
				params.start = data:GetOrigin() + ply:OBBCenter()
				params.endpos = params.start - diff:GetNormalized() * ply:BoundingRadius()
				params.filter = ply
				params.mins = ply:OBBMins()
				params.maxs = ply:OBBMaxs()
				local res = util.TraceHull(params)

				local dmg = (len - 500) / 4

				if not res.HitWorld and res.Entity:IsValid() then
					local info = DamageInfo()
					info:SetDamagePosition(data:GetOrigin())
					info:SetDamage(dmg)
					info:SetDamageType(DMG_FALL)
					info:SetAttacker(ply)
					info:SetInflictor(ply)
					info:SetDamageForce(ply.fdmg_last_vel)
					res.Entity:TakeDamageInfo(info)
				end

				local z = math.abs(res.HitNormal.z)

				if res.Hit and (z < 0.1 or z > 0.9) then
					local fall_damage = hook.Run("GetFallDamage", ply, len)
					if fall_damage ~= 0 then
						if fall_damage < dmg then
							if len > 2000 then
								local info = DamageInfo()
								info:SetDamagePosition(data:GetOrigin())
								info:SetDamage(dmg - fall_damage)
								info:SetDamageType(DMG_FALL)
								info:SetAttacker(Entity(0))
								info:SetInflictor(Entity(0))
								info:SetDamageForce(Vector(0,0,0))
								ply:TakeDamageInfo(info)
								net.Start("anime_death", true)
									net.WriteEntity(ply)
									net.WriteVector(data:GetOrigin())
									net.WriteVector(res.HitNormal)
									net.WriteFloat(ply:GetModelScale() or 1)
								net.Broadcast()

								params.mask =  MASK_SOLID_BRUSHONLY
								local res = util.TraceLine(params)

								timer.Simple(0, function()
									local ent = ply:GetNWEntity("serverside_ragdoll")
									if ent:IsValid() then
										ply:SetMoveType(MOVETYPE_NONE)
										ply:SetPos(res.HitPos)

										local phys = ent:GetPhysicsObjectNum(10)
										if phys:IsValid() then
											phys:SetPos(res.HitPos + res.HitNormal * -6)
											local ang = (-res.HitNormal):Angle()
											ang:RotateAroundAxis(res.HitNormal, math.random()*360)
											phys:SetAngles(ang)
											phys:EnableMotion(false)
										end
									end
								end)
							else
								local info = DamageInfo()
								info:SetDamagePosition(data:GetOrigin())
								info:SetDamage(dmg - fall_damage)
								info:SetDamageType(DMG_FALL)
								info:SetAttacker(Entity(0))
								info:SetInflictor(Entity(0))
								info:SetDamageForce(ply.fdmg_last_vel)
								ply:TakeDamageInfo(info)
							end
						end
					end
				end
			end
		end

		ply.fdmg_last_vel = vel
	end)
end