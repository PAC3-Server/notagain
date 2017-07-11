local easylua = requirex("easylua")
local luadev = requirex("luadev")

local function add(cmd, callback, group)
	aowl.AddCommand(cmd, function(ply, ...)
		local a,b

		easylua.End() -- nesting not supported

		a, b = callback(ply, ...)

		easylua.Start(ply)

		return a, b
	end, group or "developers")
end

local function X(ply, i) return luadev.GetPlayerIdentifier(ply, "cmd:" .. i) end

local function run(func, line, ply, x)
	local valid,err = luadev.ValidScript(line, x)
	if not valid then return false, err end
	return func(line, X(ply, x), {ply = ply})
end

add("l", function(ply, line) return run(luadev.RunOnServer, line, ply, "l") end)
add("ls", function(ply, line) return run(luadev.RunOnShared, line, ply, "l") end)
add("lc", function(ply, line) return run(luadev.RunOnClients, line, ply, "lc") end)

add("print", function(ply, line) return run(luadev.RunOnServer, "print(" .. line .. ")", ply, "print") end)
add("table", function(ply, line) return run(luadev.RunOnServer, "PrintTable(" .. line .. ")", ply, "table") end)
add("keys", function(ply, line) return run(luadev.RunOnServer, "for k, v in pairs(" .. line .. ") do print(k) end", ply, "keys") end)

add("printc", function(ply, line) return run(luadev.RunOnClients, "requirex('easylua').PrintOnServer(" .. line .. ")", ply, "printc") end)

-- specific client
add("lsc=player_admin|player_alter,string_rest", function(ply, _, ent, script)
	local valid, err = luadev.ValidScript(script, "lsc")
	if not valid then return false, err end
	return luadev.RunOnClient(script,  ent,  X(ply, "lsc"), {ply = ply})
end)

do -- self
	add("lm", function(ply, line)
		if not ply:IsAdmin() and not GetConVar("sv_allowcslua"):GetBool() then return false, "sv_allowcslua is 0" end

		line = "requirex('easylua').PrintOnServer(" .. line .. ")"
		local valid,err = luadev.ValidScript(line, "lm")
		if not valid then return false, err end

		luadev.RunOnClient(line, ply, X(ply, "lm"), {ply = ply})
	end, "players")

	add("printm", function(ply, line)
		if not ply:IsAdmin() and not GetConVar("sv_allowcslua"):GetBool() then return false, "sv_allowcslua is 0" end

		line = "requirex('easylua').PrintOnServer(" .. line .. ")"
		local valid,err = luadev.ValidScript(line, "printm")
		if not valid then return false, err end

		luadev.RunOnClient(line, ply, X(ply, "printm"), {ply = ply})
	end)
end

do -- self and server
	add("printb", function(ply, line)
		local ok, err
		ok, err = aowl.Execute(ply, "print " .. line)
		if not ok then return ok, err end
		ok, err = aowl.Execute(ply, "printm " .. line)
		if not ok then return ok, err end
	end)

	add("lb", function(ply, line)
		local ok, err
		ok, err = aowl.Execute(ply, "l " .. line)
		if not ok then return ok, err end
		ok, err = aowl.Execute(ply, "lm " .. line)
		if not ok then return ok, err end
	end)
end