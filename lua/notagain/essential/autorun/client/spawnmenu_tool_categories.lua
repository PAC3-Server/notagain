spawnmenu.old_AddToolMenuOption = spawnmenu.old_AddToolMenuOption or spawnmenu.AddToolMenuOption

spawnmenu.AddToolMenuOption = function(tab,cat,class,name,cmd,config,cpanel,tbl)
    local cat = cat
    local alloweds = {
        "Tools" = true,
        "Utilities" = true,
        "Wire" = true,
    }
    if not cat or not alloweds[cat] then
        cat = "Utilities"
    end
    spawnmenu.old_AddToolMenuOption(tab,cat,class,name,cmd,config,cpanel,tbl)
end