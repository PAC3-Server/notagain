local pushaway = {}

local function is_clustered(ent)
    for i,v in ipairs(ents.FindInBox(ent:WorldSpaceAABB())) do
        if v:IsNPC() and v ~= ent then
            return true
        end
    end
end

hook.Add("Think", "npc_spawn_uncluster", function()
    for i, npc in ipairs(pushaway) do
        if not npc:IsValid() or not is_clustered(npc) then
            table.remove(pushaway, i)
            return
        end

        local center = VectorRand()
        local count = 1
        for _, ent in ipairs(ents.FindInSphere(npc:GetPos(), npc:BoundingRadius() * 10)) do
            if npc ~= ent and ent:IsNPC() then
                center = center + ent:GetPos()
                count = count + 1
            end
        end

        center = center / count
        center.z = npc:GetPos().z

        local new_pos = npc:GetPos() + ((npc:GetPos() - center):GetNormalized() + Vector(math.Rand(-0.5,0.5), math.Rand(-0.5,0.5),0))*3

        npc:SetPos(new_pos)
        npc:DropToFloor()
    end
end)

hook.Add("OnEntityCreated", "npc_spawn_uncluster", function(ent)
    if not ent:IsNPC() then return end
    timer.Simple(0, function()
        if not ent:IsValid() then return end
        if is_clustered(ent) then
            table.insert(pushaway, ent)
        end
    end)
end)