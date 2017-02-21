local Tag = "FriendSystem"

if SERVER then

	local META = FindMetaTable( "Player" )
	
	util.AddNetworkString( Tag.." Start" )
	util.AddNetworkString( Tag )

	hook.Add( "PlayerInitialSpawn" , Tag.." InitTable" , function( ply )
		
		ply.Friends = {}
	
	end)

	hook.Add( "PlayerDisconnected" , Tag.." InValidEntRemoval" , function( ply )

		for _ , v in pairs( player.GetAll() ) do
			v:RemoveFriend( ply )
		end

	end )

	function META:AddFriend( ply )

		if IsValid( ply ) and ply:IsPlayer() and self.Friends then
			table.insert( self.Friends , ply:EntIndex() , ply )
		end

	end

	function META:RemoveFriend( ply )

		if IsValid( ply ) and ply:IsPlayer() and self.Friends then
			table.remove( self.Friends ,ply:EntIndex() )
		end

	end

	net.Receive( "StoreFriends" , function( len , ply )
		local NWFriends = net.ReadTable()
		
		for _ , v in pairs( NWFriends ) do
			v:AddFriend( ply )
			ply:AddFriend( v )
		end 

	end)

	function META:IsFriend( ply ) 

		if IsValid( ply ) and ply:IsPlayer() then

			for k,v in pairs( self.Friends ) do
				if v == ply then
					return true
				end
			end

			return false

		end

	end

end


if CLIENT then

	local Friends = Friends or {}
	
	net.Receive( Tag.." Start" , function()
		
		for _ , v in pairs( player.GetAll() ) do
			if v:GetFriendStatus() == "friend" then
				table.insert( Friends , v:EntIndex() , v )
			end
		end

		net.Start( Tag )
		net.WriteTable( Friends )
		net.SendToServer()
	
	end)


end
