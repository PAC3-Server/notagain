local tag = "player_info"

if SERVER then

	util.AddNetworkString(tag)

	local geoip
	pcall(function() geoip = requirex("geoip") end)

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
	end)

	gameevent.Listen("player_disconnect")
	hook.Add("player_disconnect",tag,function(data)
		local name = data.name
		local steamid = data.networkid
		local reason = data.reason
	end)

	hook.Add("Initialize",tag,function()
		function GAMEMODE:PlayerConnect() end
		function GAMEMODE:PlayerDisconnected() end
	end)

end
