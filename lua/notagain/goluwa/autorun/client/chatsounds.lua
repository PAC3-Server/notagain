local env = requirex("goluwa").env
local luadata = requirex("luadata")

local autocomplete_font = env.fonts.CreateFont({
	font = "Roboto Black",
	size = 18,
	weight = 600,
	blur_size = 3,
	background_color = Color(25,50,100,255),
	blur_overdraw = 3,
})

local chatsounds_enabled = CreateClientConVar("chatsounds_enabled", "1", true, false, "Disable chatsounds")

local function read(str)
	local subs = file.Read("chatsounds_subscriptions.txt", "DATA") or ""
	subs = subs:Split("\n")
	return subs
end

local default = {
	"PAC3-Server/chatsounds-valve-games/csgo",
	"PAC3-Server/chatsounds-valve-games/css",
	"PAC3-Server/chatsounds-valve-games/ep1",
	"PAC3-Server/chatsounds-valve-games/ep2",
	"PAC3-Server/chatsounds-valve-games/hl1",
	"PAC3-Server/chatsounds-valve-games/hl2",
	"PAC3-Server/chatsounds-valve-games/l4d",
	"PAC3-Server/chatsounds-valve-games/l4d2",
	"PAC3-Server/chatsounds-valve-games/portal",
	"PAC3-Server/chatsounds-valve-games/tf2",
	"Metastruct/garrysmod-chatsounds/sound/chatsounds/autoadd",
	--"PAC3-Server/chatsounds",
}

