spawnmenu.old_AddToolMenuOption = spawnmenu.old_AddToolMenuOption or spawnmenu.AddToolMenuOption

spawnmenu.AddToolMenuOption = function(tab,cat,class,name,cmd,config,cpanel,tbl)
    local tab = tab
    local alloweds = {
        ["main"] = true, --tools?
        ["tools"] = true,
        ["utilities"] = true,
        ["wire"] = true,
    }
    if not tab or not alloweds[tab] then
        if alloweds[string.lower(tab)] then
            tab = string.SetChar(tab,1,string.upper(tab[1]))
        else
            tab = "Utilities"
        end
    end
    spawnmenu.old_AddToolMenuOption(tab,cat,class,name,cmd,config,cpanel,tbl)
end
