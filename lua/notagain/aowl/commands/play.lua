AddCSLuaFile()

if SERVER then
	API_YT_SEARCH_URL = "https://www.googleapis.com/youtube/v3/search?key=%s&part=id&type=video&q=%s"
	API_YT_KEY = file.Read("translation_key.txt")

	local function RequestYTSearch( q, c )
		local url = string.format( API_YT_SEARCH_URL, API_YT_KEY, q )
		url = string.Replace( url, " ", "%20" ) // Encoding Url

		http.Fetch(url,
			function( res )
				local tab = util.JSONToTable(res)

				if tab then
					local vid = tab.items[1].id.videoId

					if vid then
						c( vid )
					end
				end

				c( false )
			end,
			function( err )
				c( false )
			end
		)
	end

	util.AddNetworkString( "s2c_mpyt" )

	local urls = {
		"youtu%.be/([%w_%-]+)",
		"youtube%.com/watch%?v%=([%w_%-]+)"
	}

	local function getYoutubeID( url )
		for _, v in pairs( urls ) do
			for m in string.gmatch( url, v ) do
				return m
			end
		end

		return false
	end

	aowl.AddCommand("ytplay", function(ply, line, q)
		local id = getYoutubeID( q )

		if id then
			net.Start( "s2c_mpyt" )
			net.WriteString( id )
			net.Send( ply )
		else
			RequestYTSearch( q, function( data )
				if data then
					net.Start( "s2c_mpyt" )
					net.WriteString( data )
					net.Send( ply )
				end
			end )
		end
	end)
end

if CLIENT then
	net.Receive("s2c_mpyt", function()
		local data = net.ReadString()
		local ent = LocalPlayer():GetEyeTrace().Entity

		if ent.IsMediaPlayerEntity then
			local q = string.format( "https://www.youtube.com/watch?v=%s", data )
			MediaPlayer.Request( ent, q )
		end
	end)
end