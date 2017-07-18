local goluwa = requirex("goluwa")

local autocomplete = goluwa.autocomplete
local chatsounds = goluwa.chatsounds

local hooks = {}
local function hookAdd(event, id, callback)
	hooks[event] = hooks[event] or {}
	hooks[event][id] = callback
	hook.Add(event, id, callback)
end

local function unhook()
	for event, data in next, hooks do
		for id, callback in next, data do
			hook.Remove(event, id)
		end
	end
end

local function rehook()
	for event, data in next, hooks do
		for id, callback in next, data do
			hook.Add(event, id, callback)
		end
	end
end

local chatsounds_enabled = CreateClientConVar("chatsounds_enabled", "1", true, false, "Disable chatsounds")

cvars.AddChangeCallback("chatsounds_enabled", function(convar_name, value_old, value_new)
	if value_new ~= '0' then
		rehook()
	else
		unhook()
	end
end)

do
	local found_autocomplete
	local random_mode = false

	local function query(str, scroll)
		found_autocomplete = autocomplete.Query("chatsounds", str, scroll)
	end

	hookAdd("OnChatTab", "chatsounds_autocomplete", function(str)
		if str == "random" or random_mode then
			random_mode = true
			query("", 0)
			return found_autocomplete[1]
		end

		query(str, (input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) or input.IsKeyDown(KEY_LCONTROL)) and -1 or 1)

		if found_autocomplete[1] then
			return found_autocomplete[1]
		end
	end)

	hookAdd("ChatTextChanged", "chatsounds_autocomplete", function(str)
		random_mode = false
		query(str, 0)
	end)

	hookAdd("StartChat", "chatsounds_autocomplete", function()
		hookAdd("PostRenderVGUI", "chatsounds_autocomplete", function()
			if found_autocomplete and #found_autocomplete > 0 then
				local x, y = chat.GetChatBoxPos()
				local w, h = chat.GetChatBoxSize()
				autocomplete.DrawFound("chatsounds", x, y + h, found_autocomplete)
			end
		end)
	end)

	hookAdd("FinishChat", "chatsounds_autocomplete", function()
		hook.Remove("PostRenderVGUI", "chatsounds_autocomplete")
	end)
end

local init = false
hookAdd("OnPlayerChat", "chatsounds", function(ply, str)
	if not init then
		for i, info in ipairs(engine.GetGames()) do
			if info.mounted then
				if not file.Exists("goluwa/data/chatsounds/lists/" .. info.depot .. ".dat", "DATA") and not file.Exists("goluwa/data/chatsounds/trees/" .. info.depot .. ".txt", "DATA") then
					print("downloading chatsounds list for " .. info.title)
					local found_list = false

					http.Fetch("https://raw.githubusercontent.com/PAC3-Server/chatsounds/master/lists/"..info.depot..".txt", function(data, _,_, code)
						if code == 200 then
							file.CreateDir("goluwa/data/chatsounds/lists")
							file.Write("goluwa/data/chatsounds/lists/" .. info.depot .. ".dat", data)
							found_list = true
						else
							print("could not download chatsounds list for " .. info.title .. ": " .. code)
							timer.Destroy("chatsounds_download_list_" .. info.depot)
						end
					end, function(err)
						print("could not download chatsounds list for " .. info.title .. ": " .. err)
						timer.Destroy("chatsounds_download_list_" .. info.depot)
					end)

					local found_tree = false

					http.Fetch("https://raw.githubusercontent.com/PAC3-Server/chatsounds/master/trees/"..info.depot..".txt", function(data, _,_, code)
						if code == 200 then
							file.CreateDir("goluwa/data/chatsounds/trees")
							file.Write("goluwa/data/chatsounds/trees/" .. info.depot .. ".dat", data)
							found_tree = true
						else
							print("could not download chatsounds tree for " .. info.title .. ": " .. code)
							timer.Destroy("chatsounds_download_list_" .. info.depot)
						end
					end, function(err)
						print("could not download chatsounds tree for " .. info.title .. ": " .. err)
						timer.Destroy("chatsounds_download_list_" .. info.depot)
					end)

					timer.Create("chatsounds_download_list_" .. info.depot, 1, 50, function()
						if found_tree and found_list then
							print("loading chatsounds data for " .. info.title)
							chatsounds.LoadData(tostring(info.depot))
							timer.Destroy("chatsounds_download_list_" .. info.depot)
						end
					end)
				else
					print("loading chatsounds data for " .. info.title)
					chatsounds.LoadData(tostring(info.depot))
				end
			end
		end

		chatsounds.Initialize()
		chatsounds.BuildFromGithub("https://api.github.com/repos/Metastruct/garrysmod-chatsounds/git/trees/master?recursive=1")

		init = true
	end

	goluwa.audio.player_object = ply
	chatsounds.Say(str, math.Round(CurTime()))
end)

if not chatsounds_enabled:GetBool() then
	timer.Simple(0.05, function()
		unhook()
	end)
end
