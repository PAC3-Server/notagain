local goluwa = requirex("goluwa")

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
							goluwa.chatsounds.LoadData(tostring(info.depot))
							timer.Destroy("chatsounds_download_list_" .. info.depot)
						end
					end)
				else
					print("loading chatsounds data for " .. info.title)
					goluwa.chatsounds.LoadData(tostring(info.depot))
				end
			end
		end

		goluwa.chatsounds.Initialize()
		goluwa.chatsounds.BuildFromGithub("https://api.github.com/repos/Metastruct/garrysmod-chatsounds/git/trees/master?recursive=1")

		init = true
	end

	goluwa.audio.player_object = ply
	goluwa.chatsounds.Say(str, math.Round(CurTime()))
end)