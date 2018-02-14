local perfutil = _G.perfutil or {}

function perfutil.ExperimentalDisable()
	matproxy.Call = function() end
	matproxy.Init = function() end
	GAMEMODE.PreDrawViewModel = function() end
	GAMEMODE.HUDSHouldDraw = function() end
	hook.Remove( "PlayerTick", "TickWidgets")
end

function perfutil.CheckGlobals(b)
	if b then
		setmetatable(_G, {
			__index = function(_, key)
				print("_G." .. key)
			end,
			__newindex = function(_, key, val)
				print("_G." .. key .. " = " .. tostring(val))
			end,
		})
	else
		setmetatable(_G, nil)
	end
end

do
	perfutil.old_hooks = perfutil.old_hooks or {}

	function perfutil.DisableHooks()
		for event_name, functions in pairs(hook.GetTable()) do
			perfutil.old_hooks[event_name] = perfutil.old_hooks[event_name] or {}
			for id, func in pairs(functions) do
				hook.Remove(event_name, id)
				perfutil.old_hooks[event_name][id] = perfutil.old_hooks[event_name][id] or func
			end
		end
	end

	function perfutil.EnableHooks()
		for event_name, functions in pairs(perfutil.old_hooks) do
			for id, func in pairs(functions) do
				hook.Add(event_name, id, func)
			end
		end

		perfutil.old_hooks = {}
	end
end


do
	perfutil.old_gamemode = perfutil.old_gamemode or {}

	function perfutil.DisableGamemode()
		for key, val in pairs(GAMEMODE) do
			if type(val) == "function" then
				perfutil.old_gamemode[key] = perfutil.old_gamemode[key] or val
				GAMEMODE[key] = function() end
			end
		end
	end

	function perfutil.EnableGamemode()
		for key, val in pairs(perfutil.old_gamemode) do
			if type(val) == "function" then
				GAMEMODE[key] = val
			end
		end

		perfutil.old_gamemode = {}
	end
end

function perfutil.SetEngineEvents(b)
	if b then
		perfutil.EnableGamemode()
		perfutil.EnableHooks()
	else
		perfutil.DisableGamemode()
		perfutil.DisableHooks()
	end
end

do
	local b = true
	concommand.Add("perfutil_toggle_engine_events", function()
		b = not b
		perfutil.SetEngineEvents(b)
	end)
end

function perfutil.CRacer()
	if not C_INJECTED then
		local TIME = util.TimerCycle
		local select = select
		local type = type
		local unpack = unpack
		local getinfo = debug.getinfo
		local tostring = tostring
		local pairs = pairs
		local print = print
		local _R = debug.getregistry()

		local calls = {}

		_G.C_CALLS = calls

		local function pack(...)
			return select("#", ...), {...}
		end

		local done = {
			[package] = true,
			[_G] = true,
			[module] = true,
			[require] = true,
			[include] = true,
			[debug] = true,
			[AddCSLuaFile] = true,
		}

		local function inject(tbl, name, one_level)
			for key, val in pairs(tbl) do
				if type(key) == "string" then
					if type(val) == "function" then
						if not done[val] and getinfo(val).what == "C" and not tostring(val):find("function: builtin", 0, true) then
							local name = name .. "." ..  key
							if name:find("^_G.", 0, true) then
								name = name:sub(4)
							end
							local t = {count = 0, total_time = 0, name = name}
							calls[name] = t
							tbl[key] = function(...)
								t.count = t.count + 1

								TIME()
								local count, ret = pack(val(...))
								local diff = TIME()
								t.total_time = t.total_time + diff

								return unpack(ret, 1, count)
							end
						end
					elseif not one_level and type(val) == "table" and not done[val] then
						done[val] = true
						if not tonumber(key) then
							inject(val, name .. "." .. key)
						end
					end
				end
			end
		end

		for k,v in pairs(_R) do
			if type(v) == "table" and v.MetaName then
				inject(v, v.MetaName, true)
			end
		end
		inject(_G, "_G")
		C_INJECTED = true
	end

	function DUMP_C_CALLS(no_print, limit)
		limit = limit or 0
		local temp = {}
		for k,v in pairs(C_CALLS) do
			if v.total_time > limit then
				table.insert(temp, v)
			end
		end
		table.sort(temp, function(a, b) return a.total_time > b.total_time end)

		if no_print then return temp end
		local total = 0
		for _, v in ipairs(temp) do
			local time = v.total_time/1000
			print(v.name .. " = " .. time)
			total = total + time
		end
		print("total time: " .. total .. " seconds")
	end

	DUMP_C_CALLS()

	for k,v in pairs(C_CALLS) do
		v.total_time = 0
		v.count = 0
	end

	local next_call = 0
	local stats

	surface.CreateFont( "cracer", {
		font = "coolvetica",
		--extended = false,
		size = 20,
		--weight = 500,
		--blursize = 0,
		--scanlines = 0,
		--antialias = true,
		--underline = false,
		--italic = false,
		--strikeout = false,
		--symbol = false,
		--rotary = false,
		shadow = true,
		--additive = false,
		outline = true,
	})

	hook.Add("HUDPaint", "cracer", function()
		if next_call < RealTime() then
			next_call = RealTime() + 1
			stats = DUMP_C_CALLS(true, 0.5)
		end

		if stats then
			surface.SetFont("cracer")
			surface.SetTextColor(255, 255, 255, 255)
			local _, h = surface.GetTextSize("|")
			for i = 1, 50 do
				local v = stats[i]
				if not v then break end
				surface.SetTextPos(5, 5 + (i * h))
				surface.DrawText(v.name .. " = " .. math.Round(v.total_time/1000, 4))
			end
		end
	end)
end

_G.perfutil = perfutil