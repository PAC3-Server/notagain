util.AddNetworkString("crashsys")

local loaded = {}
local table = table

local function ping(target, bit)
	local bit = bit and true or false
	if target then
		net.Start("crashsys", true)
		net.WriteBit(bit)
		net.Send(target)
	end
end

net.Receive("crashsys", function(len, ply)
	if not IsValid(ply) then return end
	if not table.HasValue(loaded, ply) then
		table.insert(loaded, ply)
	end
end)

hook.Add("PlayerDisconnected", "crashsys", function(ply)
	ping(ply, false)
	table.RemoveByValue(loaded, ply)
end)

timer.Create("crashsys", 3, 0, function()
	ping(loaded, false)
end)

hook.Add("ShutDown", "crashsys", function()
	ping(ply, true)
end)
