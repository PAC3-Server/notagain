include("notagain.lua")

notagain.Initialize()

if hook.GetTable().PreGamemodeLoaded and hook.GetTable().PreGamemodeLoaded.notagain then
	notagain.Autorun()
end

hook.Add("PreGamemodeLoaded", "notagain", function()
	notagain.Autorun()
end)
