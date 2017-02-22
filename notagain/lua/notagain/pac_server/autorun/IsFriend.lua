local Tag = "FriendSystem"

if SERVER then
	local META = FindMetaTable("Player")

	util.AddNetworkString(Tag)

	function META:AddFriend(ply)
		if IsValid(ply) and ply:IsPlayer() then
			self.Friends = self.Friends or {}
			self.Friends[ply] = ply
		end
	end

	function META:RemoveFriend(ply)
		if IsValid(ply) and ply:IsPlayer() and self.Friends then
			self.Friends[ply] = nil
		end
	end

	function META:IsFriend(ply)
		return self.Friends and self.Friends[ply] ~= nil
	end

	net.Receive(Tag , function(len , ply)
		if not ply:IsValid() then return end

		local friend = net.ReadEntity()
		if friend:IsValid() then
			friend:AddFriend(ply)
			ply:AddFriend(friend)
		end
	end)

	hook.Add("PlayerDisconnected" , Tag, function(friend)
		for _ , ply in ipairs(player.GetAll()) do
			ply:RemoveFriend(friend)
		end
	end)
end

if CLIENT then
	hook.Add("OnEntityCreated", Tag, function(ply)
		-- might be too early if the player has just spawned?
		timer.Simple(1, function()
			if not ply:IsValid() or not ply:IsPlayer() then return end

			if ply:GetFriendStatus() == "friend" then
				net.Start(Tag)
				net.WriteEntity(ply)
				net.SendToServer()
			end
		end)
	end)
end
