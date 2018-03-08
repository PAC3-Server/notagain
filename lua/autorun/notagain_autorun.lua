if not _G.notagain then
	include("notagain.lua")
end

notagain.Initialize()

hook.Add("PreGamemodeLoaded", "notagain", function()
	notagain.Autorun()
	hook.Remove("PreGamemodeLoaded", "notagain")
end)
