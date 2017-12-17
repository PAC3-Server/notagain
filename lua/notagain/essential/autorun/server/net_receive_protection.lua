if SERVER then
	net.old_incoming = net.old_incoming or net.Incoming

	local last_receive_error = {}
	local last_print_suppress = {}

	function net.Incoming(length, ply, ...)
		if ... then
			ErrorNoHalt("net.Incoming called with more than 2 arguments? skipping pcall protection")
			return net.old_incoming(length, ply, ...)
		end

		if last_receive_error[ply] and last_receive_error[ply] + 1 > SysTime() then
			if not last_print_suppress[ply] or last_print_suppress[ply] < RealTime() then
				print("last message from ", ply, "errored less than a second ago, supressing net message")
				last_print_suppress[ply] = RealTime() + 1
			end
			return
		end

		local tbl = {xpcall(
			net.old_incoming,
			function(msg)
				print("net message " .. id .. " from ", ply, " errored:")
				ErrorNoHalt(debug.traceback(msg, 2))
			end, length, ply
		)}

		if tbl[1] then
			return unpack(tbl, 2)
		end

		last_receive_error[ply] = SysTime()
	end

	if player.GetAll()[1] then
		util.AddNetworkString("test_error")
		net.Receive("test_error", function() error("!!!") end)
	end
end