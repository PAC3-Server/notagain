include("notagain.lua")

notagain.Initialize()

if hook.GetTable().PreGamemodeLoaded and hook.GetTable().PreGamemodeLoaded.notagain then
	notagain.Autorun()
end

hook.Add("PreGamemodeLoaded", "notagain", function()
	notagain.Autorun()
end)

concommand.Add("notagain_reload", function()
	local str = file.Read(notagain.addon_dir .. "lua/notagain.lua", "MOD")
	if str then
		CompileString(str, "lua/notagain.lua")()
	else
		include("lua/notagain.lua")
	end

	notagain.Initialize()
	notagain.Autorun()
end)