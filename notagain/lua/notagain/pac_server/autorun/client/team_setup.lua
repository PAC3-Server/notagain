local players = 1
local friends = 1

team.SetUp(players, "players", Color(255, 70, 0, 255))
team.SetUp(friends, "friends", Color(60, 127, 255, 255))

FindMetaTable("Player")._Team = FindMetaTable("Player")._Team or FindMetaTable("Player").Team

FindMetaTable("Player").Team = function(self)
	if not self:IsValid() or not LocalPlayer():IsValid() then return self:_Team() end

	if self:GetFriendStatus() == "friend" or self == LocalPlayer() then
		return friends
	end

	return players
	
end