do
	local function load_custom(ply, sub)
		ply.chatsounds_custom_lists = ply.chatsounds_custom_lists or {}
		local location, directory = sub:match("^www%.github%.com%/([^/]+/[^/]+)(.*)")
		if location then
			local id = ply:UniqueID() .. "_" .. sub
			local friendly = location .. directory
			directory = directory:sub(2)
			if directory == "" then
				directory = nil
			end
			env.autocomplete.translate_list_id["chatsounds_custom_" .. id] = function()
				if ply:IsValid() then
					return ply:Nick() .. "'s " .. friendly
				end
			end
			env.chatsounds.BuildFromGithub(location, directory, id)
			if not table.HasValue(ply.chatsounds_custom_lists, id) then
				table.insert(ply.chatsounds_custom_lists, id)
			end
		end
	end

	local function unload_custom(ply, sub)
		if env.chatsounds.custom then
			local id = ply:UniqueID() .. "_" .. sub
			env.chatsounds.custom[id] = nil
		end
	end

	net.Receive("chatsounds_subscriptions_broadcast", function()
		local ply = net.ReadEntity()
		local subs = net.ReadTable()

		for _, sub in ipairs(subs) do
			load_custom(ply, sub)
		end
	end)

	local function clean(subs, str)
		for i = #subs, 1, -1 do
			if subs[i] == str or subs[i]:Trim() == "" then
				table.remove(subs, i)

				if str:StartWith("custom ") then
					unload_custom(LocalPlayer(), str:sub(#"custom " + 1))
				end
			end
		end
	end

	local function tell()
		local subs = read(str)

		local temp = {}

		for i,v in ipairs(subs) do
			if v:StartWith("custom ") then
				table.insert(temp, v:sub(#"custom " + 1))
			end
		end

		subs = temp

		if #subs == 0 then return end

		net.Start("chatsounds_subscriptions")
			net.WriteInt(#subs, 32)
			for _, line in ipairs(subs) do
				net.WriteString(line)
			end
		net.SendToServer()
	end

	local function save(subs)
		file.Write("chatsounds_subscriptions.txt", table.concat(subs, "\n"))
	end

	concommand.Add("chatsounds_subscribe", function(ply, _, _, str)
		if not str:StartWith("local ") and not str:StartWith("custom ") then
			print("a subscription must be either local or custom")
			print("example:")
			print("custom www.github.com/CapsAdmin/mylist")
			print("local www.github.com/PAC3-Server/chatsounds-valve-games/hl1")
			return
		end

		if not str:find("^%S.- www%.github%.com/") then
			print("a subscription must be on www.github.com")
			return
		end

		if str:StartWith("local ") then
			local location, directory = str:match("^local www%.github%.com%/([^/]+/[^/]+)(.*)")
			directory = directory:sub(2)
			if directory == "" then
				directory = nil
			end
			env.chatsounds.BuildFromGithub(location, directory)
		elseif str:StartWith("custom ") then
			load_custom(ply, str:sub(#"custom " + 1))
		end

		local subs = read(str)
		clean(subs, str)
		table.insert(subs, str)
		save(subs)
		tell()
	end)

	concommand.Add("chatsounds_unsubscribe", function(ply, _, _, str)
		local subs = read(str)
		clean(subs, str)
		save(subs)
	end, function(cmd, args)
		local subs = read(str)
		for i,v in ipairs(subs) do
			subs[i] = "chatsounds_unsubscribe " .. v
		end
		tell()
		return subs
	end)

	concommand.Add("chatsounds_list_subscriptions", function(ply, _, _, str)
		for _, line in ipairs((file.Read("chatsounds_subscriptions.txt", "DATA") or ""):Split("\n")) do
			print(line)
		end
	end)

	if LocalPlayer():IsValid() then
		for i, sub in ipairs(default) do
			LocalPlayer():ConCommand("chatsounds_subscribe local www.github.com/" .. sub)
		end
	end
end

do
	local found_autocomplete
	local random_mode = false

	local function query(str, scroll)

		local temp = {"chatsounds"}

		local lists = read()
		for i,v in ipairs(lists) do
			if v:StartWith("custom ") then
				table.insert(temp, "chatsounds_custom_" .. LocalPlayer():UniqueID() .. "_" .. v:sub(#"custom " + 1))
			end
		end

		found_autocomplete = env.autocomplete.Query("chatsounds", str, scroll, temp)
	end

	hook.Add("StartChat", "chatsounds_autocomplete_init", function()
		if not chatsounds_enabled:GetBool() then return end

		hook.Add("OnChatTab", "chatsounds_autocomplete", function(str)
			if str == "random" or random_mode then
				random_mode = true
				query("", 0)
				return found_autocomplete[1].val
			end

			query(str, (input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) or input.IsKeyDown(KEY_LCONTROL)) and -1 or 1)

			if found_autocomplete[1] then
				return found_autocomplete[1].val
			end
		end)

		hook.Add("ChatTextChanged", "chatsounds_autocomplete", function(str)
			if str == "" then
				random_mode = true
				return
			end

			random_mode = false
			query(str, 0)
		end)

		hook.Add("PostRenderVGUI", "chatsounds_autocomplete", function()
			if random_mode then return end
			if found_autocomplete and #found_autocomplete > 0 then
				local x, y = chat.GetChatBoxPos()
				local w, h = chat.GetChatBoxSize()
				env.gfx.SetFont(autocomplete_font)
				env.autocomplete.DrawFound("chatsounds", x, y + h, found_autocomplete)
			end
		end)
	end)

	hook.Add("FinishChat", "chatsounds_autocomplete", function()
		if not chatsounds_enabled:GetBool() then return end

		-- in some cases ChatTextChanged is called on FinishChat which adds the hook again
		timer.Simple(0, function()
			hook.Remove("PostRenderVGUI", "chatsounds_autocomplete")
			hook.Remove("ChatTextChanged", "chatsounds_autocomplete")
			hook.Remove("OnChatTab", "chatsounds_autocomplete")
		end)
	end)
end

local init = false

local function player_say(ply, str)
	if not init then
		env.chatsounds.Initialize()

		if LocalPlayer():IsValid() then
			for i, sub in ipairs(default) do
				LocalPlayer():ConCommand("chatsounds_subscribe local www.github.com/" .. sub)
			end
			LocalPlayer():ConCommand("chatsounds_subscribe custom www.github.com/PAC3-Server/chatsounds")
		end

		hook.Run("ChatsoundsInitialized")

		init = true
	end

	if str == "sh" or (str:find("sh%s") and not str:find("%Ssh")) or (str:find("%ssh") and not str:find("sh%S")) then
		env.audio.Panic()
	end

	if str:Trim():find("^<.*>$") then return end
	if str:find("^%p") then return end

	env.audio.player_object = ply

	env.chatsounds.Say(str, math.Round(CurTime()), ply.chatsounds_custom_lists)
end

hook.Add("OnPlayerChat", "chatsounds", player_say)
concommand.Add("saysound",function(ply, _,_, str)
	player_say(ply, str)
end)

if not chatsounds_enabled:GetBool() then
	hook.Remove("OnPlayerChat", "chatsounds")
end
