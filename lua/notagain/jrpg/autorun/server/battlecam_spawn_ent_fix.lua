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

            local rand = ply:GetAimVector() + VectorRand()*0.5
            rand.z = 0

            ent:SetPos(util.QuickTrace(ply:EyePos(), rand * 200, ply).HitPos)
            ent:DropToFloor()
        end
    end)
end