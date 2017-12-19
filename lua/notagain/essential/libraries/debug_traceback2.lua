local function tostringx(obj)
	local t = type(obj)

	if obj == NULL then
		return t .. "(NULL)"
	elseif t == "string" then
		if obj:find("\n", nil, true) then
			obj = obj:gsub("\n", "\\n"):sub(0,50) .. "..."
		end

		return '"' .. obj .. '"'
	elseif t == "Player" then
		return "Player("..obj:EntIndex()..") -- " .. obj:SteamID64()
	elseif t == "Entity" then
		return "Entity("..obj:EntIndex()..")"
	elseif t == "function" then
		local info = debug.getinfo(obj)

		if info.source == "=[C]" then
			return "function() end -- C function"
		else
			local params = {}

			for i = 1, math.huge do
				local key = debug.getlocal(obj, i)
				if key then
					table.insert(params, key)
				else
					break
				end
			end

			return "function(" .. table.concat(params, ", ") .. ") end -- " .. info.source .. ":" .. info.linedefined
		end
	end

	local ok, str = pcall(tostring, obj)

	if not ok then
		return "tostring error: " .. str
	end

	return str
end

return function(offset, check_level)
	offset = offset or 0
	local str = ""

	local max_level = 0
	local min_level = offset

	for level = min_level, math.huge do
		local info = debug.getinfo(level)
		if not info then break end
		max_level = level
	end

	local extra_indent = 0
	local for_loop
	local for_gen
	local generator

	for level = max_level, min_level, -1 do
		local info = debug.getinfo(level-1)
		if not info then break end

		if check_level and check_level(info, level) ~= nil then break end

		local t = (" "):rep(-level + max_level + extra_indent)

		for i = 1, math.huge do
			local key, val = debug.getlocal(level, i)
			if not key then break end

			if key == "(for generator)" then
				for_gen = ""
				generator = val
			elseif key == "(for state)" then
			elseif key == "(for control)" then

			elseif key == "(for index)" then
				for_loop = ""
			elseif key == "(for limit)" then
				for_loop = for_loop .. val .. ", "
			elseif key == "(for step)" then
				for_loop = for_loop .. val .. " do"
			elseif key ~= "(*temporary)" then
				if for_loop then
					str = str .. t .. "for " .. key .. " = " .. val .. ", " .. for_loop .. "\n"

					extra_indent = extra_indent + 1
					t = (" "):rep(-level + max_level + extra_indent)

					for_loop = nil
				else

					if for_gen then
						if for_gen == "" then
							for_gen = "for " .. key .. " = " .. tostringx(val) .. ", "
						else
							for_gen = for_gen .. key .. " = " .. tostringx(val) .. " in ??? do"

							str = str .. t .. for_gen .. "\n"

							extra_indent = extra_indent + 1
							t = (" "):rep(-level + max_level + extra_indent)

							generator = nil
							for_gen = nil
						end
					else
						str = str .. t .. key .. " = " .. tostringx(val) .. "\n"
					end
				end
			end
		end

		if not info.name then
			if level == max_level then
				info.name = "main"
			end
		end

		do
			local info = debug.getinfo(level)
			if info and info.source and info.source:sub(1,1) == "@" then
				local lua = file.Read(info.source:sub(2), "LUA") or file.Read(info.source:sub(2), "MOD")
				if lua then
					local lines = lua:Split("\n")
					if lines[info.currentline] then
						str = str .. t .. "-- " .. lines[info.currentline]:Trim() .. "\n"
					end
				end
			end
		end

		if info.proper_name then
			str = str .. t .. "function " .. (info.name or "__UNKNOWN__")
		else
			str = str .. t .. "function " .. (info.name or "__UNKNOWN__")
			str = str .. "("

			if info.isvararg then
				str = str .. "..."
			else
				for i = 1, info.nparams do
					local key, val = debug.getlocal(info.func, i)

					if not key then break end

					if key == "(*temporary)" then
						str = str .. tostringx(val) .. ", "
					elseif key:sub(1, 1) ~= "(" then
						str = str .. key .. ", "
					end
				end
			end

			if str:sub(#str, #str) == ", " then
				str = str:sub(0, -3)
			end
		end

		if info.source:sub(1, 1) == "@" then
			str = str .. ") -- " .. info.source:sub(2) .. ":" .. info.linedefined
		else
			str = str .. ")"
		end

		str = str .. "\n"
	end

	return str
end