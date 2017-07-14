hook.Add("InitPostEntity","hide_public_dupes",function()
  creation_tab_old = creation_tab_old or spawnmenu.GetCreationTabs

  spawnmenu.GetCreationTabs = function()
      local HideTabs ={["#spawnmenu.category.dupes"] = true,
                       ["#spawnmenu.category.saves"] = true}

      local tabs = {}
      for k, v in next, creation_tab_old() do
          if not HideTabs[k] then
              tabs[k] = v
          end
      end

      return tabs
  end
  LocalPlayer():ConCommand("spawnmenu_reload")
end)
