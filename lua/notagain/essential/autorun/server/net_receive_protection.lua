if SERVER then
	local SysTime = SysTime
	local RealTime = RealTime

	function net.Incoming(length, ply)
		if (ply.net_incoming_last_error or 0) + 1 > SysTime() then
			if (ply.net_incoming_last_print_suppress or 0) < RealTime() then
				MsgN(("suppressing net message from %s (%s) because of lua error less than a second ago"):format(tostring(ply), ply:SteamID()))
				ply.net_incoming_last_print_suppress = RealTime() + 1
			end
		else
			local i = net.ReadHeader()
			local id = util.NetworkIDToString(i)

			if id then
				local func = net.Receivers[id:lower()]

				if func then
					local ok = xpcall(
						func,
						function(msg)
							ErrorNoHalt(debug.traceback(("net message %q (%s) from %s (%s) errored:"):format(id, string.NiceSize(length), tostring(ply), ply:SteamID())))
						end,
						length - 16,
						ply
					)

					if not ok then
						ply.net_incoming_last_error = SysTime()
					end
				end
			end
		end
	end
end