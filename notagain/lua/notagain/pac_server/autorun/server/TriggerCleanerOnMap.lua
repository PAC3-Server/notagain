hook.Add("Initialize","ClearUselessTriggers",function()
	for _,v in pairs(ents.GetAll()) do
		if v:GetClass():match("trigger_*") then
			v:Remove()
		end
	end
end)
