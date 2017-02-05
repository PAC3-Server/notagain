if SERVER then
	util.AddNetworkString("DiscordMessage")

	discordrelay = discordrelay or {} 
	discordrelay.token = file.Read( "discordbot_token.txt", "DATA" )
	discordrelay.relayChannel = "273575417401573377"
    discordrelay.webhookid = "274957435091812352"
    discordrelay.webhooktoken = file.Read( "webhook_token.txt", "DATA" )
	
	discordrelay.endpoints = discordrelay.endpoints or {}
	discordrelay.endpoints.base = "https://discordapp.com/api/v6"
	discordrelay.endpoints.users = discordrelay.endpoints.base.."/users"
	discordrelay.endpoints.guilds = discordrelay.endpoints.base.."/guilds"
	discordrelay.endpoints.channels = discordrelay.endpoints.base.."/channels"
    discordrelay.endpoints.webhook = "https://canary.discordapp.com/api/webhooks"

	discordrelay.enabled = true

	discordrelay.user = {}
	discordrelay.user.username = "GMod-Relay"
	discordrelay.user.id = "276379732726251521"

	function discordrelay.HTTPRequest(ctx, callback, err)
		local HTTPRequest = {}
		HTTPRequest.method = ctx.method
		HTTPRequest.url = ctx.url
		HTTPRequest.headers = {
			["Authorization"]= "Bot "..discordrelay.token,
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
        if not callback then return end
			callback(headers, body)
		end

		HTTPRequest.failed = function(reason)
        if not err then return end
            err(reason)
		end

		HTTP(HTTPRequest)
	end

    function discordrelay.WebhookRequest(ctx, callback, err)
        local HTTPRequest = {}
        HTTPRequest.method = ctx.method
		HTTPRequest.url = ctx.url
        HTTPRequest.headers = {
			["Content-Type"] = "application/json",
            ["Content-Length"] = string.len(ctx.body) or "0"
		}

        HTTPRequest.type = "application/json"

		if ctx.body then
			HTTPRequest.body = ctx.body
		elseif ctx.parameters then
			HTTPRequest.parameters = ctx.parameters
		end

		HTTPRequest.success = function(code, body, headers)
        if not callback then return end
			callback(headers, body)
		end

		HTTPRequest.failed = function(reason)
        if not err then return end
            err(reason)
		end

		HTTP(HTTPRequest)
    end
	function discordrelay.GetAvatar(steamid, callback)
		local commid = util.SteamIDTo64(steamid)
		http.Fetch("http://steamcommunity.com/profiles/" .. commid .. "?xml=1", function(content, size)
			local ret = content:match("<avatarFull><!%[CDATA%[(.-)%]%]></avatarFull>")
			callback(ret)
		end)
	end

	function discordrelay.CreateMessage(channelid, msg, cb) -- still keeping this if we want to post anything in the future, feel free to remove though
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

    function discordrelay.ExecuteWebhook(whid, whtoken, msg, cb)
        local res
        if type(msg) == "string" then
			res = util.TableToJSON({["content"] = msg})
		elseif type(msg) == "table" then
			res = util.TableToJSON(msg)
		else
			return print("Relay: attempting to send a invalid message")
		end
        discordrelay.WebhookRequest({
            ["method"] = "POST",
            ["url"] = discordrelay.endpoints.webhook.."/"..whid.."/"..whtoken,
            ["body"] = res
            
        }, function(headers, body)
        if not cb then return end
			local tbl = util.JSONToTable(body)
			cb(tbl)
		end,function(err) print(err) end)
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
	--It was either this or websockets. But this shouldn't be that bad of a solution
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
					if discordrelay.user.id == v.author.id or v.author.bot == true then continue end

					if string.StartWith(v.content, "<@"..discordrelay.user.id.."> status") or string.StartWith(v.content, ".status") then
						local onlineplys = ""
						local players = player.GetAll()
						for k,v in pairs(players) do
							if k == #players then
								onlineplys = onlineplys..v:Nick()
							else
								onlineplys = onlineplys..v:Nick()..", "
							end
						end
						if #players > 0 then
							discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
								["username"] = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server",
								["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
								["embeds"] = {
									[1] = {
										["title"] = "Server status:",
										["description"] = "**Hostname:** "..GetHostName().."\n**Map:** "..game.GetMap().."\n**Players online:** "..table.Count(player.GetAll()).."/"..game.MaxPlayers().."\n```"..onlineplys.." ```",
										["author"] = {
											["name"] = data.name,
											["icon_url"] = ret
										},
										["type"] = "rich",
										["color"] = 0x0040ff
									}
								}
							})
						else
						discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
							["username"] = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server",
							["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
							["embeds"] = {
								[1] = {
									["title"] = "Server status:",
									["description"] = "No Players are currently on the Server...",
									["type"] = "rich",
									["color"] = 0x5a5a5a
								}
							}
						})
						end
						
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
            discordrelay.GetAvatar(ply:SteamID(), function(ret)
            	discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
					["username"] = ply:Nick(),
					["content"] = text,
					["avatar_url"] = ret
					}) 
			end)
	    end
	end)
    gameevent.Listen( "player_connect" )
	hook.Add("player_connect", "DiscordRelayPlayerConnect", function(data)
	    if discordrelay and discordrelay.enabled then
            discordrelay.GetAvatar(data.networkid, function(ret)
				discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
					["username"] = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server",
					["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
					["embeds"] = {
						[1] = {
							["title"] = "",
							["description"] = "is joining the Server.",
							["author"] = {
								["name"] = data.name,
								["icon_url"] = ret
							},
							["type"] = "rich",
							["color"] = 0x00b300
						}
                	}
				})
            end)
	    end
	end)


	gameevent.Listen( "player_disconnect" )
	hook.Add("player_disconnect", "DiscordRelayPlayerDisconnect", function(data)
	    if discordrelay and discordrelay.enabled then
        	discordrelay.GetAvatar(data.networkid, function(ret)
				discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
					["username"] = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server",
					["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
					["embeds"] = {
						[1] = {
							["title"] = "",
							["description"] = "left the Server.",
							["author"] = {
								["name"] = data.name,
								["icon_url"] = ret
							},
							["type"] = "rich",
							["color"] = 0xb30000
						}
                	}
				})
			end)
		end
	end)

	hook.Add("ShutDown", "DiscordRelayShutDown", function()
		if discordrelay and discordrelay.enabled then
			discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
				["username"] = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server",
				["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
				["embeds"] = {
					[1] = {
						["title"] = "",
						["description"] = ":warning: has shutdown. :warning:",
						["type"] = "rich",
						["color"] = 0xb30000
					}
				}
			})
		end
	end)
else
	net.Receive( "DiscordMessage", function()
		local nick = net.ReadString()
		local message = net.ReadString()

		chat.AddText(Color(114,137,218),nick,Color(255,255,255,255),": ",message);
	end)
end
