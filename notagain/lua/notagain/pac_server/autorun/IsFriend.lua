local Tag = "FriendSystem"

if SERVER then
	AddCSLuaFile()
	local META = FindMetaTable( "Player" )
	
	util.AddNetworkString( Tag )

	function META:AddFriend( ply )

		if IsValid( ply ) and ply:IsPlayer() then
			self.Friends = self.Friends or {}
			table.insert( self.Friends , ply:EntIndex() , ply )
		end

	end

	function META:RemoveFriend( ply )

		if IsValid( ply ) and ply:IsPlayer() and self.Friends then
			table.remove( self.Friends ,ply:EntIndex() )
		end

	end

	net.Receive( Tag , function( len , ply )
		local NWFriends = net.ReadTable()
		
		for _ , v in pairs( NWFriends ) do
			v:AddFriend( ply )
			ply:AddFriend( v )
		end 

	end )

	hook.Add( "PlayerDisconnected" , Tag , function( ply )

		for _ , v in pairs( player.GetAll() ) do
			v:RemoveFriend( ply )
		end

	end )

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
	
	for _ , v in pairs( player.GetAll() ) do
		if v:GetFriendStatus() == "friend" then
			table.insert( Friends , v:EntIndex() , v )
		end
	end

	net.Start( Tag )
	net.WriteTable( Friends )
	net.SendToServer()



end
