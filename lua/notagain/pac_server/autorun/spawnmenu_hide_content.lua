if engine.ActiveGamemode() ~= "sandbox" then return end

if CLIENT then
	local hide_tabs = {
		["#spawnmenu.category.dupes"] = true,
		["#spawnmenu.category.saves"] = true,
		["VJ Base"] = true,
	}

	local hide_categories = {
		["VJ Base"] = true,
	}

	hook.Add("OnSpawnMenuOpen", "spawnmenu_hide_content", function()
		while true do
			local found = false

			for k, v in pairs(g_SpawnMenu.CreateMenu:GetItems()) do
				if hide_tabs[v.Name] then
					g_SpawnMenu.CreateMenu:CloseTab(v.Tab, true)
					found = true
					break
				end
			end

			if not found then break end
		end

		for k, v in pairs(g_SpawnMenu.CreateMenu:GetItems()) do
			if v.Name == "#spawnmenu.category.entities" or v.Name == "#spawnmenu.category.weapons" then
				local ok, err = pcall(function()
					for k, v in pairs(v.Panel:GetChildren()[1].HorizontalDivider:GetLeft().Tree:Root().ChildNodes:GetChildren()) do
						if hide_categories[v:GetText()] then
							v:Remove()
						end
					end
				end)

				if not ok then
					ErrorNoHalt(err)
				end
			end
		end
	end)
end
