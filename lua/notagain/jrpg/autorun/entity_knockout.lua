local function manip_ang(ent, id, ang)
    local bone = ent:LookupBone(id)
    if bone  then
        ent:ManipulateBoneAngles(bone, ang)
        ent.jrpg_knockout_manip = ent.jrpg_knockout_manip or {}
        ent.jrpg_knockout_manip.ang = ent.jrpg_knockout_manip.ang or {}
        ent.jrpg_knockout_manip.ang[bone] = bone
    end
end

local function manip_pos(ent, id, ang)
    local bone = ent:LookupBone(id)
    if bone  then
        ent:ManipulateBonePosition(bone, ang)
        ent.jrpg_knockout_manip = ent.jrpg_knockout_manip or {}
        ent.jrpg_knockout_manip.pos = ent.jrpg_knockout_manip.pos or {}
        ent.jrpg_knockout_manip.pos[bone] = bone
    end
end

local function reset_manip(ent)
    if ent.jrpg_knockout_manip then
        for what, bones in pairs(ent.jrpg_knockout_manip) do
            for bone in pairs(bones) do
                if what == "pos" then
                    ent:ManipulateBonePosition(bone, vector_origin)
                elseif what == "ang" then
                    ent:ManipulateBoneAngles(bone, Angle())
                end
            end
        end
    end
end

function jrpg.KnockoutDraw(ent)
    if ent:GetNW2Bool("jrpg_knockout") then-- ent:DrawModel() do return end
        local time = CurTime() - ent.jrpg_knockout_timer
        local parent = ent:GetParent()
        if not parent:IsValid() then
            parent = ent
        else
            if time > 0.2  then
                ent:SetSequence(0)
            end
        end

        local wvel = parent:GetVelocity()
        local s = math.Clamp(wvel:Length()/300, 0, 1)
        local ang = (-wvel):Angle()

        if s > 0.1 then
            ent.jrpg_knockout_lastang = ang
        else
            ent.jrpg_knockout_lastang = ent.jrpg_knockout_lastang or ent:GetAngles()
        end

        s = s * math.min(time*2, 1)

        if ent.jrpg_knockout_lastang then
            ang = LerpAngle(s, Angle(Lerp(math.Clamp(CurTime() - ent.jrpg_knockout_timer, 0, 1), 0, -90),ent.jrpg_knockout_lastang.y,0), ang)
        end

        ent:SetRenderAngles(ang)
        local origin = parent:GetPos() - parent:GetUp()*(parent:BoundingRadius()+2.5)*math.min(time, 1)
        ent:SetRenderOrigin(origin)

        ent.jrpg_knockout_render_origin = origin
        ent.jrpg_knockout_render_angles = ang

        manip_pos(ent, "ValveBiped.Bip01_Pelvis", Vector(0,0,-ent:BoundingRadius()))

        manip_ang(ent, "ValveBiped.Bip01_Spine", Angle(0,20*s,0))
        manip_ang(ent, "ValveBiped.Bip01_Spine1", Angle(0,20*s,0))
        manip_ang(ent, "ValveBiped.Bip01_Spine2", Angle(0,20*s,0))
        manip_ang(ent, "ValveBiped.Bip01_Spine4", Angle(0,20*s,0))

        manip_ang(ent, "ValveBiped.Bip01_R_Thigh", Angle(0,-85*s,0))
        manip_ang(ent, "ValveBiped.Bip01_L_Thigh", Angle(0,-85*s,0))

        manip_ang(ent, "ValveBiped.Bip01_L_Clavicle", Angle(-30*s,0,20*s))
        manip_ang(ent, "ValveBiped.Bip01_R_Clavicle", Angle(30*s,0,-20*s))

        manip_ang(ent, "ValveBiped.Bip01_L_UpperArm", Angle(-60*s,-140*s,40*s))
        manip_ang(ent, "ValveBiped.Bip01_R_UpperArm", Angle(60*s,-140*s,-40*s))

        manip_ang(ent, "ValveBiped.Bip01_R_Calf", Angle(0,12*s,0))
        manip_ang(ent, "ValveBiped.Bip01_L_Calf", Angle(0,12*s,0))

        ent:SetupBones()
    end

    if ent.jrpg_knockout_getup then
        local f = CurTime() - ent.jrpg_knockout_getup

        f = math.Clamp(f*2, 0,1)^0.5

        local ang = LerpAngle(f, ent.jrpg_knockout_render_angles, Angle(0,ent.jrpg_knockout_render_angles.y, 0))
        ent:SetRenderAngles(ang)
        manip_pos(ent, "ValveBiped.Bip01_Pelvis", Vector(0,0,-ent:BoundingRadius()*(-f+1)))

        --ent:SetRenderOrigin(NULL)
        --ent:SetRenderAngles(NULL)
    end
end

jrpg.knockouts_ents = jrpg.knockouts_ents or {}
local knockouts = jrpg.knockouts_ents

hook.Add("PreDrawOpaqueRenderables", "jrpg_knockout", function()
    for i = #knockouts, 1, -1 do
        if knockouts[i]:IsValid() then
            jrpg.KnockoutDraw(knockouts[i])
        else
            table.remove(knockouts, i)
        end
    end
end)

local COND_NPC_FREEZE = 67
local COND_NPC_UNFREEZE = 68

