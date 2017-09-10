spawnmenu.old_AddToolMenuOption = spawnmenu.old_AddToolMenuOption or spawnmenu.AddToolMenuOption
spawnmenu.old_AddToolCategory   = spawnmenu.old_AddToolCategory or spawnmenu.AddToolCategory

local Properify = function(tab)
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
    return tab
end

spawnmenu.AddToolMenuOption = function(tab,cat,class,name,cmd,config,cpanel,tbl)
    spawnmenu.old_AddToolMenuOption(Properify(tab),cat,class,name,cmd,config,cpanel,tbl)
end

spawnmenu.AddToolCategory = function(tab,realname,printname)
    spawnmenu.old_AddToolCategory(Properify(tab),realname,printname)
end
