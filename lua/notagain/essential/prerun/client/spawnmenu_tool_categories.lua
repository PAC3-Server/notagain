spawnmenu.old_AddToolMenuOption = spawnmenu.old_AddToolMenuOption or spawnmenu.AddToolMenuOption

spawnmenu.AddToolMenuOption = function(tab,cat,class,name,cmd,config,cpanel,tbl)
    local tab = tab
    local alloweds = {
        [""] = true, --tools?
        ["Tools"] = true,
        ["Utilities"] = true,
        ["Wire"] = true,
    }
    if not tab or not alloweds[tab] then
        tab = "Utilities"
    end
    spawnmenu.old_AddToolMenuOption(tab,cat,class,name,cmd,config,cpanel,tbl)
end