function jrpg.CancelKnockout(ent, broadcast)
    if broadcast then
        net.Start( "jrpg_knockout_cancel" )
            net.WriteEntity( ent )
        net.Broadcast()
    end

    if ent.SetCondition then
        ent:SetCondition( COND_NPC_UNFREEZE )
    end

    if ent.jrpg_knockout_old_sequence then
        ent:SetSequence(ent.jrpg_knockout_old_sequence)
    end

    if IsValid(ent.jrpg_knockout_dummy) then
        local parent = ent.jrpg_knockout_dummy
        local pos = util.QuickTrace(parent:GetPos(), physenv.GetGravity()*100, parent).HitPos

        ent:SetPos(parent:GetPos())
        ent:SetParent(NULL)
        ent:SetNotSolid(false)
        SafeRemoveEntity(ent.jrpg_knockout_dummy)

        local ang = ent:GetAngles()
        ang.p = 0
        ang.r = 0
        ent:SetAngles(ang)
        ent:SetPos(pos)
    end

    ent:SetNW2Bool("jrpg_knockout", false)

    if CLIENT then
        ent.jrpg_knockout_getup = CurTime()
        ent.jrpg_knockout_timer = nil

        timer.Simple(1, function()
            if not ent:IsValid() then return end
            ent.jrpg_knockout_getup = nil
            reset_manip(ent)
            ent:SetRenderAngles(NULL)
            ent:SetRenderOrigin(NULL)
        end)
    end
end

if CLIENT then
    net.Receive("jrpg_knockout_cancel", function()
        local ent = net.ReadEntity()
        if not ent:IsValid() then return end

        jrpg.CancelKnockout(ent)
    end)

    net.Receive("jrpg_knockout_start", function()
        local ent = net.ReadEntity()
        if not ent:IsValid() then return end
        local attacker = net.ReadEntity()
        local vel = net.ReadVector()

        jrpg.KnockoutEntity(ent, attacker, vel)
    end)

end
if SERVER then
    util.AddNetworkString( "jrpg_knockout_start" )
    util.AddNetworkString( "jrpg_knockout_cancel" )
end

function jrpg.KnockoutEntity(ent, attacker, vel, broadcast)
    if broadcast then
        net.Start( "jrpg_knockout_start" )
            net.WriteEntity( ent )
            net.WriteEntity( attacker )
            net.WriteVector( vel )
        net.Broadcast()
    end

    if ent:GetNW2Bool("jrpg_knockout") then
        jrpg.CancelKnockout(ent, broadcast)
    end

    if SERVER then
        if ent.SetCondition then
            ent:SetCondition( COND_NPC_FREEZE )
        end
    end

    ent.jrpg_knockout_old_sequence = ent:GetSequence()
    ent:SetNW2Bool("jrpg_knockout", true)

    if SERVER then
        local dummy = ents.Create("prop_physics")
        ent.jrpg_knockout_dummy = dummy
        dummy:SetModel("models/props_junk/rock001a.mdl")
        dummy:SetPos(ent:WorldSpaceCenter())
        dummy:SetAngles(ent:GetAngles())
        dummy:SetNoDraw(true)
        ent:SetParent(dummy)
        ent:SetLocalPos(-ent:OBBCenter())
        dummy:SetSolid(SOLID_VPHYSICS)
        dummy:Spawn()
        --dummy:PhysicsInitBox(Vector(1,1,1)*-10, Vector(1,1,1)*10)
        dummy:PhysicsInitSphere(ent:BoundingRadius()/2)
        if dummy.CPPISetOwner then
            dummy:CPPISetOwner(ent)
        end
        dummy:SetOwner(attacker)
        dummy.jrpg_is_knockout = true

        dummy:AddCallback("PhysicsCollide", function(ent, data)
            if data.HitEntity:IsNPC() then
                jrpg.KnockoutEntity(data.HitEntity, attacker, data.PhysObject:GetVelocity(), true)
            end
            data.PhysObject:SetVelocity(data.PhysObject:GetVelocity() / 3)
        end)

        ent:SetNotSolid(true)

        ent:CallOnRemove("jrpg_pushent", function()
            SafeRemoveEntity(dummy)
        end)

        local phys = dummy:GetPhysicsObject()
        if phys:IsValid() then
           -- phys:EnableGravity(false)
            phys:SetDamping(0, 10000)
            phys:SetMaterial("gmod_bouncy")
            phys:SetVelocity(vel)
            phys:SetMass(100)
        end

        local id = "jrpg_knockout_" .. ent:EntIndex()
        local sleep = nil
        timer.Create(id, 0.1, 0, function()
            if not ent:IsValid() then timer.Remove(id) return end
            if not dummy:IsValid() then timer.Remove(id) return end
            local phys = dummy:GetPhysicsObject()
            if not phys:IsValid() then timer.Remove(id) return end

            if phys:GetVelocity():Length() < 0.1 then
                sleep = sleep or CurTime() + 1

                if sleep < CurTime() then
                    timer.Remove(id)
                    if ent:IsValid() then
                        jrpg.CancelKnockout(ent, true)
                    end
                end
            else
                sleep = nil
            end
        end)
    end

    if CLIENT then
        ent.jrpg_knockout_timer = CurTime()
        table.insert(knockouts, ent)
    end

end

hook.Remove("KeyRelease", "")

hook.Add("KeyPress", "", function(ply, key)
    if not IsFirstTimePredicted() then return end
    if ply ~= me then return end
    if key ~= IN_USE then return end
    local ent = ply:GetEyeTrace().Entity
    if not ent:IsValid() then return end

    if ent.jrpg_knockout_id then
        return
    end

--    jrpg.KnockoutEntity(ent, ply, (ply:GetAimVector() + Vector(0,0,1)) * 300)
end)
