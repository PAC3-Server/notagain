if game.SinglePlayer() then return end

if SERVER then
	local tag = "player_info"

	local function playerJoin(state, ...)
 		if state then
 			MsgC(Color(0, 255, 0), "[Join] ") print(...)
 		else
 			MsgC(Color(255, 0, 0), "[Leave] ") print(...)
 		end
 	end

 	util.AddNetworkString(tag)

	gameevent.Listen("player_connect")
	hook.Add("player_connect", tag, function(data)
		local name 		= data.name
		local ip 		= data.address
		local steamid 	= data.networkid

		playerJoin(true, name .. " (" .. steamid .. ") is connecting to the server! [" .. ip .. "]")

	end)

	gameevent.Listen("player_disconnect")
	hook.Add("player_disconnect", tag, function(data)
		local name 		= data.name
		local steamid 	= data.networkid
		local reason 	= data.reason

		playerJoin(false, name .. " (" .. steamid .. ") has left the server! (" .. reason .. ")")
	end)

	hook.Add("Initialize", tag, function()
		hook.Remove("Initialize", tag)
		function GAMEMODE:PlayerConnect() end
		function GAMEMODE:PlayerDisconnected() end
	end)

end
