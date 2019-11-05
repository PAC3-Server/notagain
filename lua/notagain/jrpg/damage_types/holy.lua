local META = {}
META.Name = "holy"

META.Color = Color(255, 200, 150)

META.Adjectives = {"angelic", "divine", "spiritual", "sublime", "celestial", "spirited"}
META.Names = {"light", "holyness"}


if CLIENT then
	local jfx = requirex("jfx")
    local mat = jfx.CreateOverlayMaterial("effects/splash2", {Additive = 0, RimlightBoost = 1})

    local sounds = {
        "ambient/levels/coast/coastbird4.wav",
        "ambient/levels/coast/coastbird5.wav",
        "ambient/levels/coast/coastbird6.wav",
        "ambient/levels/coast/coastbird7.wav",
    }

    META.Sounds = {
        {
            path = "music/hl2_song10.mp3",
            pitch = 230,
        },
        {
            path = "physics/cardboard/cardboard_box_scrape_smooth_loop1.wav",
            pitch = 200,
        }
    }

    function META:SoundThink(ent, f, s, t)
        if math.random() > 0.95 then
            ent:EmitSound(table.Random(sounds), 75, math.Rand(100,120), f)
            ent:EmitSound("friends/friend_join.wav", 75, 255, f)
        end
    end

    function META:DrawOverlay(ent, f, s, t)
        render.ModelMaterialOverride(mat)
        render.SetColorModulation(s*6,s*6,s*6)
        render.SetBlend(f)

        jfx.DrawModel(ent)
    end

    local feather_mat = jfx.CreateMaterial({
        Shader = "VertexLitGeneric",

        BaseTexture = "https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/feather.png",
        VertexColor = 1,
        VertexAlpha = 1,
    })

    function META:DrawProjectile(ent, dmg, simple, vis)
        local size = dmg / 100

        render.SetMaterial(jfx.materials.glow)
        render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(self.Color.r, self.Color.g, self.Color.b, 255))

        render.SetMaterial(jfx.materials.glow2)
        render.DrawSprite(ent:GetPos(), 64*size, 64*size, Color(self.Color.r, self.Color.g, self.Color.b, 200))

        --jfx.DrawSunbeams(ent:GetPos(), size/20, 0.05, 0.5)


        render.SetMaterial(jfx.materials.refract3)
        render.DrawSprite(ent:GetPos(), 32*size, 32*size, Color(255,255,255, 150))

        if not simple then

            for i = 1, 3 do
                local pos = ent:GetPos()
                pos = pos + Vector(jfx.GetRandomOffset(pos, i, 2))*size*25

                ent.trail_data = ent.trail_data or {}
                ent.trail_data[i] = ent.trail_data[i] or {}
                jfx.DrawTrail(ent.trail_data[i], 0.5, 0, pos, jfx.materials.trail, self.Color.r, self.Color.g, self.Color.b, 255, self.Color.r, self.Color.g, self.Color.b, 0, 15*size, 0)
            end

            render.SetMaterial(jfx.materials.glow)
            render.DrawSprite(ent:GetPos(), 200*size, 200*size, Color(self.Color.r, self.Color.g, self.Color.b, 50))


            if not ent.next_emit or ent.next_emit < RealTime() then
                local life_time = 2

                local feather = ents.CreateClientProp()
                if feather:IsValid() then
                    SafeRemoveEntityDelayed(feather, life_time)

                    feather:SetModel("models/pac/default.mdl")
                    feather:SetPos(ent:GetPos() + (VectorRand()*size))
                    feather:SetAngles(VectorRand():Angle())
                    feather:SetModelScale(size + math.random()*0.75)

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

                    local h,s,v = ColorToHSV(self.Color)
                    local color = HSVToColor(h,s*0.25,v*0.8)

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
                end

                ent.next_emit = RealTime() + math.random()*0.25
            end
        end
    end
end

jdmg.RegisterDamageType(META)