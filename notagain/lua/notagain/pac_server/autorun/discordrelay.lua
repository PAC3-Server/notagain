if SERVER then
	util.AddNetworkString("DiscordMessage")

	discordrelay = discordrelay or {} 
	discordrelay.token = file.Read( "discordbot_token.txt", "DATA" )
	discordrelay.relayChannel = "273575417401573377"
	
	discordrelay.endpoints = discordrelay.endpoints or {}
	discordrelay.endpoints.base = "https://discordapp.com/api/v6"
	discordrelay.endpoints.users = discordrelay.endpoints.base.."/users"
	discordrelay.endpoints.guilds = discordrelay.endpoints.base.."/guilds"
	discordrelay.endpoints.channels = discordrelay.endpoints.base.."/channels"

	discordrelay.enabled = true

	discordrelay.user = {}
	discordrelay.user.username = "GMod-Relay"
	discordrelay.user.id = "276379732726251521"

	function discordrelay.HTTPRequest(ctx, callback)
		local HTTPRequest = {}
		HTTPRequest.method = ctx.method
		HTTPRequest.url = ctx.url
		HTTPRequest.headers = {
			["Authorization"]="Bot "..discordrelay.token,
			["Content-Type"] = "application/json",
			["User-Agent"] = "GModRelay (https://datamats.com/, 1.0.0)"
		}
		
		HTTPRequest.type = "application/json"

		if ctx.body then
			HTTPRequest.body = ctx.body
		elseif ctx.parameters then
			HTTPRequest.parameters = ctx.parameters
		end

		HTTPRequest.success = function(code, body, headers)
			callback(headers, body)
		end

		HTTPRequest.failed = function(reason)
		end

		HTTP(HTTPRequest)
	end

	function discordrelay.CreateMessage(channelid, msg, cb)
		local res
		if type(msg) == "string" then
			res = util.TableToJSON({["content"] = msg})
		elseif type(msg) == "table" then
			res = util.TableToJSON(msg)
		else
			return print("Relay: attempting to send a invalid message")
		end
		discordrelay.HTTPRequest({
			["method"] = "post",
			["url"] = discordrelay.endpoints.channels.."/"..channelid.."/messages",
			["body"] = res
		}, function(headers, body)
			if not cb then return end
			local tbl = util.JSONToTable(body)
			cb(tbl)
		end)
	end

	function discordrelay.init()
		discordrelay.user = {}
		discordrelay.authed = false
	   	discordrelay.HTTPRequest({["method"] = "get", ["url"] = discordrelay.endpoints.users.."/@me"}, function(headers, body)
	   		local json = util.JSONToTable(body)
	   		if json and json.username then
	   			discordrelay.user.username = json.username
	   			discordrelay.user.id = json.id
	   			discordrelay.authed = true
	   			print("Discord Relay: Is authed!")
	   		else
	   			print("Sure that is a valid token?")
	   		end
	   	end)
	end

	local after = 0
	--It was either this or websockets. But this shouldt be that bad of a solution
	timer.Create("DiscordRelayFetchMessages", 1.5, 0, function()
		local url
		if after ~= 0 then
			url = discordrelay.endpoints.channels.."/"..discordrelay.relayChannel.."/messages?after="..after
		else
			url = discordrelay.endpoints.channels.."/"..discordrelay.relayChannel.."/messages"
		end

		discordrelay.HTTPRequest({["method"] = "get", ["url"] = url}, function(headers, body)
			local json = util.JSONToTable(body)

			if after ~= 0 then
				for k,v in pairs(json) do
					if discordrelay.user.id == v.author.id then continue end

					if string.StartWith(v.content, "<@"..discordrelay.user.id.."> status") or string.StartWith(v.content, ".status") then
						local onlineplys = ""
						for k,v in pairs(player.GetAll()) do
							if k == table.Count(player.GetAll()) then
								onlineplys = onlineplys..v:Nick()
							else
								onlineplys = onlineplys..v:Nick()..", "
							end
						end
						discordrelay.CreateMessage(discordrelay.relayChannel, {
							["embed"] = {
								["title"] = "Server status:",
								["description"] = "**Hostname:** "..GetHostName().."\n**Map:** "..game.GetMap().."\n**Players online:** "..table.Count(player.GetAll()).."/"..game.MaxPlayers().."\n```"..onlineplys.." ```",
								["type"] = "rich",
								["color"] = 0x051690
							}
						})
					else
						net.Start( "DiscordMessage" )
							net.WriteString(string.sub(v.author.username,1,14))
							net.WriteString(string.sub(v.content,1,400))
						net.Broadcast()
					end

				end
			end

			if json and json[1] then
				after = json[1].id
			end
		end)
	end)

	hook.Add("PlayerSay", "DiscordRelayChat", function(ply, text, teamChat)
	    if discordrelay and discordrelay.enabled then
	        discordrelay.CreateMessage(discordrelay.relayChannel, "`"..ply:Nick()..": "..text.."`")
	    end
	end)

	hook.Add("PlayerConnect", "DiscordRelayPlayerConnect", function(name)
	    if discordrelay and discordrelay.enabled then
	        discordrelay.CreateMessage(discordrelay.relayChannel, "`"..name.." is joining the server!`")
	    end
	end)


	gameevent.Listen( "player_disconnect" )
	hook.Add("player_disconnect", "DiscordRelayPlayerDisconnect", function(data)
	    if discordrelay and discordrelay.enabled then
	       	discordrelay.CreateMessage(discordrelay.relayChannel, "`"..data.name.." has disconnected from the server! ("..data.reason..")`")
	    end
	end)

	hook.Add("ShutDown", "DiscordRelayShutDown", function()
		if discordrelay and discordrelay.enabled then
			discordrelay.CreateMessage(discordrelay.relayChannel, "`The server is shutting down!`")
		end
	end)
else
	net.Receive( "DiscordMessage", function()
		local nick = net.ReadString()
		local message = net.ReadString()

		chat.AddText(Color(114,137,218),nick,Color(255,255,255,255),": ",message);
	end)
end