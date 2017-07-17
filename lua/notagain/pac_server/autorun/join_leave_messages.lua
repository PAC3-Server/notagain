if game.SinglePlayer() then return end

if SERVER then
	util.AddNetworkString("player_info")

	local geoip = requirex("geoip")

	gameevent.Listen("player_connect")
	hook.Add("player_connect", "player_info", function(data)
		local name = data.name
		local ip = data.address
		local steamid = data.networkid

		local geoipres = geoip.Get(ip:Split(":")[1])
		local geoipinfo = {geoipres.country_name, geoipres.city, geoipres.asn}

		MsgC(Color(0,255,0),"[Join] ") print(name.." ("..steamid..") is connecting to the server! ["..ip..(steamid ~= "BOT" and table.Count(geoipinfo) ~= 0 and " | "..table.concat(geoipinfo,", ").."]" or "]"))
		--MsgC(Color(0,255,0),"[Join] ") print(name.." ("..steamid..") is connecting to the server! ["..ip.."]")
	end)

	gameevent.Listen("player_disconnect")
	hook.Add("player_disconnect", "player_info", function(data)
		local name = data.name
		local steamid = data.networkid
		local reason = data.reason
		MsgC(Color(255,0,0),"[Leave] ") print(name.." ("..steamid..") has left the server! ("..reason..")")
	end)

	hook.Add("Initialize", "player_info", function()
		function GAMEMODE:PlayerConnect() end
		function GAMEMODE:PlayerDisconnected() end
	end)

end
