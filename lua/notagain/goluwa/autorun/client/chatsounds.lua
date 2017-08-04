local env = requirex("goluwa").env

local autocomplete_font = {
	font = "Roboto-Black.ttf",
	size = 18,
	weight = 600,
	blur_size = 3,
	background_color = Color(25,50,100,255),
	blur_overdraw = 3,
}

local hooks = {}
local function hookAdd(event, id, callback)
	hooks[event] = hooks[event] or {}
	hooks[event][id] = callback
	hook.Add(event, id, callback)
end

local function unhook()
	for event, data in pairs(hooks) do
		for id, callback in pairs(data) do
			hook.Remove(event, id)
		end
	end
end

local function rehook()
	for event, data in pairs(hooks) do
		for id, callback in pairs(data) do
			hook.Add(event, id, callback)
		end
	end
end

local chatsounds_enabled = CreateClientConVar("chatsounds_enabled", "1", true, false, "Disable chatsounds")

cvars.AddChangeCallback("chatsounds_enabled", function(convar_name, value_old, value_new)
	if value_new ~= '0' then
		rehook()
	else
		unhook()
	end
end)

do
	local found_autocomplete
	local random_mode = false

	local function query(str, scroll)
		found_autocomplete = env.autocomplete.Query("chatsounds", str, scroll)
	end

	hookAdd("OnChatTab", "chatsounds_autocomplete", function(str)
		if str == "random" or random_mode then
			random_mode = true
			query("", 0)
			return found_autocomplete[1]
		end

		query(str, (input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) or input.IsKeyDown(KEY_LCONTROL)) and -1 or 1)

		if found_autocomplete[1] then
			return found_autocomplete[1]
		end
	end)

	hookAdd("ChatTextChanged", "chatsounds_autocomplete", function(str)
		random_mode = false
		query(str, 0)

		hookAdd("PostRenderVGUI", "chatsounds_autocomplete", function()
			if found_autocomplete and #found_autocomplete > 0 then
				local x, y = chat.GetChatBoxPos()
				local w, h = chat.GetChatBoxSize()
				env.gfx.SetFont(autocomplete_font)
				env.autocomplete.DrawFound("chatsounds", x, y + h, found_autocomplete)
			end
		end)
	end)

	hookAdd("FinishChat", "chatsounds_autocomplete", function()
		hook.Remove("PostRenderVGUI", "chatsounds_autocomplete")
	end)
end

local blacklist = {
	[220] = true, -- hl2
	[320] = true, -- hl2 death match
	[360] = true, -- hl1 death match
	[340] = true, -- hl2 lost coast
}

local init = false
local doit = function(ply, str)
	if not init then

		env.resource.AddProvider("https://github.com/PAC3-Server/chatsounds/raw/master/")

		env.chatsounds.Initialize()

		env.chatsounds.LoadListFromAppID(220) -- hl2

		for i, info in ipairs(engine.GetGames()) do
			if info.mounted and not blacklist[info.depot] then
				env.chatsounds.LoadListFromAppID(info.depot)
			end
		end

		env.chatsounds.BuildFromGithub("PAC3-Server/chatsounds")

		init = true
	end

	if str == "sh" or (str:find("sh%s") and not str:find("%Ssh")) or (str:find("%ssh") and not str:find("sh%S")) then
		env.audio.Panic()
	end

	env.audio.player_object = ply
	env.chatsounds.Say(str, math.Round(CurTime()))
end

hookAdd("OnPlayerChat", "chatsounds",doit)
concommand.Add("saysound",doit) --LEGACY

if not chatsounds_enabled:GetBool() then
	timer.Simple(0.05, function()
		unhook()
	end)
end
