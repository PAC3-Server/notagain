local Hooks = hook.GetTable() -- so hooks called before get registered

local old_hookadd    = hook.Add 
local old_hookremove = hook.Remove

hook.Add = function(hk,hkname,callback)
	Hooks[hk] = Hooks[hk] or {}
	Hooks[hk][hkname] = callback 
	old_hookadd(hk,hkname,callback)
end

hook.Remove = function(hk,hkname)
	if Hooks[hk][hkname] then
		Hooks[hk][hkname] = nil 
	end
	old_hookremove(hk,hkname)
end

hook.GetAll = function() -- less intensive way to get all hooks
	return Hooks 
end

hook.Find = function(hk)
	local found = {}
	local hk = string.lower(hk)
	for type,_ in pairs(Hooks) do
		for name,callback in pairs(Hooks[type]) do
			if string.match(tostring(name),string.PatternSafe(hk),1) then
				found[type] = found[type] or {}
				found[type][name] = callback
			end
		end
	end
	return found
end
