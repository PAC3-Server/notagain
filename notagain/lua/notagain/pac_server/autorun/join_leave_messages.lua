

local tag = "player_info"

if SERVER then

	util.AddNetworkString(tag)

	local geoip = requirex("geoip")

	local function JoinMessage(name,steamid)
		local info = {}
		info.name = name
		info.steamid = steamid
		net.Start(tag)
			net.WriteTable(info)
		net.Broadcast()
	end

	local function LeaveMessage(name,steamid,reason)
		local info = {}
		info.name = name
		info.steamid = steamid
		info.reason = reason
		net.Start(tag)
			net.WriteTable(info)
		net.Broadcast()
	end


	gameevent.Listen("player_connect")
	hook.Add("player_connect",tag,function(data)
		local name = data.name
		local ip = data.address
		local steamid = data.networkid
		local geoipres = geoip.Get(ip:Split(":")[1])
		local geoipinfo = {geoipres.country_name,geoipres.city,geoipres.asn}

		MsgC(Color(0,255,0),"[Join] ") print(name.." ("..steamid..") is connecting to the server! ["..ip..(steamid ~= "BOT" and table.Count(geoipinfo) ~= 0 and " | "..table.concat(geoipinfo,", ").."]" or "]"))

		JoinMessage(name,steamid)

	end)

	gameevent.Listen("player_disconnect")
	hook.Add("player_disconnect",tag,function(data)
		local name = data.name
		local steamid = data.networkid
		local reason = data.reason

		LeaveMessage(name,steamid,reason)
		
	end)

	function GAMEMODE:PlayerConnect() end
	function GAMEMODE:PlayerDisconnected() end

end

if CLIENT then

	net.Receive(tag,function()
		local info = net.ReadTable()

		if not info.reason then

			chat.AddText(Color(255,255,255),info.name .. " (" .. info.steamid .. ") is ", Color(0,255,0), "connecting", Color(255,255,255), " to the server!")

		else

			chat.AddText(Color(255,255,255),info.name .. " (" .. info.steamid .. ") has ", Color(255,0,0), "disconnected", Color(255,255,255), " from the server! (" .. info.reason .. ")")

		end

	end)

	hook.Add("ChatText",tag,function(some,very,special,shit)
		if shit == "joinleave" then 
			return true
		end
	end)


end


