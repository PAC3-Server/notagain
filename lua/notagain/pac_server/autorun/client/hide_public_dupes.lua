hook.Add("InitPostEntity","hide_public_dupes",function()
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
  timer.Simple(0.1,function() RunConsoleCommand("spawnmenu_reload") end)
end)
