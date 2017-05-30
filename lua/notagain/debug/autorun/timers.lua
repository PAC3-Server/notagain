local Timers = Timers or {}

local old_timercreate = timer.Create 

timer.Create = function(name,delay,rep,callback)
	Timers[name] = {
		Delay = delay,
		Repetitions = rep == 0 and "inf" or rep,
		Callback = callback,
	}
	old_timercreate(name,delay,rep,callback)
end

timer.GetAll = function()
	return Timers 
end

timer.Find = function(tim)
	local found = {}
	for name,ti in pairs(Timers) do
		if string.match(tostring(name),tim,1) then
			found[name] = ti 
		end
	end
	return found 
end
