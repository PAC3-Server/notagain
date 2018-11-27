hook.Add("PlayerSpawnedNPC", "jrpg_spawn_powerful_npcs", function(ply, ent)
    if not jrpg.IsEnabled(ply) then return end
    local max = ent:GetMaxHealth() * (ply:GetMaxHealth()/100) * 10
    ent:SetHealth(max)
    ent:SetMaxHealth(max)
    print(max)
end) 