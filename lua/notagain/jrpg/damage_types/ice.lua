local META = {}
META.Name = "ice"
META.Adjectives = {"cold", "frozen", "freezing", "chilled", "iced", "arctic", "frosted"}
META.Names = {"ice", "glacier", "snow"}
META.Color = Color(150, 200, 255)

function META:OnDamage(self, attacker, victim, dmginfo)
	jdmg.AddStatus(victim, "frozen", dmginfo:GetDamage() / 100)
end

if CLIENT then
	local jfx = requirex("jfx")
	local mat = jfx.CreateOverlayMaterial("effects/filmscan256")

	local ice_mat = jfx.CreateMaterial({
		Name = "magic_ice",
		Shader = "VertexLitGeneric",
		CloakPassEnabled = 1,
		RefractAmount = 1,
	})

	function META:DrawOverlay(ent, f, s, t)
		local pos = ent:NearestPoint(ent:WorldSpaceCenter()+VectorRand()*100)

		local p = jfx.emitter:Add("effects/splash1", pos + VectorRand() * 20)
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

		local c = Vector(self.Color.r/255, self.Color.g/255, self.Color.b/255)*5*(f^0.15)
		ice_mat:SetVector("$CloakColorTint", c)
		ice_mat:SetFloat("$CloakFactor", f^0.15)
		ice_mat:SetFloat("$RefractAmount", -(f^0.1)+1)
		render.ModelMaterialOverride(ice_mat)
		render.SetColorModulation(c.r,c.g, c.b)
		render.SetBlend(f)
		jfx.DrawModel(ent)
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

	function META:DrawProjectile(ent, dmg, simple)
		local size = dmg / 100

		render.SetMaterial(jfx.materials.glow)
		render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(self.Color.r, self.Color.g, self.Color.b, 255))

		render.SetMaterial(jfx.materials.glow2)
		render.DrawSprite(ent:GetPos(), 128*size, 128*size, Color(self.Color.r, self.Color.g, self.Color.b, 150))

		if not simple then

			jfx.DrawTrail(ent, 0.4, 0, ent:GetPos(), jfx.materials.trail, self.Color.r, self.Color.g, self.Color.b, 50, self.Color.r, self.Color.g, self.Color.b, 0, 10, 0, 1)


			if not ent.next_emit or ent.next_emit < RealTime() then
				local life_time = 2

				local ice = ents.CreateClientProp()
				if ice:IsValid() then
					SafeRemoveEntityDelayed(ice, life_time)

					ice:SetModel(table.Random(rocks))

					ice:SetPos(ent:GetPos())
					ice:SetAngles(VectorRand():Angle())
					ice:SetModelScale(math.Rand(0.1, 0.2)*size)

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

						local c = Vector(self.Color.r/255, self.Color.g/255, self.Color.b/255)*5*(f2^0.5)
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
				end
				ent.next_emit = RealTime() + 0.02
			end
		end
	end
end

jdmg.RegisterDamageType(META)
