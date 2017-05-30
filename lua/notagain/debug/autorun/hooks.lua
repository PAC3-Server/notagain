local Hooks = Hooks or {}

local old_hookadd = hook.Add 

hook.Add = function(hk,hkname,callback)
	Hooks[hk] = Hooks[hk] or {}
	Hooks[hk][hkname] = callback 
	old_hookadd(hk,hkname,callback)
end

hook.GetAll = function()
	return Hooks 
end

hook.Find = function(hk)
	local found = {}
	for type,_ in pairs(Hooks) do
		for name,callback in pairs(Hooks[type]) do
			if string.match(tostring(name),hk,1) then
				found[type] = found[type] or {}
				found[type][name] = callback
			end
		end
	end
	return found
end
