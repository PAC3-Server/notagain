if SERVER then
	net.old_receive = net.old_receive or net.Receive

	function net.Receive(id, callback, ...)
		if ... then
			ErrorNoHalt("net.Receive called with more than 3 arguments? skipping pcall protection")
			return net.old_receive(id, callback, ...)
		end

		net.old_receive(id, function(length, ply, ...)
			if ply.net_last_receive_error and ply.net_last_receive_error + 1 > SysTime() then
				if not ply.net_last_print_suppress or ply.net_last_print_suppress < RealTime() then
					print("last message from ", ply, "errored less than a second ago, supressing net message")
					ply.net_last_print_suppress = RealTime() + 1
				end
				return
			end

			local tbl = {xpcall(callback, function(msg) print("net message " .. id .. " from ", ply, " errored:") ErrorNoHalt(msg .. "\n" .. debug.traceback()) end, length, ply, ...)}
			if tbl[1] then
				return unpack(tbl, 2)
			end

			ply.net_last_receive_error = SysTime()
		end)
	end

	if player.GetAll()[1] then
		util.AddNetworkString("test_error")
		net.Receive("test_error", function() error("!!!") end)
	end
end