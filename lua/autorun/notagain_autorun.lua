if not _G.notagain then
	include("notagain.lua")
end

hook.Add("PostGamemodeLoaded", "notagain", function()
	notagain.Autorun()
	hook.Remove("PostGamemodeLoaded", "notagain")
end)