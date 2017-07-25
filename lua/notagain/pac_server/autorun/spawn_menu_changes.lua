if CLIENT then

    local HideUselessStuff = function()
        local npcs = list.GetForEdit("NPC")
        if npcs.sent_vj_test then
            npcs.sent_vj_test = nil
        end
        if npcs.npc_vj_aerialtest then
            npcs.npc_vj_aerialtest = nil
        end
        if npcs.npc_tf2_ghost then
            npcs.npc_tf2_ghost = nil
        end
        local weapons = list.GetForEdit("Weapon")
        for k,v in pairs(weapons) do
            if string.match(k,"weapon%_vj*") then
                weapons[k] = nil
            end
        end
        local entities = list.GetForEdit("SpawnableEntities")
        for k,v in pairs(entities) do
            if string.match(k,"sent%_vj*") then
                entities[k] = nil
            end
        end
    end

    hook.Add("InitPostEntity","spawn_menu_changes",function()
        creation_tab_old = creation_tab_old or spawnmenu.GetCreationTabs

        spawnmenu.GetCreationTabs = function()
            local HideTabs ={
                ["#spawnmenu.category.dupes"] = true,
                ["#spawnmenu.category.saves"] = true,
                ["VJ Base"] = true,
            }

            local tabs = {}
            for k, v in next, creation_tab_old() do
                if not HideTabs[k] then
                    tabs[k] = v
                end
            end

            return tabs
        end

        HideUselessStuff()

        timer.Simple(0.1,function() RunConsoleCommand("spawnmenu_reload") end)

    end)
end
