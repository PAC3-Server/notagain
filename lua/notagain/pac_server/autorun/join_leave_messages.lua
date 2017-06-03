local tag = "player_info"

if SERVER then

	util.AddNetworkString(tag)

	local geoip
	pcall(function() geoip = requirex("geoip") end)

	local function JoinMessage(name, steamid)
		local info = {}
		info.name = name
		info.steamid = steamid
		net.Start(tag)
			net.WriteTable(info)
		net.Broadcast()
	end

	local function LeaveMessage(name, steamid, reason)
		local info = {}
		info.name = name
		info.steamid = steamid
		info.reason = reason
		net.Start(tag)
			net.WriteTable(info)
		net.Broadcast()
	end


	gameevent.Listen("player_connect")
	hook.Add("player_connect", tag, function(data)
		local name = data.name
		local ip = data.address
		local steamid = data.networkid
		if geoip then 
			local geoipres = geoip.Get(ip:Split(":")[1])
			local geoipinfo = {geoipres.country_name, geoipres.city, geoipres.asn}

			MsgC(Color(0,255,0),"[Join] ") print(name.." ("..steamid..") is connecting to the server! ["..ip..(steamid ~= "BOT" and table.Count(geoipinfo) ~= 0 and " | "..table.concat(geoipinfo,", ").."]" or "]"))
		else
			MsgC(Color(0,255,0),"[Join] ") print(name.." ("..steamid..") is connecting to the server! ["..ip.."]")
		end			
				
		JoinMessage(name,steamid)
	end)

	gameevent.Listen("player_disconnect")
	hook.Add("player_disconnect",tag,function(data)
		local name = data.name
		local steamid = data.networkid
		local reason = data.reason

		LeaveMessage(name,steamid,reason)
	end)

	hook.Add("Initialize",tag,function()
		function GAMEMODE:PlayerConnect() end
		function GAMEMODE:PlayerDisconnected() end
	end)

end

if CLIENT then

	net.Receive(tag,function()
		local info = net.ReadTable()
		if not info.reason then
			chat.AddText(Color(20, 230, 20), "▶ ", Color(255,255,255),info.name,Color(220,220,220)," (" .. info.steamid .. ") is ", Color(20, 255, 20), "connecting", Color(220,220,220), " to the server!")
		else
			chat.AddText(Color(230, 20, 20), "▶ ", Color(255,255,255),info.name,Color(220,220,220)," (" .. info.steamid .. ") has ", Color(255, 20, 20), "disconnected", Color(220,220,220), " from the server! (" .. info.reason .. ")")
		end
	end)

	hook.Add("ChatText",tag,function(_,_,_,mode)
		if mode == "joinleave" then 
			return true
		end
	end)
	
end
