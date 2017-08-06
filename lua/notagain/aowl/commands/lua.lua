local luadev = requirex("luadev")

-- this will require easylua on server as well which is needed to setup some network messages
requirex("easylua")

local function run(func, script, ply, name)
	local valid, err = luadev.ValidScript(script, name)
	if not valid then return false, err end
	return func(script, luadev.GetPlayerIdentifier(ply, "cmd:" .. name), {sender = ply})
end

aowl.AddCommand("l", function(ply, script)
	return run(luadev.RunOnServer, script, ply, "l")
end, "developers")

aowl.AddCommand("ls", function(ply, script)
	return run(luadev.RunOnShared, script, ply, "l")
end, "developers")

aowl.AddCommand("lc", function(ply, script)
	return run(luadev.RunOnClients, script, ply, "lc")
end, "developers")

aowl.AddCommand("print", function(ply, script)
	return run(luadev.RunOnServer, "print(" .. script .. ")", ply, "print")
end, "developers")

aowl.AddCommand("table", function(ply, script)
	return run(luadev.RunOnServer, "PrintTable(" .. script .. ")", ply, "table")
end, "developers")

aowl.AddCommand("keys", function(ply, script)
	return run(luadev.RunOnServer, "for k, v in pairs(" .. script .. ") do print(k) end", ply, "keys")
end, "developers")

aowl.AddCommand("printc", function(ply, script)
	return run(luadev.RunOnClients, "requirex('easylua').PrintOnServer(" .. script .. ")", ply, "printc")
end, "developers")

-- specific client
aowl.AddCommand("lsc=player_admin|player_alter,string_rest", function(ply, _, ent, script)
	if not ply:IsAdmin() and not GetConVar("sv_allowcslua"):GetBool() then
		return false, "sv_allowcslua is 0"
	end

	local valid, err = luadev.ValidScript(script, "lsc")
	if not valid then return false, err end
	return luadev.RunOnClient(script, ent, luadev.GetPlayerIdentifier(ply, "cmd:lsc"), {sender = ply})
end, "developers")

do -- self
	aowl.AddCommand("lm", function(ply, script)
		if not ply:IsAdmin() and not GetConVar("sv_allowcslua"):GetBool() then
			return false, "sv_allowcslua is 0"
		end

		local valid,err = luadev.ValidScript(script, "lm")
		if not valid then return false, err end

		luadev.RunOnClient(script, ply, luadev.GetPlayerIdentifier(ply, "cmd:lm"), {sender = ply})
	end, "players")

	aowl.AddCommand("gl", function(ply, script)
		if not ply:IsAdmin() and not GetConVar("sv_allowcslua"):GetBool() then
			return false, "sv_allowcslua is 0"
		end

		script = "requirex('goluwa').SetEnv() " .. script
		local valid,err = luadev.ValidScript(script, "lm")
		if not valid then return false, err end

		luadev.RunOnClient(script, ply, luadev.GetPlayerIdentifier(ply, "cmd:lm"), {sender = ply})
	end, "players")

	aowl.AddCommand("printm", function(ply, script)
		if not ply:IsAdmin() and not GetConVar("sv_allowcslua"):GetBool() then
			return false, "sv_allowcslua is 0"
		end

		script = "requirex('easylua').PrintOnServer(" .. script .. ")"
		local valid, err = luadev.ValidScript(script, "printm")
		if not valid then return false, err end

		luadev.RunOnClient(script, ply, luadev.GetPlayerIdentifier(ply, "cmd:printm"), {sender = ply})
	end)
end

do -- self and server
	aowl.AddCommand("printb", function(ply, script)
		local ok, err
		ok, err = aowl.Execute(ply, "print " .. script)
		if not ok then return ok, err end
		ok, err = aowl.Execute(ply, "printm " .. script)
		if not ok then return ok, err end
	end, "developers")

	aowl.AddCommand("lb", function(ply, script)
		local ok, err
		ok, err = aowl.Execute(ply, "l " .. script)
		if not ok then return ok, err end
		ok, err = aowl.Execute(ply, "lm " .. script)
		if not ok then return ok, err end
	end, "developers")
end