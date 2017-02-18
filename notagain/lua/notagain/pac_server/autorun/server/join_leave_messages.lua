local tag = "player_info"
pcall(require,"geoip")

local function JoinMessage(name,steamid)
	for _,v in next,player.GetAll() do 
		v:SendLua([[chat.AddText(Color(255,255,255),"]] .. name .. [[ (]] .. steamid .. [[) is ",Color(0,255,0),"connecting",Color(255,255,255)," to the server!")]])
	end
end

local function LeaveMessage(name,steamid,reason)
	for _,v in next,player.GetAll() do 
		v:SendLua([[chat.AddText(Color(255,255,255),"]] .. name .. [[ (]] .. steamid .. [[) has ",Color(255,0,0),"disconnected",Color(255,255,255)," from the server! (]] .. reason .. [[)")]]) 
	end
end


gameevent.Listen("player_connect")
hook.Add("player_connect",tag,function(data)
	local name = data.name
	local ip = data.address
	local steamid = data.networkid
	local geoip = GeoIP.Get(ip:Split(":")[1])
	local geoipinfo = {geoip.country_name,geoip.city,geoip.asn}
	
	MsgC(Color(0,255,0),"[Join] ") print(name.." ("..steamid..") is connecting to the server! ["..ip..(table.Count(geoipinfo) ~= 0 and " | "..table.concat(geoipinfo,", ").."]" or "]"))

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