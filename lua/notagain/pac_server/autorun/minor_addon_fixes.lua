if CLIENT then
    hook.Add("PreGamemodeLoaded", "vjdrej", function()
        hook.Remove("AddToolMenuTabs", "VJ_CREATETOOLTAB")
        hook.Remove("PreGamemodeLoaded", "vjdrej")
    end)
end

if SERVER then
    timer.Simple(1, function()
        hook.Remove("PlayerInitialSpawn", "VJBaseSpawn")
    end)
end