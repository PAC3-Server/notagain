if not game.SinglePlayer() then return end
local unpaused = false
hook.Add("DrawOverlay", "unpause", function()
	if gui.IsGameUIVisible() then
		if not unpaused then
			RunConsoleCommand("unpause")
			unpaused = true
		end
	else
		unpaused = false
	end
end)