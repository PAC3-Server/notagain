if game.GetMap() ~= "gm_bluehills_test3" then return end

hook.Add("InitPostEntity", "bluehills_grass", function()
	local ent = ents.Create("env_skypaint")
    ent:Spawn()
    ent:Activate()

    ent:SetKeyValue("sunposmethod", "0")
    ent:SetKeyValue("drawstars", "1")
    ent:SetKeyValue("startexture", "skybox/starfield")

    RunConsoleCommand("sv_skyname", "painted")

    hook.Remove("InitPostEntity", "bluehills_grass")
end)