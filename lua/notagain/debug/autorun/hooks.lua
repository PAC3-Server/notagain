local Hooks     = hook.GetTable() or {} -- so hooks called before get registered
local Faileds   = Faileds or {}
local NWs       = NWs or {}

local HookAddNetString    = "__NW__HOOKS__ADD__"
local HookRemoveNetString = "__NW__HOOKS__END__"
local HookRunNetString    = "__NW__HOOKS__RUN__"

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
			if string.match(string.lower(tostring(name)),string.PatternSafe(hk),1) then
				found[type] = found[type] or {}
				found[type][name] = callback
			end
		end
	end
	return found
end

hook.GetNWs = function()
	return NWs
end

hook.FindNW = function(hk)
	local found = {}
	local hk = string.lower(hk)
	for type,_ in pairs(NWs) do
		for name,callback in pairs(NWs[type]) do
			if string.match(string.lower(tostring(name)),string.PatternSafe(hk),1) then
				found[type] = found[type] or {}
				found[type][name] = callback
			end
		end
	end
	return found
end

if SERVER then

	util.AddNetworkString(HookAddNetString)
	util.AddNetworkString(HookRemoveNetString)
	util.AddNetworkString(HookRunNetString)

	hook.AddNW = function(hk,hkname,callback)

		local netname = "__NW__"..hkname
		local tbl = {
				Type = hk,
				Name = khname,
				Callback = callback,
		}
					
		hook.Add(hk,netname,callback)

		NWs[hk] = NWs[hk] or {}
		NWs[hk][hkname] = callback 
		
		net.Start(HookAddNetString)
		net.WriteTable(tbl)
		net.Broadcast()

		hook.Add("OnPlayerInitialSpawn","__NW__INIT__"..hkname,function(ply)
			net.Start(HookAddNetString)
			net.WriteTable(tbl)
			net.Send(ply)
		end)

	end

	hook.RemoveNW = function(hk,hkname)

		local netname = "__HW__"..hkname

		NWs[hk][hkname] = nil

		hook.Remove(hk,netname)

		net.Start(HookRemoveNetString)
		net.WriteString(hk)
		net.WriteString(hkname)
		net.Broadcast()

		hook.Add("OnPlayerInitialSpawn","__NW__END__"..hkname,function(ply)
			net.Start(HookRemoveNetString)
			net.WriteString(hk)
			net.WriteString(hkname)
			net.Broadcast()
		end)
	
	end

	hook.RunNW = function(name,...)
		local tbl = {
			Name = name,
			Args = { ... },
		}

		hook.Run(name,...)

		net.Start(HookRunNetString)
		net.WriteTable(tbl)
		net.Broadcast()
	end

end

	
if CLIENT then
	
	net.Receive(HookAddNetString,function()
		local tbl = net.ReadTable()
		hook.Add(tbl.Type,tbl.Name,tbl.Callback)
		NWs[tbl.Type] = NWs[tbl.Type] or {}
		NWS[tbl.Type][tbl.Name] = tbl.Callback
	end)

	net.Receive(HookRemoveNetString,function()
		local t = net.ReadString()
		local n = net.ReadString()
		hook.Remove(t,n)
		NWs[hk][hkname] = nil
	end)

	net.Receive(HookRunNetString,function()
		local tbl = net.ReadTable()
		hook.Run(tbl.Name,unpack(tbl.Args))
	end)

end

local cachehookerr = function(name,err)
	if #Faileds >= 30 then
		table.remove(Faileds,1)
	end 
	local add = true
	local tbl = {
		File = name,
		Line = string.match(err,"(%>%:(%d*)%:){1}"),
		Error = err,
	}
	for k,v in pairs(Faileds) do
		if v == tbl then
			add = false 
			break 
		end
	end
	
	if add then
		table.insert(Faileds,tbl)
	end
end

--dont look at this its an attempt to catch failed hooks
hook.Add("OnLuaError","__HOOKS__FAILED__",function(err,_,name,_)
	local hookerr = string.match(err,"(lua%/includes%/modules%/hook)")
	if hookerr then
		cachehookerr(name,err)
	end
end)

hook.GetFailed = function()
	return Faileds 
end
