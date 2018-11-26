local hooks = {
    "PlayerSpawnedEffect",
    "PlayerSpawnedNPC",
    "PlayerSpawnedProp",
    "PlayerSpawnedRagdoll",
    "PlayerSpawnedSENT",
    "PlayerSpawnedSWEP",
    "PlayerSpawnedVehicle",
}

for _, event in ipairs(hooks) do
    hook.Add(event, "jrpg_battlecam_spawn_fix", function(...)
        local args = {...}
        local ply = args[1]
        local tp = ply:GetInfo("battlecam_enabled")
        if tp == "1" then
            local ent = args[#args]
            if IsEntity(ent) and ent:GetPos():Distance(ply:GetPos()) > 700 then
                ent:SetPos(ply:EyePos() + ply:GetAimVector() * 300)
            end
        end
    end)
end