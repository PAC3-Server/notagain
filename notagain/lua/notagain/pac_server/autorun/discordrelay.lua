if SERVER then
	local easylua = requirex('easylua')
	local luadev = requirex('luadev')

	local webhooktoken = file.Read( "webhook_token.txt", "DATA" )
	local token = file.Read( "discordbot_token.txt", "DATA" )

	if not token then
		print("discordbot_token.txt", " not found")
	end

	if not webhooktoken then
		print("webhook_token.txt", " not found")
	end

	if not token or not webhooktoken then return end

	util.AddNetworkString("DiscordMessage")

	discordrelay = discordrelay or {}
	discordrelay.token = token
	discordrelay.guild = "260866188962168832"
	discordrelay.admin_roles = {"260870255486697472", "260932947140411412"}
	discordrelay.relayChannel = "273575417401573377"
	discordrelay.logChannel = "280436597248229376"
    discordrelay.webhookid = "274957435091812352"
    discordrelay.webhooktoken = webhooktoken

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

	discordrelay.AvatarCache = discordrelay.AvatarCache or {}

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
		if discordrelay.AvatarCache[commid] then
			callback(discordrelay.AvatarCache[commid])
		else
			http.Fetch("http://steamcommunity.com/profiles/" .. commid .. "?xml=1", function(content, size)
				local ret = content:match("<avatarFull><!%[CDATA%[(.-)%]%]></avatarFull>") or "http://i.imgur.com/ovW4MBM.png"
				discordrelay.AvatarCache[commid] = ret
				callback(ret)
			end)
		end
	end

	function discordrelay.IsAdmin(userid, cb)
		discordrelay.HTTPRequest({
			["method"] = "get",
			["url"] = discordrelay.endpoints.guilds.."/"..discordrelay.guild.."/members/"..userid
		}, function(headers, body)
			local tbl = util.JSONToTable(body)
			if tbl.roles then
				for k,role in pairs(discordrelay.admin_roles) do
					for k,v in pairs(tbl.roles) do
						if role == v then
							return cb(true)
						end
					end
				end
			end
			cb(false)
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

    local prefixes = {".", "!"}

    local function startsWith(name, msg, param)
    	for k,v in pairs(prefixes) do
    		if string.StartWith(msg, v..name) then
    			return true
    		end
    	end
    	return false
    end

    local function getType(cmds, msg)
    	for k,v in pairs(prefixes) do
    		for k,cmd in pairs(cmds) do
    			if string.StartWith(msg, v..cmd.." ") then
    				return cmd
    			end
    		end
    	end
    	return false
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
					if not (v and v.author) and discordrelay.user.id == v.author.id then continue end

					if v.author.bot and v.webhook_id then
						if string.lower(v.author.username) == "github" and v.embeds and v.embeds[1] then
							local embed = v.embeds[1]
							if string.match(embed.title, "new commit") then
								local message = "GitHub: "..embed.title
								for k,v in pairs(string.Split(embed.description, "\n")) do
									local hash, url, commit = string.match(v, "%[`(.*)`%]%((.*)%) (.*)")
									message = message.."\n	"..hash.." "..commit
								end
								net.Start( "DiscordMessage" )
									net.WriteString("")
									net.WriteString(message)
								net.Broadcast()
							else
								net.Start( "DiscordMessage" )
									net.WriteString("")
									net.WriteString("GitHub: "..embed.title)
								net.Broadcast()
							end
						end
					elseif v.author.bot ~= true and string.StartWith(v.content, "<@"..discordrelay.user.id.."> status") or startsWith("status", v.content) then
                        local embeds = {} -- maybe cache that too?
						local players = player.GetAll()
                        local cache = discordrelay.AvatarCache -- todo check if not nil
                        for i=1,#players do
                            local ply = players[i]
                            local commid = util.SteamIDTo64(ply:SteamID()) -- move to player meta?
                            embeds[i] = {
                                ["author"] = {
                                    ["name"] = ply:Nick(),["icon_url"] = cache[commid],
                                    ["url"] = "http://steamcommunity.com/profiles/" .. commid
                                },
                                ["color"] = 0x00b300 -- ply:isAFK() and 0xb30000 or 0x00b300, -- todo replace with afk color or something
                            }
                        end
						if #players > 0 then
							discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
								["username"] = "Server status:",
								["content"] = "**Hostname:** "..GetHostName().."\n**Map:** `"..game.GetMap().."`\n**Players:** "..#players.."/"..game.MaxPlayers(),
								["embeds"] = embeds
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
					elseif startsWith("l", v.content) or startsWith("print", v.content) or startsWith("table", v.content) then
						discordrelay.IsAdmin(v.author.id, function(access)
							if access then
								local cmd = getType({"l", "lc", "ls", "print", "table"}, v.content)
								local code = string.sub(v.content, #cmd + 2, #v.content)
								if code and code ~= "" then
									local data
									if cmd == "l" then
									 	data = easylua.RunLua(nil, code)
									elseif cmd == "lc" then
										data = luadev.RunOnClients(code)
									elseif cmd == "ls" then
										data = luadev.RunOnShared(code)
									elseif cmd == "print" then
									 	data = easylua.RunLua(nil, "return "..code)
									elseif cmd == "table" then
									 	data = easylua.RunLua(nil, "return table.ToString("..code..")")
									else
										return
									end

									if type(data) ~= "table" then
										local ok, returnvals = data
										if returnvals then
											discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
												["embeds"] = {
													[1] = {
													["description"] = returnvals,
														["type"] = "rich",
														["color"] = 0x182687
													}
												}
											})
										else
											discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
												["embeds"] = {
													[1] = {
													["description"] = ":ok_hand:",
														["type"] = "rich",
														["color"] = 0x182687
													}
												}
											})
										end
										return
									end

									if not data.error then
										local res = unpack(data.args)
										if res and cmd ~= "lc" then
											res = tostring(res)
										else
											res = ":ok_hand:"
										end
										discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
											["embeds"] = {
												[1] = {
												["description"] = res,
													["type"] = "rich",
													["color"] = 0x182687
												}
											}
										})
									else
										discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
											["embeds"] = {
												[1] = {
												["description"] = ":interrobang: **Error: **"..data.error,
													["type"] = "rich",
													["color"] = 0xb30000
												}
											}
										})
									end
								else
									discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
										["embeds"] = {
											[1] = {
												["description"] = ":interrobang: **Cannot run nothing!**",
												["type"] = "rich",
												["color"] = 0xb30000
											}
										}
									})
								end
							else
								discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
									["embeds"] = {
										[1] = {
											["description"] = ":no_entry: **Access denied!**",
											["type"] = "rich",
											["color"] = 0xb30000
										}
									}
								})
							end
						end)
						net.Start( "DiscordMessage" )
							net.WriteString(string.sub(v.author.username,1,14))
							net.WriteString(string.sub(v.content,1,400))
						net.Broadcast()


					elseif startsWith("rcon", v.content) then
						discordrelay.IsAdmin(v.author.id, function(access)
							if access then
								game.ConsoleCommand(string.sub(v.content, 6, #v.content).."\n")
								discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
									["embeds"] = {
										[1] = {
										["description"] = ":ok_hand:",
											["type"] = "rich",
											["color"] = 0x182687
										}
									}
								})

							else
								discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
									["embeds"] = {
										[1] = {
											["description"] = ":no_entry: **Access denied!**",
											["type"] = "rich",
											["color"] = 0xb30000
										}
									}
								})
							end
						end)
						net.Start( "DiscordMessage" )
							net.WriteString(string.sub(v.author.username,1,14))
							net.WriteString(string.sub(v.content,1,400))
						net.Broadcast()
					elseif v.author.bot ~= true then
						local ret = v.content
						if v.mentions then
							for k,mention in pairs(v.mentions) do
								ret = string.gsub(v.content, "<@!?"..mention.id..">", "@"..mention.username)
							end
						end
						if v.attachments then
							for _,attachments in pairs(v.attachments) do
								ret = ret .. "\n" .. attachments.url
							end
						end
						net.Start( "DiscordMessage" )
							net.WriteString(string.sub(v.author.username,1,14))
							net.WriteString(string.sub(ret,1,400))
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
			local commid = util.SteamIDTo64(data.networkid)
				discordrelay.ExecuteWebhook(discordrelay.webhookid, discordrelay.webhooktoken, {
					["username"] = GetConVar("sv_testing") and GetConVar("sv_testing"):GetBool() and "Test Server" or "Server",
					["avatar_url"] = "https://cdn.discordapp.com/avatars/276379732726251521/de38fcf57f85e75739a1510c3f9d0531.png",
					["embeds"] = {
						[1] = {
							["title"] = "",
							["description"] = "is joining the Server.",
							["author"] = {
								["name"] = data.name,
								["icon_url"] = ret,
								["url"] = "http://steamcommunity.com/profiles/" .. commid
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
			local commid = util.SteamIDTo64(data.networkid)
			local reason = (string.StartWith(data.reason ,"Map") or string.StartWith(data.reason ,data.name) or string.StartWith(data.reason ,"Client" )) and ":interrobang: "..data.reason or data.reason
        	
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
								["icon_url"] = ret,
								["url"] = "http://steamcommunity.com/profiles/" .. commid
							},
							["type"] = "rich",
							["color"] = 0xb30000,
							["fields"] = {
								[1] = {
									["name"] = "Reason:",
									["value"] = reason,
									["inline"] = false
								}
							}
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
						["description"] = "**Server has shutdown.**",
						["type"] = "rich",
						["color"] = 0xb30000
					}
				}
			})
		end
	end)

	local blacklist = {"suicided", "Bad SetLocalOrigin"}
	local logBuffer = ""
	hook.Add("EngineSpew", "DiscordRelaySpew", function(spewType, msg, group, level)
		for k,v in pairs(blacklist) do
			if string.match(msg, v) then
				return
			end
		end

		logBuffer = logBuffer..msg
	end )

	timer.Create("DiscordRelayAddLog", 1.5, 0, function()
		if logBuffer ~= "" then
			discordrelay.CreateMessage(discordrelay.logChannel, "```"..logBuffer.."```")
			logBuffer = ""
		end
	end)

else
	net.Receive( "DiscordMessage", function()
		local nick = net.ReadString()
		local message = net.ReadString()

		if ChathudImage then
			ChathudImage(message)
		end

		if nick ~= "" then
			chat.AddText(Color(114,137,218),nick,Color(255,255,255,255),": ",message)
		else
			chat.AddText(Color(255,255,255,255), message)
		end
	end)
end
