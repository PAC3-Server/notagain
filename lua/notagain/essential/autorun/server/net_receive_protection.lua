if SERVER then
	local SysTime = SysTime
	local RealTime = RealTime

	local function warn(ply, fmt, ...)
		ply.net_incoming_last_print_suppress = ply.net_incoming_last_print_suppress or {}
		ply.net_incoming_last_print_suppress[fmt] = ply.net_incoming_last_print_suppress[fmt] or RealTime()

		if ply.net_incoming_last_print_suppress[fmt] < RealTime() then
			ply.net_incoming_last_print_suppress[fmt] = RealTime() + 0.5

			fmt = fmt:Replace("PLAYER", ply:Nick() .. "( " .. ply:SteamID() .. " )")
			local str = fmt:format(...)
			MsgN("[net] " .. str)
		end
	end

	local function punish(ply, sec)
		ply.net_incoming_suppress = SysTime() + sec
		warn(ply, "dropping net messages from PLAYER for %f seconds", sec)
	end

	function net.Incoming(length, ply)
		do -- rate limit
			ply.net_incoming_rate_count = (ply.net_incoming_rate_count or 0) + 1
			ply.net_incoming_rate_next_check = ply.net_incoming_rate_next_check or 0

			if ply.net_incoming_rate_next_check < RealTime() then
				if ply.net_incoming_rate_count > 100 then
					warn(ply, "PLAYER is sending more than 100 net messages a second", ply)
					punish(ply, 2)
				end

				ply.net_incoming_rate_count = 0
				ply.net_incoming_rate_next_check = RealTime() + 1
			end
		end

		if ply.net_incoming_suppress and ply.net_incoming_suppress > SysTime() then
			return
		end

		do -- gmod's net.Incoming
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
						punish(ply, 1)
					end
				end
			end
		end
	end
end