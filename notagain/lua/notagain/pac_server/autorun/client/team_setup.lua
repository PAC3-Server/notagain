team.SetUp(1, "players", Color(255, 70, 0, 255))
team.SetUp(2, "friends", Color(60, 127, 255, 255))

FindMetaTable("Player").Team = function(self)
	if self:GetFriendStatus() == "friend" or self == LocalPlayer() then
		return 2
	end
	return 1
end