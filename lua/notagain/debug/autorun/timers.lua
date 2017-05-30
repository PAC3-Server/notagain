local Timers = Timers or {}

local old_timercreate  = timer.Create 
local old_timeradjust  = timer.Adjust
local old_timerremove  = timer.Remove 
local old_timerdestroy = timer.Destroy

timer.Create = function(name,delay,rep,callback)
	if rep == 0 then
		Timers[name] = {
			Delay = delay,
			Callback = callback,
		}
	end
	
	old_timercreate(name,delay,rep,callback)
end

timer.Adjust = function(name,delay,rep,callback)
	if Timers[name] then
		if rep == 0 then
			Timers[name] = {
				Delay = delay, 
				Callback = callback,
			}
		end
	end
	
	return old_timeradjust(name,delay,rep,callback)

end

timer.Remove = function(name)
	if Timers[name] then
		Timers[name] = nil 
	end
	old_timerremove(name)
end

timer.Destroy = function(name)
	if Timers[name] then
		Timers[name] = nil 
	end
	old_timerdestroy(name)
end

timer.GetAll = function()
	return Timers 
end

timer.Find = function(tim)
	local found = {}
	local tim = string.lower(tim)
	for name,ti in pairs(Timers) do
		if string.match(string.lower(tostring(name)),string.PatternSafe(tim),1) then
			found[name] = ti 
		end
	end
	return found 
end
