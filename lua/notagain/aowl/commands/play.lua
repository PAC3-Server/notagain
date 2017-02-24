AddCSLuaFile()

if SERVER then
	API_YT_SEARCH_URL = "https://www.googleapis.com/youtube/v3/search?key=%s&part=id&type=video&q=%s"
	API_YT_KEY = file.Read("translation_key.txt")

	function RequestYTSearch( q, c )
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

	aowl.AddCommand( {"ytplay"}, function( player, line, q )
		if ( string.find( q, "https?://[%w-_%.%?%.:/%+=&]+" ) ) then
			net.Start( "s2c_mpyt" )
			net.WriteBool( true )
			net.WriteString( q ) 
			net.Send( player )
		else
			RequestYTSearch( q, function( data )
				if data then
					net.Start( "s2c_mpyt" )
					net.WriteBool( false )
					net.WriteString( data ) 
					net.Send( player )
				end
			end )
		end
	end)
else
	net.Receive( "s2c_mpyt", function()
		local isUrl = net.ReadBool()
		local data = net.ReadString()
		local ent = LocalPlayer():GetEyeTrace().Entity
		
		if ent.IsMediaPlayerEntity then
			local q = (isUrl) and data or string.format( "https://www.youtube.com/watch?v=%s", data ) 
			MediaPlayer.Request( ent, q )
		end
	end )
end