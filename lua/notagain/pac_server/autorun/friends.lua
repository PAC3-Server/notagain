friends = friends or {}

local is_friend_cache = setmetatable({}, {__mode = "kv"})

local META = FindMetaTable("Player")

function aowl.SetFriend(a, b, is_friend)
	if is_friend == true then
		is_friend = 1
	elseif is_friend == false then
		is_friend = 0
	else
		is_friend = -1
	end

	local uid = b:IsPlayer() and b:UniqueID() or b:EntIndex()

	a:SetNW2Int("friends_set_override_" .. uid, is_friend)

	if CPPI then
		hook.Run("CPPIFriendsChanged", ply, {b})
	end

	is_friend_cache[a] = nil
	is_friend_cache[b] = nil

	if SERVER then
		net.Start("friends_changed")
			net.WriteEntity(a)
			net.WriteEntity(b)
		net.Broadcast()
	end
end

do
	local function is_friend(a, b)
		local uid = b:IsPlayer() and b:UniqueID() or b:EntIndex()

		local num = a:GetNW2Int("friends_set_override_" .. uid, -1)

		if num == 1 then
			return true
		elseif num == 0 then
			return false
		end

		return a:GetNW2Bool("friends_set_" .. uid, false)
	end

	function aowl.GetFriend(a, b)
		if is_friend_cache[a] and is_friend_cache[a][b] ~= nil then return is_friend_cache[a][b] end

		is_friend_cache[a] = is_friend_cache[a] or {}
		is_friend_cache[a][b] = is_friend(a, b)
	end
end

function META:IsFriend(ply)
	if ply == self then return true end

	return aowl.GetFriend(self, ply)
end

function META:GetFriends()
	local out = {}
	for i, ply in ipairs(player.GetAll()) do
		if self:IsFriend(ply) then
			table.insert(out, ply)
		end
	end
	return out
end

if CLIENT then
	TEAM_PLAYERS = 1
	TEAM_FRIENDS = 2

	local b = 1.5

	timer.Simple(0.25, function()
		team.SetUp(TEAM_PLAYERS, "players", Color(150*b, 50*b, 50*b, 255))
		team.SetUp(TEAM_FRIENDS, "priends", Color(25*b, 100*b, 130*b, 255))
	end)

	META._Team = META._Team or META.Team

	function META:Team(...)
		if self.IsFriend then
			return LocalPlayer():IsFriend(self) and TEAM_FRIENDS or TEAM_PLAYERS
		end

		return META._Team(self, ...)
	end
end

if CPPI then
	META.CPPIGetFriends = META.GetFriends
end

if SERVER then
	util.AddNetworkString("friends")
	util.AddNetworkString("friends_changed")

	net.Receive("friends", function(len , ply)
		if not ply:IsValid() then return end

		local friend = net.ReadEntity()
		if friend:IsValid() then
			local status = net.ReadString()

			if status == "__add" then
				ply:SetNW2Bool("friends_set_" .. friend:UniqueID(), true)
			elseif status == "__remove" then
				ply:SetNW2Bool("friends_set_" .. friend:UniqueID(), false)
			end

			if status == "clear" then
				aowl.SetFriend(ply, friend, nil)
			elseif status == "add" then
				aowl.SetFriend(ply, friend, true)
			elseif status == "remove" then
				aowl.SetFriend(ply, friend, false)
			end

			net.Start("friends_changed")
				net.WriteEntity(ply)
				net.WriteEntity(friend)
			net.Broadcast()
		end
	end)
end

if CLIENT then
	net.Receive("friends_changed", function(len , ply)
		local a = net.ReadEntity()
		local b = net.ReadEntity()
		is_friend_cache[a] = nil
		is_friend_cache[b] = nil
	end)

	for _, ply in ipairs(player.GetAll()) do
		ply.friends_last_friend_status = nil
	end

	timer.Create("friends", 1, 0, function()
		for _, ply in ipairs(player.GetAll()) do
			local status = ply:GetFriendStatus()
			if ply.friends_last_friend_status ~= status then
				net.Start("friends")
					net.WriteEntity(ply)
					if status == "friend" or status == "requested" then
						net.WriteString("__add")
					elseif status == "none" or status == "blocked" then
						net.WriteString("__remove")
					end
				net.SendToServer()
			end
			ply.friends_last_friend_status = status

			local status = cookie.GetString("friends_" .. ply:UniqueID(), "none")
			if ply.friends_last_cookie ~= status then
				if status == "clear" then
					cookie.Delete("friends_" .. ply:UniqueID())
				else
					net.Start("friends")
						net.WriteEntity(ply)
						net.WriteString(status)
					net.SendToServer()
				end
			end
			ply.friends_last_cookie = status
		end
	end)

	concommand.Add("friends_set", function(ply, _, args)
		local ply = player.GetByUniqueID(args[1])
		if not ply:IsValid() then return end

		net.Start("friends")
			net.WriteEntity(ply)
			net.WriteString(args[2])
		net.SendToServer()

		cookie.Set("friends_" .. args[1], args[2])
	end)
end

function friends.ClientPanel(Panel)
	Panel:ClearControls()

	if not friends.ClientCPanel then
		friends.ClientCPanel = Panel
	end

	Panel:AddControl("Label", {Text = "friends"})

	local plys = player.GetAll()
	if table.Count(plys) == 1 then
		Panel:AddControl("Label", {Text = "no players are online"})
	else
		for _, ply in ipairs(plys) do
			if ply ~= LocalPlayer() then
				local check = Panel:AddControl("CheckBox", {Label = ply:Nick()})
				check.OnChange = function(_, b)
					RunConsoleCommand("friends_set", ply:UniqueID(), b and "add" or "remove")
				end
				check:SetChecked(aowl.GetFriend(LocalPlayer(), ply))
			end
		end
	end

	Panel:AddControl("Button", {Text = "clear friend overrides"}).DoClick = function()
		for _, ply in ipairs(player.GetAll()) do
			RunConsoleCommand("friends_set", ply:UniqueID(), "clear")
		end
	end
end


function friends.SpawnMenuOpen()
	if IsValid(friends.ClientCPanel) then
		friends.ClientPanel(friends.ClientCPanel)
	end
end
hook.Add("SpawnMenuOpen", "friends", friends.SpawnMenuOpen)

function friends.PopulateToolMenu()
	spawnmenu.AddToolMenuOption("Utilities", "AOWL", "Friends", "Friends", "", "", friends.ClientPanel)
end
hook.Add("PopulateToolMenu", "friends", friends.PopulateToolMenu)