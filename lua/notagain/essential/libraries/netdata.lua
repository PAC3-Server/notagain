local netdata = {}


local meta={__index=table}
local queue=setmetatable({},meta )
local started=false
local function doqueue()
	local sent
	for pl,plqueue in pairs(queue) do
		sent=true
		if not IsValid(pl) then
			queue[pl]=nil
		else
			local func = plqueue:remove(1)
			if not func then
				queue[pl]=nil
			else
				--Dbg("doqueue",pl)
				local ok,err = pcall(func)
				if not ok then
					ErrorNoHalt(err..'\n')
				end
			end
		end
	end
	if not sent then 
		started=false
		hook.Remove("Think",'netqueue') 
	end
end

local function net_queuesingle(pl,func)
	if not started then
		hook.Add("Think",'netqueue',doqueue)
	end
	
	local plqueue=queue[pl] or setmetatable({},meta)
	queue[pl]=plqueue
	plqueue:insert(func)
end

local function net_queue(targets,func)
	if targets==true then 
		targets=nil
	elseif targets and isentity(targets) then
		targets={targets}
	end
	for _,pl in pairs(targets or player.GetHumans()) do
		net_queuesingle(pl,function() func(pl) end)
	end
end

local Tag="NetData"
local data_table=({})

local function Set(id,key,value)
	local tt=data_table[id]
	if not tt then
		tt={}
		data_table[id]=tt
	end
	tt[key]=value
	--print("Set",id,key,value)
end
local function Get(id,key)
	local tt = data_table[id]
	return tt and tt[key]
end

local lookup={}	

if SERVER then
	util.AddNetworkString(Tag)
	

	
	local function ReplicateData(id,key,value,targets)
		local queuefunc = function(pl) 
			net.Start(Tag)
				net.WriteUInt(id,16)
				net.WriteString(key)
				net.WriteType(value)
			net.Send(pl)
		end
		for _,pl in pairs(targets and (istable(targets) and targets or {targets}) or player.GetHumans()) do
			net_queue(pl,queuefunc)
		end
	end
	
	hook.Add("PlayerInitialSpawn",Tag,function(pl) 
		
		-- only transmit valid players
		-- TODO: Purge old players?
		local valid={}
		for k,v in pairs(player.GetAll()) do
			valid[v:UserID()]=true
		end
		
		for id,data_table in pairs(data_table) do
			if valid[id] then
				for key,value in pairs(data_table) do
					ReplicateData(id,key,value,pl)
				end
			end
		end
		
	end)

	function netdata.SetData(self, key,value)
		
		local id = lookup[self]
		if not id then
			id = self:UserID()
			lookup[self]=id
		end
		
		local lastval = Get(id,key)
		
		Set(id,key,value)
		
		if lastval!= value then
			ReplicateData(id,key,value)
		end
	end
	
	net.Receive(Tag,function(len,self)
		local id = self:UserID()		
		local key = net.ReadString()
		local _type = net.ReadUInt( 8 )
		local value = net.ReadType(_type)
		
		-- for necessity
		if hook.Call(Tag,nil,self,key,value)==true then
			netdata.SetData(self, key,value)
		end
	end)
	
else
	net.Receive(Tag,function(len)
			
		local id = net.ReadUInt(16)
		local key = net.ReadString()
		local _type = net.ReadUInt( 8 )
		local value = net.ReadType(_type)
		Set(id,key,value)
		
		hook.Call(Tag,nil,id,key,value)
	end)
	
	function netdata.SetData(self, key,value)
		if self~=LocalPlayer() then error"not implemented" end
		net.Start(Tag)
			net.WriteString(key)
			net.WriteType(value)
		net.SendToServer()

	end
	
end

local lookup={}
function netdata.GetData(self, key)
	local id = lookup[self]
	if not id then
		id = self:UserID()
		lookup[self]=id
	end
	
	return Get(id,key)
end

return netdata
