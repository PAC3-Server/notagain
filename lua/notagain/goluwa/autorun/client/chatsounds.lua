local goluwa = requirex("goluwa")

local autocomplete = goluwa.autocomplete
local chatsounds = goluwa.chatsounds

do
	local found_autocomplete

	local function query(str, scroll)
		found_autocomplete = autocomplete.Query("chatsounds", str, scroll)
	end

	hook.Add("OnChatTab", "chatsounds_autocomplete", function(str)
		query(str, (input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) or input.IsKeyDown(KEY_LCONTROL)) and -1 or 1)

		if found_autocomplete[1] then
			return found_autocomplete[1]
		end
	end)

	hook.Add("ChatTextChanged", "chatsounds_autocomplete", function(str)
		query(str, 0)
	end)

	hook.Add("StartChat", "chatsounds_autocomplete", function()
		hook.Add("PostRenderVGUI", "chatsounds_autocomplete", function()
			if found_autocomplete and #found_autocomplete > 0 then
				local x, y = chat.GetChatBoxPos()
				local w, h = chat.GetChatBoxSize()
				autocomplete.DrawFound(x, y + h, found_autocomplete, nil, 2)
			end
		end)
	end)

	hook.Add("FinishChat", "chatsounds_autocomplete", function()
		hook.Remove("PostRenderVGUI", "chatsounds_autocomplete")
	end)
end

local init = false
hook.Add("OnPlayerChat", "chatsounds", function(ply, str)
	if not init then
		for i, info in ipairs(engine.GetGames()) do
			if info.mounted then
				if not file.Exists("goluwa/chatsounds/lists/" .. info.depot .. ".txt", "DATA") and not file.Exists("goluwa/chatsounds/trees/" .. info.depot .. ".txt", "DATA") then
					print("downloading chatsounds list for " .. info.title)
					local found_list = false

					http.Fetch("https://raw.githubusercontent.com/PAC3-Server/chatsounds/master/lists/"..info.depot..".txt", function(data, _,_, code)
						if code == 200 then
							file.CreateDir("goluwa/chatsounds/lists")
							file.Write("goluwa/chatsounds/lists/" .. info.depot .. ".txt", data)
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
							file.CreateDir("goluwa/chatsounds/trees")
							file.Write("goluwa/chatsounds/trees/" .. info.depot .. ".txt", data)
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

