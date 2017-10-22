AddCSLuaFile()

local luadata = requirex("luadata")

local aowl = {}
_G.aowl = aowl

do

	local function compare(a, b)

		if a == b then return true end
		if a:find(b, nil, true) then return true end
		if a:lower() == b:lower() then return true end
		if a:lower():find(b:lower(), nil, true) then return true end

		return false
	end

	local function comparenick(a, b)
		local MatchTransliteration = GLib and GLib.UTF8 and GLib.UTF8.MatchTransliteration
		if not MatchTransliteration then return compare (a, b) end

		if a == b then return true end
		if a:lower() == b:lower() then return true end
		if MatchTransliteration(a, b) then return true end

		return false
	end

	local function compareentity(ent, str)
		if ent.GetName and compare(ent:GetName(), str) then
			return true
		end

		if ent:GetModel() and compare(ent:GetModel(), str) then
			return true
		end

		return false
	end

	local function vec3(str, ctor)
		local num = str:Split(" ")
		local ok = true

		if #num == 3 then
			for i, v in ipairs(num) do
				num[i] = tonumber(v)

				if not num[i] then
					ok = false
					break
				end
			end

			return ctor(unpack(num))
		end

		if not ok then
			local test = str:match("(b())")
			if test then
				return vec3(test:sub(2, -2), ctor)
			end
		end
	end

	local function trace_me(me)
		if IsEntity(me) and me:IsPlayer() and me:IsValid() then
			return util.QuickTrace(me:EyePos(), me:GetAimVector() * 10000, {me, me:GetVehicle()})
		end
	end

	local function no_filter()
		return true
	end

	local function find_entity(str, me, filter)
		if str == "" then return end

		filter = filter or no_filter

		if str == "#this" or str == "this" then
			local trace = trace_me(me)
			if trace and trace.Entity:IsValid() and filter(trace.Entity) then
				return trace.Entity
			end
		end

		for key, ent in pairs(ents.GetAll()) do
			if compareentity(ent, str) and filter(ent) then
				return ent
			end
		end

		if str:sub(1,1) == "_" and tonumber(str:sub(2)) then
			str = str:sub(2)
		end

		if tonumber(str) then
			local ent = Entity(tonumber(str))
			if ent:IsValid() and not ent:IsPlayer() and filter(ent) then
				return ent
			end
		end

		do -- class
			local _str, idx = str:match("(.-)(%d+)$")
			if idx then
				idx = tonumber(idx)
				str = _str
			else
				idx = (me and me.aowl_entity_iterator) or 0
			end

			local found = {}

			for key, ent in pairs(ents.GetAll()) do
				if compare(ent:GetClass(), str) and filter(ent) then
					table.insert(found, ent)
				end
			end

			local ent = found[math.Clamp(idx%#found, 1, #found)]

			if ent then
				me.aowl_entity_iterator = (me.aowl_entity_iterator or 0) + 1

				return ent
			end
		end
	end

	local function find_player(str, me, filter)
		if str == "" then return end

		filter = filter or no_filter

		assert(isstring(str), 'String expected got ' .. type(str))

		do
			local ply = player.GetByUniqueID(str)

			if ply and ply:IsPlayer() and filter(ply) then
				return ply
			end
		end

		-- steam id
		if str:find("STEAM", nil, true) then
			for key, _ply in ipairs(player.GetAll()) do
				if _ply:SteamID() == str and filter(me) then
					return _ply
				end
			end
		end

		-- ip
		if SERVER then
			if str:find("%d+%.%d+%.%d+%.%d+") then
				for key, _ply in pairs(player.GetAll()) do
					if _ply:IPAddress():find(str) and filter(me) then
						return _ply
					end
				end
			end
		end

		-- search exact
		for _,ply in pairs(player.GetAll()) do
			if ply:Nick() == str and filter(ply) then
				return ply
			end
		end

		-- Search bots so we target those first
		for _, ply in pairs(player.GetBots()) do
			if comparenick(ply:Nick(), str) and filter(ply) then
				return ply
			end
		end

		-- search from beginning of nick
		for _,ply in pairs(player.GetHumans()) do
			if ply:Nick():lower():find(str, 1, true) == 1 and filter(ply) then
				return ply
			end
		end

		-- Search normally and search with colorcode stripped
		for _, ply in pairs(player.GetAll()) do
			if comparenick(ply:Nick(), str) and filter(ply) then
				return ply
			end

			if comparenick(ply:Nick():gsub("%^%d+", ""), str) and filter(ply) then
				return ply
			end
		end

		if str == "#randply" or str == "randply" then
			for _, ply in RandomPairs(player.GetAll()) do
				if filter(ply) then
					return ply
				end
			end
		end

		if str == "#this" or str == "this" then
			local trace = trace_me(me)

			if trace and trace.Entity:IsPlayer() and filter(trace.Entity) then
				return trace.Entity
			end
		end

		-- add #him / #her?

		if str == "#me" or str == "me" then
			if IsEntity(me) and me:IsPlayer() and me:IsValid() and filter(me) then
				return me
			end
		end
	end

	local META = {}

	function META:__index(key)
		return function(_, ...)
			local args = {}

			for _, ent in ipairs(self) do
				if type(ent[key]) == "function" or ent[key] == "table" and type(ent[key].__call) == "function" and getmetatable(ent[key]) then
					table.insert(args, {ent = ent, args = (ent[key](ent, ...))})
				else
					ErrorNoHalt("attempt to call field '" .. key .. "' on ".. tostring(ent) .." a " .. type(ent[key]) .. " value\n")
				end
			end

			return args
		end
	end

	function META:__newindex(key, value)
		for _, ent in ipairs(self) do
			ent[key] = value
		end
	end

	function wrap_entities(tbl, filter)
		local out = {}
		for i, v in ipairs(tbl) do
			if not filter or filter(v) then
				table.insert(out, v)
			end
		end
		return setmetatable(out, META)
	end

	aowl.ArgumentTypes = {
		["nil"] = function(str) return str end,
		self = function(str, me) return me end,
		vector = function(str, me)
			return vec3(str, Vector)
		end,
		angle = function(str, me)
			return vec3(str, Angle)
		end,
		location = function(str, me)
			local force_entities = false

			if string.sub(str, 1, 1) == "#" then
				str = string.sub(str, 2, #str)
				force_entities = true
			end

			if not force_entities then
				if compare(str, "spawn") or compare(str, "somewhere") then
					return str
				end

				local pos = aowl.StringToType("vector", str, me)

				if pos then
					return pos
				end

				local areas = MapDefine and MapDefine.Areas or {}
				for area, data in next, areas do
					if compare(area, str) then
						return area
					end
				end
			end

			local ent = find_player(str, me) or find_entity(str, me)
			if ent then
				return ent
			end
		end,
		entity = function(str, me)
			local ent = find_entity(str, me) or find_player(str, me)

			if ent then
				return ent
			end
		end,
		player = function(str, me)
			local ent = find_player(str, me) or find_entity(str, me)

			if ent then
				return ent
			end
		end,
		player_alter = function(str, me)
			local ent = find_player(str, me, function(ent) return me:CanAlter(ent) end)

			if ent then
				return ent
			end
		end,
		player_admin = function(str, me)
			if not me:IsAdmin() then return end

			local ent = find_player(str, me)

			if ent then
				return ent
			end
		end,
		entity_alter = function(str, me)
			local ent = find_entity(str, me, function(ent) return me:CanAlter(ent) end) or find_player(str, me, function(ent) return me:CanAlter(ent) end)

			if ent then
				return ent
			end
		end,
		entities = function(str, me, alter)
			alter = alter or no_filter

			if str == "everything" then
				return wrap_entities(ents.GetAll(), function(v) return true end)
			end

			if str == "props" then
				return wrap_entities(ents.GetAll(), function(v) return v:GetClass() == "prop_physics" end)
			end

			if str == "these" then
				local trace = trace_me(me)
				if trace and trace.Entity:IsValid() then
					return wrap_entities(ents.GetAll(), constraint.GetAllConstrainedEntities(trace.Entity))
				end
			end

			local ent = find_entity(str, me, alter)

			if ent then
				return wrap_entities({ent})
			end
		end,
		players = function(str, me, alter)
			alter = alter or no_filter

			if str == "us" then
				return wrap_entities(player.GetAll(), function(v) return v:GetPos():Distance(me:GetPos()) < 512 end)
			end

			if str == "everyone else" then
				return wrap_entities(player.GetAll(), function(v) return v ~= me end)
			end

			if str == "everyone" or str == "all" then
				return wrap_entities(player.GetAll())
			end

			if str == "friends" then
				return wrap_entities(player.GetAll(), function(v) return me:IsFriend(v) end)
			end

			local ent = find_player(str, me, alter)

			if ent then
				return wrap_entities({ent})
			end
		end,
		players_alter = function(str, me)
			return aowl.StringToType("players", str, me, function(ent) return me:CanAlter(ent) end)
		end,
		entities_alter = function(str, me)
			return aowl.StringToType("entities", str, me, function(ent) return me:CanAlter(ent) end)
		end,
		boolean = function(arg)
			arg = arg:lower()

			if arg == "1" or arg == "true" or arg == "on" or arg == "yes" or arg == "y" then
				return true
			end

			if arg == "0" or arg == "false" or arg == "off" or arg == "no" or arg == "n" then
				return false
			end

			return false
		end,
		number = function(arg)
			return tonumber(arg)
		end,
		string = function(arg)
			if #arg > 0 then
				return arg
			end
		end,
		string_trim = function(arg)
			arg = arg:Trim()
			if #arg > 0 then
				return arg
			end
		end,
		string_rest = function(arg) return arg end,
	}

	function aowl.StringToType(type, ...)
		return aowl.ArgumentTypes[type](...)
	end
end

local function log(cmd, line)
	MsgC(Color(51,255,204), "[aowl]"..(cmd and ' '..tostring(cmd) or "")..' ')
	MsgN(line)
end

aowlMsg = log -- AOWL LEGACY

do -- commands
	local function utf8_totable(str)
		local tbl = {}
		local i = 1

		for tbl_i = 1, #str do
			local byte = str:byte(i)

			if not byte then break end

			local length = 1

			if byte >= 128 then
				if byte >= 240 then
					length = 4
				elseif byte >= 224 then
					length = 3
				elseif byte >= 192 then
					length = 2
				end
			end

			tbl[tbl_i] = str:sub(i, i + length - 1)

			i = i + length
		end

		return tbl
	end

	local function levenshtein(a, b)
		local distance = {}

		for i = 0, #a do
		  distance[i] = {}
		  distance[i][0] = i
		end

		for i = 0, #b do
		  distance[0][i] = i
		end

		local str1 = utf8_totable(a)
		local str2 = utf8_totable(b)

		for i = 1, #a do
			for j = 1, #b do
				distance[i][j] = math.min(
					distance[i-1][j] + 1,
					distance[i][j-1] + 1,
					distance[i-1][j-1] + (str1[i-1] == str2[j-1] and 0 or 1)
				)
			end
		end

		return distance[#a][#b]
	end

	aowl.commands = aowl.commands or {}
	aowl.help = aowl.help or {}

	local capture_symbols = {
		["\""] = "\"",
		["'"] = "'",
		["("] = ")",
		["["] = "]",
		["`"] = "`",
		["´"] = "´",
	}

	local function parse_args(arg_line)
		if not arg_line or arg_line:Trim() == "" then return {} end

		local args = {}
		local capture = {}
		local escape  = false

		local in_capture = false

		for _, char in ipairs(utf8_totable(arg_line)) do
			if escape then
				table.insert(capture, char)
				escape = false
			else
				if in_capture then
					if char == in_capture then
						in_capture = false
					end

					table.insert(capture, char)
				else
					if char == "," then
						table.insert(args, table.concat(capture, ""))
						table.Empty(capture)
					else
						table.insert(capture, char)

						if capture_symbols[char] then
							in_capture = capture_symbols[char]
						end

						if char == "\\" then
							escape = true
						end
					end
				end
			end
		end

		table.insert(args, table.concat(capture, ""))

		return args
	end

	local start_symbols = {
		"%!",
		"%.",
		"%/",
		"",
	}

	local function parse_line(line)
		for _, v in ipairs(start_symbols) do
			local start, rest = line:match("^(" .. v .. ")(.+)")
			if start then
				local cmd, rest_ = rest:match("^(%S+)%s+(.+)$")
				if not cmd then
					return v, rest:Trim()
				else
					return v, cmd, rest_
				end
			end
		end
	end

	function aowl.AddCommand(command, callback, group)
		-- AOWL LEGACY
		if type(command) == "table" then
			command = table.concat(command, "|")
		end

		local aliases = command
		local argtypes
		local defaults

		if command:find("=") then
			aliases, argtypes =  command:match("(.+)=(.+)")
			if not aliases then
				aliases = command
			end
		end

		aliases = aliases:Split("|")

		if argtypes then
			argtypes = argtypes:Split(",")

			for i, v in ipairs(argtypes) do
				if v:find("|", nil, true) then
					argtypes[i] = v:Split("|")
				else
					argtypes[i] = {v}
				end
			end

			for i, types in ipairs(argtypes) do
				for i2, arg in ipairs(types) do
					if arg:find("[", nil, true) then
						local temp, default = arg:match("(.+)(%b[])")
						if aowl.ArgumentTypes[temp] then
							defaults = defaults or {}
							default = default:sub(2, -2)

							-- special case
							if temp == "string" then
								defaults[i] = default
							else
								defaults[i] = aowl.StringToType(temp, default)
							end

							types[i2] = temp
						else
							log(aliases[1] .. ": no type information found for \"" .. temp .. "\"")
						end
					end
				end
			end
		end

		aowl.commands[aliases[1]] = {
			aliases = aliases,
			argtypes = argtypes,
			callback = callback,
			group = group,
			defaults = defaults
		}

		hook.Run("AowlCommandAdded", aowl.commands[aliases[1]])
	end

 	function aowl.AddHelp(command, help)
  		local commandFound, msg = aowl.FindCommand(command)
  		if not commandFound then
  			return false
  		end

  		for _, alias in next, commandFound.aliases do
			aowl.help[alias] = help
		end
  		return true
  	end

  	function aowl.FindCommand(str)
		local found = {}

		for _, command in pairs(aowl.commands) do
			for _, alias in ipairs(command.aliases) do
				if str:lower() == alias:lower() then
					return command
				end
				table.insert(found, {distance = levenshtein(str, alias), alias = alias, command = command})
			end
		end

		table.sort(found, function(a, b) return a.distance < b.distance end)

		return nil, "could not find command " .. str .. ". did you mean " .. found[1].alias .. "?"
	end

	function aowl.GetHelpText(alias)
		local command, msg = aowl.FindCommand(alias)
		if not command then return false, msg end

		local str = aowl.help[command]

		if str then
			return str
		end

		local params = {}

		for i = 1, math.huge do
			local key = debug.getlocal(command.callback, i)
			if key then
				table.insert(params, key)
			else
				break
			end
		end

		str = "!" .. alias .. " "

		if #params == 2 then
			str = str .. params[2]
		else
			for i = 3, #params do
				local arg_name = params[i]
				local types = command.argtypes[i-2]
				local default = command.defaults and command.defaults[i-2]

				str = str .. arg_name .. ""

				if types then
					str = str .. "<"
					for _, type in pairs(types) do
						str = str .. type
						if _ ~= #types then
							str = str .. " or "
						end
					end
					str = str .. ">"
				end

				if default then
					str = str .. " = " .. tostring(default)
				end

				if i ~= #params then
					str = str .. ", "
				end
			end
		end

		return "usage example: \n" .. str
	end

	function aowl.ParseString(str)
		local symbol, alias, arg_line = parse_line(str)

		local args = parse_args(arg_line)
		local command, err = aowl.FindCommand(alias)

		if not command then return command, err end

		return command, alias, arg_line, args
	end

	function aowl.RunString(ply, str)
		local command, alias, arg_line, args = assert(aowl.ParseString(str))

		if command.group then
			local ok = false
			local name

			if command.group == "localplayer" then
				if CLIENT and ply == LocalPlayer() then
					ok = true
				else
					return true
				end
			elseif command.group == "clientside" then
				if CLIENT then
					ok = true
				else
					return true
				end
			end

			if SERVER then
				if type(ply) == "string" then
					ok = aowl.CheckUserGroupFromSteamID(ply, command.group)
					name = ply
				elseif type(ply) == "Player" then
					ok = ply:CheckUserGroupLevel(command.group)
					name = ply:Nick() .. " ( " .. ply:SteamID() .. " )"
				elseif not ply:IsValid() then
					ok = true -- console
					name = "SERVER CONSOLE"
				end
			end

			if not ok then
				error(name .. " is not allowed to execute " .. alias .. " because group is " .. command.group)
			end
		end

		if command.argtypes then
			for i, arg in ipairs(args) do
				if command.argtypes[i] then
					for _, arg_type in ipairs(command.argtypes[i]) do
						if not aowl.ArgumentTypes[arg_type] then
							log(alias .. ": no type information found for \"" .. arg_type .. "\"")
						end
					end
				end
			end

			for i, arg_types in ipairs(command.argtypes) do
				if command.defaults and args[i] == nil and command.defaults[i] then
					args[i] = command.defaults[i]
				end

				if args[i] ~= nil or not table.HasValue(arg_types, "nil") then
					local val

					for _, arg_type in ipairs(arg_types) do
						if arg_type == "string_rest" then
							val = table.concat({select(i, unpack(args))}, ","):Trim()
						else
							local test = aowl.ArgumentTypes[arg_type](args[i] or "", ply)

							if test ~= nil then
								val = test
								break
							end
						end
					end

					if val == nil and command.defaults and args[i] then

					else
						if val == nil then
							local err = "unable to convert argument " .. (debug.getlocal(command.callback, i+2) or i) .. " >>|" .. (args[i] or "") .. "|<< to one of these types: " .. table.concat(command.argtypes[i], ", ") .. "\n"
							err = err .. aowl.GetHelpText(alias) .. "\n"
							error(err)
						end

						args[i] = val
					end
				end
			end
		end

		local ret, reason = hook.Run("AowlCommand", command, alias, ply, arg_line, unpack(args))

		if ret == false then return ret, reason or "no reason" end

		return command.callback(ply, arg_line, unpack(args))
	end

	function aowl.Execute(ply, str)
		local a, b, c = pcall(aowl.RunString, ply, str)

		if a == false then
			return false, b
		end

		if b == false then
			return false, c or "unknown reason"
		end

		return true
	end

	function aowl.SayCommand(ply, txt)
		if #txt == 1 then return end

		local ok = false

		for _, symbol in ipairs(start_symbols) do
			if #symbol > 0 then
				if txt:sub(1, 1):find(symbol) then
					ok = true
					break
				end
			end
		end

		if not ok then return end

		local ok, reason = aowl.Execute(ply, txt)

		if not ok then

			if CLIENT and reason:find("could not find command") then
				return
			end

			timer.Simple(0, function()
				if ply:IsValid() then
					local msg = "aowl: " .. reason
					if CLIENT and ply ~= LocalPlayer() then
						MsgN(msg)
					else
						ply:ChatPrint(msg)
					end
				end
			end)
		end
	end

	function aowl.ConsoleCommand(ply, cmd, args, line)
		local cmd = table.remove(args, 1) or "Command Not Found"
		local ok, reason = aowl.Execute(ply, cmd .. " " .. table.concat(args, ","))
	end

	if SERVER then
		concommand.Add("a", aowl.ConsoleCommand)
		concommand.Add("aowl", aowl.ConsoleCommand)

		hook.Add("PlayerSay", "aowl", aowl.SayCommand)
	end

	if CLIENT then
		hook.Add("OnPlayerChat", "aowl", aowl.SayCommand)
	end

	function aowl.TargetNotFound(target)
		return string.format("could not find: %q", target or "<no target>")
	end

	aowl.AddCommand("help|usage=string", function(ply, line, cmd)
		ply:ChatPrint(assert(aowl.GetHelpText(cmd)))
	end)
end

do -- message
	local NOTIFY = {
		GENERIC	= 0,
		ERROR	= 1,
		UNDO	= 2,
		HINT	= 3,
		CLEANUP	= 4,
	}
	function aowl.Message(ply, msg, msgtype, duration)
		duration = duration or 5

		local lua = string.format(
			"local s=%q notification.AddLegacy(s,%u,%s) MsgN(s)",
			"aowl: " .. msg,
			NOTIFY[(msgtype and msgtype:upper())] or NOTIFY.GENERIC,
			duration
		)

		if type(ply) ~= "table" then ply = {ply} end

		for _, ply in ipairs(ply) do
			ply:SendLua(lua)
			ply:EmitSound("buttons/button15.wav")
		end
	end

	aowl.AddCommand("message=string,number[15],string[generic]", function(ply, line, msg, duration, type)
		aowl.Message(nil, msg, "generic", duration)
	end, "developers")
end

do -- countdown
	if SERVER then
		aowl.AddCommand("abort|stop", function(player, line)
			aowl.AbortCountDown()
		end, "developers")

		local function Shake()
			for k,v in pairs(player.GetAll()) do
				util.ScreenShake(v:GetPos(), math.Rand(.1,1.5), math.Rand(1,5), 2, 500)
			end
		end

		function aowl.CountDown(seconds, msg, callback, typ)
			seconds = seconds and tonumber(seconds) or 0

			local function timeout()
				umsg.Start("__countdown__")
					umsg.Short(-1)
				umsg.End()
				if callback then
					log("countdown", "'"..tostring(msg).."' finished, calling "..tostring(callback))
					callback()
				else
					if seconds<1 then
						log("countdown", "aborted")
					else
						log("countdown", "'"..tostring(msg).."' finished. Initated without callback by "..tostring(source))
					end
				end
			end


			if seconds > 0.5 then
				timer.Create("__countdown__", seconds, 1, timeout)
				timer.Create("__countbetween__", 1, math.floor(seconds), Shake)

				umsg.Start("__countdown__")
					umsg.Short(typ or 2)
					umsg.Short(seconds)
					umsg.String(msg)
				umsg.End()
				local date = os.prettydate and os.prettydate(seconds) or seconds.." seconds"
				log("countdown", "'"..msg.."' in "..date )
			else
				timer.Remove "__countdown__"
				timer.Remove "__countbetween__"
				timeout()
			end
		end

		aowl.AbortCountDown = aowl.CountDown
	end

	if CLIENT then
		local CONFIG = {}

		CONFIG.TargetTime 	= 0
		CONFIG.Counting 	= false
		CONFIG.Warning 		= ""
		CONFIG.PopupText	= {}
		CONFIG.PopupPos		= {0,0}
		CONFIG.LastPopup	= CurTime()
		CONFIG.Popups		= { "HURRY!", "FASTER!", "YOU WON'T MAKE IT!", "QUICKLY!", "GOD YOU'RE SLOW!", "DID YOU GET EVERYTHING?!", "ARE YOU SURE THAT'S EVERYTHING?!", "OH GOD!", "OH MAN!", "YOU FORGOT SOMETHING!", "SAVE SAVE SAVE" }
		CONFIG.StressSounds = { Sound("vo/ravenholm/exit_hurry.wav"), Sound("vo/npc/Barney/ba_hurryup.wav"), Sound("vo/Citadel/al_hurrymossman02.wav"), Sound("vo/Streetwar/Alyx_gate/al_hurry.wav"), Sound("vo/ravenholm/monk_death07.wav"), Sound("vo/coast/odessa/male01/nlo_cubdeath02.wav") }
		CONFIG.NextStress	= CurTime()
		CONFIG.NumberSounds = { Sound("npc/overwatch/radiovoice/one.wav"), Sound("npc/overwatch/radiovoice/two.wav"), Sound("npc/overwatch/radiovoice/three.wav"), Sound("npc/overwatch/radiovoice/four.wav"), Sound("npc/overwatch/radiovoice/five.wav"), Sound("npc/overwatch/radiovoice/six.wav"), Sound("npc/overwatch/radiovoice/seven.wav"), Sound("npc/overwatch/radiovoice/eight.wav"), Sound("npc/overwatch/radiovoice/nine.wav") }
		CONFIG.LastNumber	= CurTime()

		surface.CreateFont(
			"aowl_restart",
			{
				font		= "Roboto Bk",
				size		= 60,
				weight		= 1000,
			}
		)
		-- local gradient_u = Material("vgui/gradient-u.vtf")
		local function DrawWarning()
			if CurTime()-3 > CONFIG.TargetTime then
				CONFIG.Counting = false
				if CONFIG.Sound then
					CONFIG.Sound:FadeOut(2)
				end
				hook.Remove("HUDPaint", "__countdown__")
			end

			surface.SetFont("aowl_restart")
			local messageWidth = surface.GetTextSize(CONFIG.Warning)

			surface.SetDrawColor(255, 50, 50, 100 + (math.sin(CurTime() * 3) * 80))
			surface.DrawRect(0, 0, ScrW(), ScrH())

			-- Countdown bar
			surface.SetDrawColor(Color(0,220,200,255))
			surface.DrawRect((ScrW() - messageWidth)/2, 175, messageWidth * math.max(0, (CONFIG.TargetTime-CurTime())/(CONFIG.TargetTime-CONFIG.StartedCount) ), 20)
			surface.SetDrawColor(Color(0,0,0,30))
			surface.DrawRect((ScrW() - messageWidth)/2, 175+20/2, messageWidth * math.max(0, (CONFIG.TargetTime-CurTime())/(CONFIG.TargetTime-CONFIG.StartedCount) ), 20/2)
			surface.SetDrawColor(color_black)
			surface.DrawOutlinedRect((ScrW() - messageWidth)/2, 175, messageWidth, 20)

			-- Countdown message
			surface.SetFont("aowl_restart")
			surface.SetTextColor(Color(50, 50, 50, 255))

			local y = 200
			for _, messageLine in ipairs(string.Split(CONFIG.Warning, "\n")) do
				local w, h = surface.GetTextSize(messageLine)
				w = w or 56
				surface.SetTextPos((ScrW() / 2) - w / 2, y)
				surface.DrawText(messageLine)
				y = y + h
			end

			-- Countdown timer
			local timeRemaining = CONFIG.TargetTime - CurTime()
			timeRemaining = math.max(timeRemaining, 0)
			local timeRemainingString = string.format("%02d:%02d:%03d",
				math.floor (timeRemaining / 60),
				math.floor (timeRemaining % 60),
				math.floor ((timeRemaining * 1000) % 1000)
			)

			local w = surface.GetTextSize(timeRemainingString)

			surface.SetTextPos((ScrW() / 2) - w / 2, y)
			surface.DrawText(timeRemainingString)

			surface.SetTextColor(255, 255, 255, 255)
			if(CurTime() - CONFIG.LastPopup > 0.5) then
				for i = 1, 3 do
					CONFIG.PopupText[i] = table.Random(CONFIG.Popups)
					local w, h = surface.GetTextSize(CONFIG.PopupText[i])
					CONFIG.PopupPos[i] = {math.random(1, ScrW() - w), math.random(1, ScrH() - h) }
				end
				CONFIG.LastPopup = CurTime()
			end

			if(CurTime() > CONFIG.NextStress) then
				LocalPlayer():EmitSound(CONFIG.StressSounds[math.random(1, #CONFIG.StressSounds)], 80, 100)
				CONFIG.NextStress = CurTime() + math.random(1, 2)
			end

			local num = math.floor(CONFIG.TargetTime - CurTime())
			if(CONFIG.NumberSounds[num] ~= nil and CurTime() - CONFIG.LastNumber > 1) then
				CONFIG.LastNumber = CurTime()
				LocalPlayer():EmitSound(CONFIG.NumberSounds[num], 511, 100)
			end

			for i = 1, 3 do
				surface.SetTextPos(CONFIG.PopupPos[i][1], CONFIG.PopupPos[i][2])
				surface.DrawText(CONFIG.PopupText[i])
			end
		end

		usermessage.Hook("__countdown__", function(um)
			local typ = um:ReadShort()
			local time = um:ReadShort()

			CONFIG.Sound = CONFIG.Sound or CreateSound(LocalPlayer(), Sound("ambient/alarms/siren.wav"))


			if typ  == -1 then
				CONFIG.Counting = false
				CONFIG.Sound:FadeOut(2)
				hook.Remove("HUDPaint", "__countdown__")
				return
			end

			CONFIG.Sound:Play()
			CONFIG.StartedCount = CurTime()
			CONFIG.TargetTime = CurTime() + time
			CONFIG.Counting = true

			hook.Add("HUDPaint", "__countdown__", DrawWarning)

			if typ == 0 then
				CONFIG.Warning = "SERVER IS RESTARTING THE LEVEL\nSAVE YOUR PROPS AND HIDE THE CHILDREN!"
			elseif typ == 1 then
				CONFIG.Warning = string.format("SERVER IS CHANGING LEVEL TO %s\nSAVE YOUR PROPS AND HIDE THE CHILDREN!", um:ReadString():upper())
			elseif typ == 2 then
				CONFIG.Warning = um:ReadString()
			end
		end)
	end
end

do -- groups
	local USERSFILE = "aowl/users.txt"

	CreateConVar("aowl_hide_ranks", "1", FCVAR_REPLICATED)

	do -- team setup
		function team.GetIDByName(name)
			do return 3003 end

			for id, data in pairs(team.GetAllTeams()) do
				if data.Name == name then
					return id
				end
			end
			return 1
		end
	end

	local list =
	{
		players = 1,
		--moderators = 2,
		emeritus = 2, -- 3
		developers = 3, -- 4,
		owners = math.huge,
	}

	local alias =
	{
		user = "players",
		default = "players",
		admin = "developers",
		moderators = "developers",
		superadmin = "owners",
		superadmins = "owners",
		administrator = "developers",
	}

	local META = FindMetaTable("Player")

	function META:CheckUserGroupLevel(name)

		--Console?
		if not self:IsValid() then return true end


		name = alias[name] or name
		local ugroup=self:GetUserGroup()

		local a = list[ugroup]
		local b = list[name]

		return a and b and a >= b
	end

	function META:ShouldHideAdmins()
		return self.hideadmins or false
	end

	function META:IsAdmin()

		--Console?
		if not self:IsValid() then return true end

		if self:ShouldHideAdmins() then
			return false
		end
		return self:CheckUserGroupLevel("developers")
	end

	function META:IsSudo()
		return self.aowl_sudo and true or false
	end

	function META:SetSudo(b)
		self.aowl_sudo = b
	end

	function META.CanAlter(a, b)
		if a:IsSudo() then
			return true
		end

		if not b:IsPlayer() then
			if b.CPPIGetOwner and b:CPPIGetOwner() then
				return a:CanAlter(b:CPPIGetOwner())
			end

			return true -- no prop protection means you can alter anything
		end

		if b.IsFriend then
			return b:IsFriend(a)
		end
	end

	function META:IsSuperAdmin()

		--Console?
		if not self:IsValid() then return true end

		if self:ShouldHideAdmins() then
			return false
		end
		return self:CheckUserGroupLevel("developers")
	end

	function META:TeleportingBlocked()
		return hook.Run("CanPlyTeleport",self)==false
	end

	function META:IsUserGroup(name)
		name = alias[name] or name
		name = name:lower()

		local ugroup = self:GetUserGroup()

		return ugroup == name or false
	end

	function META:GetUserGroup()
		if self:ShouldHideAdmins() then
			return "players"
		end
		return self:GetNetworkedString("UserGroup"):lower()
	end

	team.SetUp(1, "players", Color(97, 101, 117, 255))
	team.SetUp(2, "friends", Color(96, 178, 138, 255))

	--[[
	team.SetUp(2, "developers", 	Color(147, 63,  147))
	team.SetUp(3, "owners", 		Color(207, 110, 90))
	team.SetUp(4, "emeritus", 		Color(98, 107, 192))
	]]

	if SERVER then
		local dont_store =
		{
			"moderators",
			"players",
			"users",
		}

		local function clean_users(users, _steamid)

			for name, group in pairs(users) do
				name = name:lower()
				if not list[name] then
					users[name] = nil
				else
					for steamid in pairs(group) do
						if steamid:lower() == _steamid:lower() then
							group[steamid] = nil
						end
					end
				end
			end

			return users
		end

		local function safe(str)
			return str:gsub("{",""):gsub("}","")
		end

		function META:SetUserGroup(name, force)
			name = name:Trim()
			name = alias[name] or name

			self:SetTeam(1)
			self:SetNetworkedString("UserGroup", name)
			--[[
			umsg.Start("aowl_join_team")
				umsg.Entity(self)
			umsg.End()
			--]]

			if force == false or #name == 0 then return end

			name = name:lower()

			if force or (not table.HasValue(dont_store, name) and list[name]) then
				local users = luadata.ReadFile(USERSFILE)
					users = clean_users(users, self:SteamID())
					users[name] = users[name] or {}
					users[name][self:SteamID()] = self:Nick():gsub("%A", "") or "???"
				file.CreateDir("aowl")
				luadata.WriteFile(USERSFILE, users)

				if not game.SinglePlayer() then
					log("rank", string.format("Changing %s (%s) usergroup to %s",self:Nick(), self:SteamID(), name))
				end
			end
		end

		function aowl.GetUserGroupFromSteamID(id)
			for name, users in pairs(luadata.ReadFile(USERSFILE)) do
				for steamid, nick in pairs(users) do
					if steamid == id then
						return name, nick
					end
				end
			end
		end

		function aowl.CheckUserGroupFromSteamID(id, name)
			local group = aowl.GetUserGroupFromSteamID(id)

			if group then
				name = alias[name] or name

				local a = list[group]
				local b = list[name]

				return a and b and a >= b
			end

			return false
		end

		local users_file_date,users_file_cache=-2,nil
		hook.Add("PlayerSpawn", "PlayerAuthSpawn", function(ply)

			ply:SetUserGroup("players")

			if game.SinglePlayer() or ply:IsListenServerHost() then
				ply:SetUserGroup("owners")
				return
			end

			local timestamp = file.Time(USERSFILE, "DATA")
			timestamp = timestamp and timestamp > 0 and timestamp or 0/0


			if users_file_date ~= timestamp then
				users_file_cache = luadata.ReadFile( USERSFILE ) or {}
				users_file_date = timestamp
			end

			for name, users_file_cache in pairs(users_file_cache) do
				for steamid in pairs(users_file_cache) do
					if ply:SteamID() == steamid or ply:UniqueID() == steamid then
						if ply:ShouldHideAdmins() then
							ply:SetUserGroup("players",false)
						else
							ply:SetUserGroup(name, false)
						end
					end
				end
			end
		end)

		aowl.AddCommand("rank=player,string_trim", function(player, line, ent, rank)
			rank = rank:lower()
			ent:SetUserGroup(rank, true) -- rank == "players") -- shouldn't it force-save no matter what?
			hook.Run("AowlTargetCommand", player, "rank", ent, {rank = rank})
		end, "owners")

		aowl.AddCommand("hiderank=boolean", function(pl, line, administrate)
			if administrate then
				pl.hideadmins = nil
			elseif pl:IsAdmin() then
				pl.hideadmins = true
			end
		end, "developers")

		aowl.AddCommand("sudo=boolean", function(ply, line, b)
			ply.aowl_sudo = b
		end, "developers")
	end
end

for _, file_name in ipairs((file.Find("notagain/aowl/commands/*", "LUA"))) do
	include("notagain/aowl/commands/" .. file_name)
end

for _, addon_dir in pairs(notagain.directories) do
	local path = addon_dir .. "/aowl_commands/"
	for _, file_name in ipairs((file.Find(path .. "*", "LUA"))) do
		include(path .. file_name)
	end
end

timer.Simple(0, function() hook.Run("AowlInitialized") end)

return aowl
