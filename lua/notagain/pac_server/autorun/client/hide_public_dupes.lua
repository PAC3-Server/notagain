local TabsModified = false

local GetCreationTabs = spawnmenu.GetCreationTabs

local TabsToRemove = {
  ["#spawnmenu.category.saves"] = 1,
	["#spawnmenu.category.dupes"] = 1,
  ["VJ Base"] = 1,
	-- ["#spawnmenu.category.entities"] = 1,
	-- ["#spawnmenu.category.npcs"] = 1,
	-- ["#spawnmenu.category.postprocess"] = 1,
	-- ["#spawnmenu.category.vehicles"] = 1,
	-- ["#spawnmenu.category.weapons"] = 1,
	-- ["#spawnmenu.content_tab"] = 1,
}

local function DestroySpawnTabs()
	for k,_ in next, GetCreationTabs() do
		if TabsToRemove[k] == 1 then
			GetCreationTabs()[k] = nil
		end
	end
	if not TabsModified then
		LocalPlayer():ConCommand('spawnmenu_reload')
		TabsModified = true
	end
end

hook.Add("PopulatePropMenu", "RemoveSpawnmenuTabs", DestroySpawnTabs)
