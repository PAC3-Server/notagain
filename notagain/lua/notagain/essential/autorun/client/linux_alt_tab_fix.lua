if not system.IsLinux() then return end

local alt_tabbed = false

hook.Add("Think", "linux_alt_tab_fix", function()
	if system.HasFocus() then
		if not alt_tabbed then
			gui.EnableScreenClicker(false)
			alt_tabbed = true
		end
	else
		if alt_tabbed then
			gui.EnableScreenClicker(true)
			alt_tabbed = false
		end
	end
end)