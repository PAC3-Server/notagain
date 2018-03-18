if not game.IsDedicated() then return end
if engine.ActiveGamemode() ~= "sandbox" then return end

local restarting = false
local try_restart = false
local reason = false

file.Delete("server_want_restart.txt")
file.Write("server_last_restart.txt", tostring(os.time()))

timer.Create("auto_restart", 2, 0, function()
	local want_restart = os.time() - tonumber(file.Read("server_last_restart.txt", "DATA") or 0) > (6 * 60 * 60)

	if file.Exists("server_want_restart.txt", "DATA") then
		reason = file.Read("server_want_restart.txt", "DATA")
		try_restart = true
	end

	if want_restart or try_restart then
		local players = player.GetAll()
		local afk = true

		for _, ply in ipairs(players) do
			afk = ply:IsAFK()
			if not afk then
				break
			end
		end

		if afk then
			if not players[1] then
				hook.Run("AutoRestart", want_restart, reason)
				game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n")
				return
			end

			if not restarting then
				restarting = true
				hook.Run("AutoRestart", want_restart, reason)
				aowl.CountDown(15, "RESTARTING SERVER BECAUSE EVERYONE IS AFK", function()
					game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n")
				end)
			end
		else
			if restarting then
				restarting = false
				aowl.AbortCountDown()
			end
		end
	end
end)