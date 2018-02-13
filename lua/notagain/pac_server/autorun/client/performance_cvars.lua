local settings = {
	r_WaterDrawReflection = 0,
	r_3dsky = 0,
	mat_forceaniso = 16,
	mat_hdr_level = 0,
}

local cvars = {}

for k,v in pairs(settings) do
	RunConsoleCommand(k, v)
	cvars[k] = GetConVar(k):GetString()
end

hook.Add("ShutDown", "perf_cvars", function()
	for k,v in pairs(cvars) do
		RunConsoleCommand(k, v)
	end
end)