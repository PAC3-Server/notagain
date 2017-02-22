TEAM_PLAYERS = 1
TEAM_FRIENDS = 2

team.SetUp(TEAM_PLAYERS, "players", Color(255, 70, 0, 255))
team.SetUp(TEAM_FRIENDS, "friends", Color(60, 127, 255, 255))

local meta = FindMetaTable("Player")

meta._Team = meta._Team or meta.Team

function meta:Team(...)
	if self.IsFriend then
		return LocalPlayer():IsFriend(self) and TEAM_FRIENDS or TEAM_PLAYERS
	end

	return meta._Team(self, ...)
end
