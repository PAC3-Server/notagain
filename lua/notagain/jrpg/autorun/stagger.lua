local ease = requirex("ease")

local function manip_angles(ply, id, ang)
    if pac and pac.ManipulateBoneAngles then
        pac.ManipulateBoneAngles(ply, id, ang)
    else
        ply:ManipulateBoneAngles(id, ang)
    end
end

local queue = {}

local function calc_staggnation()
     for i = #queue, 1, -1 do
        local data = queue[i]

        if not data.ent:IsValid() or not jrpg.IsActorAlive(data.ent) then  
            table.remove(queue, i)
            continue
        end

        if not data.ent.jrpg_stagger_bones or data.ent.jrpg_stagger_lastmdl ~= data.ent:GetModel() then
            data.ent.jrpg_stagger_bones = {}
            local center = data.ent:NearestPoint(data.ent:EyePos())
            local radius = data.ent:BoundingRadius() / 1.6
            for i = 0, data.ent:GetBoneCount() do
                local pos, ang = data.ent:GetBonePosition(i)
                if pos then
                    if pos:Distance(center) < radius then
                        table.insert(data.ent.jrpg_stagger_bones, i)
                    end
                end
            end
            if false and #data.ent.jrpg_stagger_bones <= 1 then
                for i = 0, data.ent:GetBoneCount() do
                    table.insert(data.ent.jrpg_stagger_bones, i)                  
                end
            end

            data.ent.jrpg_stagger_lastmdl = data.ent:GetModel()
        end

        local time = (data.time - CurTime()) / data.length
        local f = math.Clamp(time, 0, 1)           
        f = -f + 1
        f = f * 2
        if f > 1 then 
            f = -(f - 1) + 1 
            f = ease.inOutQuad(f, 0, 1, 1)
        else
            f = ease.outExpo(f, 0, 1, 1)
        end

        if time > 0 then
            if not data.tposed and data.ent:GetSequence(0) ~= 0 then
                data.prev_seq = data.ent:GetSequence()
                data.ent:SetSequence(0)
                data.tposed = true
            elseif data.prev_seq then
                data.ent:SetSequence(data.prev_seq)
                data.prev_seq = nil
            end
        end
        
        local weight = f * data.force

        for i, id in ipairs(data.ent.jrpg_stagger_bones) do
            math.randomseed(i+data.dir.z)
            local p = weight*math.Rand(-1,1)
            local y = weight*math.Rand(-1,1)
            manip_angles(data.ent, id, Angle(p+data.dir.x*f,y+data.dir.y*f,0))
        end

        if time < 0 then
            for _, id in ipairs(data.ent.jrpg_stagger_bones) do
                manip_angles(data.ent, id, Angle(0,0,0))
            end

            table.remove(queue, i)
        end

        if CLIENT then
            data.ent:SetupBones()
        end
    end
end

if CLIENT then
    hook.Add("PreDrawOpaqueRenderables", "jrpg_stagger", function()
        calc_staggnation()
    end)
end

if SERVER then
    hook.Add("Think", "jrpg_stagger", function()
        calc_staggnation()
    end)
end

local function add_to_queue(ent, time, length, dir, force)
    for i = #queue, 1, -1 do
        if queue[i].ent == ent then
            if queue[i].length > 1.5 and queue[i].length > length then return end
            table.remove(queue, i)
            break
        end
    end

    table.insert(queue, {
        ent = ent, 
        time = time,
        length = length,
        dir = dir,
        force = force,
    })
end

net.Receive("jrpg_stagger", function()
    local ent = net.ReadEntity()
    if not ent:IsValid() then return end
    local time = net.ReadFloat()
    local length = net.ReadFloat()
    local dir = net.ReadVector()
    local force = net.ReadFloat()

    add_to_queue(ent, time, length, dir, force)
end)

if SERVER then
    util.AddNetworkString("jrpg_stagger")

    function jrpg.Stagnate(ent, length, force)
        length = length or 0.4
        force = force or 1
        
        local freeze_time = length - 0.1
        if freeze_time > 0 and force > 0.1 then
            jrpg.FreezeEntity(ent, true)
            timer.Create("freeze_" .. tostring(ent), freeze_time, 1, function()
                if ent:IsValid() then
                    jrpg.FreezeEntity(ent, false)  
                end
            end)
        end

        length = length + 0.1
        local time = CurTime() + length
        local dir = VectorRand()*force*10

        net.Start("jrpg_stagger")
            net.WriteEntity(ent)
            net.WriteFloat(time)
            net.WriteFloat(length)
            net.WriteVector(dir)
            net.WriteFloat(force)
        net.Broadcast()

        add_to_queue(ent, time, length, dir, force)
    end

    hook.Add("EntityTakeDamage", "stagger", function(ent, dmginfo)
        if jrpg.IsActor(ent) then
            if not ent:IsPlayer() or jrpg.IsEnabled(ply) then
                local f = math.Clamp(dmginfo:GetDamage() / ent:GetMaxHealth(), 0, 1)
                
                
                jrpg.Stagnate(ent, Lerp(f, 0.4, 1.5), Lerp(f, 0.5, 3))
            end
        end
    end)
end