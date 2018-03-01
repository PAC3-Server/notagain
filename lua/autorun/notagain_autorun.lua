if not _G.notagain then
	include("notagain.lua")
end

hook.Add("PreGamemodeLoaded", "notagain", function()
		print(engine.ActiveGamemode(), "?!?!?!")
	notagain.Autorun()
	hook.Remove("PreGamemodeLoaded", "notagain")
end)