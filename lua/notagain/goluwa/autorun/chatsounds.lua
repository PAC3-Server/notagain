local userdata = requirex("userdata")

local cache = {}

local default_lists = {
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
	"PAC3-Server/chatsounds",
}

local function load_subscriptions(subscriptions)
    if not subscriptions then return end

    local env = requirex("goluwa").env

    for _, sub in ipairs(subscriptions) do
        local location, directory = sub:match("^(.-/.-)/(.*)$")
        location = location or sub
        directory = directory or ""

        if location then
            local friendly = location .. "/" .. directory

            env.autocomplete.translate_list_id["chatsounds_custom_" .. sub] = friendly

            local directory = directory
            if directory == "" then
                directory = nil
            end

            if not cache[sub] then
                env.chatsounds.BuildFromGithub(location, directory, sub)
                cache[sub] = true
            end
        end
    end
end

userdata.Setup("chatsounds_subscriptions", default_lists, function(ply, subscriptions)
	for _, sub in ipairs(subscriptions) do
		local location, directory = sub:match("^(.-/.-)/(.*)$")
		location = location or sub
		directory = directory or ""

		if sub:find("https://", nil, true) or sub:find("http://", nil, true) or sub:find("www.", nil, true) then
			error("invalid subscription '" .. sub .. "' all has to be on github")
		end

		if #location:Split("/") ~= 2 then
			error("invalid subscription: " .. sub)
		end
	end

    if CLIENT then
        local env = requirex("goluwa").env

        load_subscriptions(subscriptions)

        if env.chatsounds.custom then
            local found = {}

            for _, sub in ipairs(subscriptions) do
                found[sub] = true
            end

            for _, ply in ipairs(player.GetAll()) do
                if ply ~= LocalPlayer() then
                    for _, sub in ipairs(userdata.Get(ply, "chatsounds_subscriptions")) do
                        found[sub] = true
                    end
                end
            end

            for id, val in pairs(env.chatsounds.custom) do
                if not found[id] then
                    env.chatsounds.custom[id] = nil
                    cache[id] = nil
                    print("chatsounds: unloading " .. id .. " since no one is using it anymore")
                end
            end
        end
	end
end)

if CLIENT then
    concommand.Add("chatsounds_reload", function()
        cache = {}
        for _, ply in ipairs(player.GetAll()) do
            load_subscriptions(userdata.Get(ply, "chatsounds_subscriptions"))
        end
    end)

    local env = requirex("goluwa").env

    local autocomplete_font = env.fonts.CreateFont({
        font = "Roboto Black",
        size = 18,
        weight = 600,
        blur_size = 3,
        background_color = Color(25,50,100,255),
        blur_overdraw = 3,
    })

    local chatsounds_enabled = CreateClientConVar("chatsounds_enabled", "1", true, false, "Disable chatsounds")

    concommand.Add("chatsounds_subscribe", function(ply, _, _, str)
        local url = str
        local subscriptions = table.Copy(userdata.Get(LocalPlayer(), "chatsounds_subscriptions"))

        if not table.HasValue(subscriptions, str) then
            table.insert(subscriptions, str)
        end

        userdata.Set("chatsounds_subscriptions", subscriptions)
    end)

    concommand.Add("chatsounds_unsubscribe", function(ply, _, _, str)
        local url = str
        local subscriptions = table.Copy(userdata.Get(LocalPlayer(), "chatsounds_subscriptions"))

        for i,v in ipairs(subscriptions) do
            if v == str then
                table.remove(subscriptions, i)
                break
            end
        end

        userdata.Set("chatsounds_subscriptions", subscriptions)
    end)

    concommand.Add("chatsounds_list_subscriptions", function(ply, _, _, str)
        for _, line in ipairs(userdata.Get(LocalPlayer(), "chatsounds_subscriptions")) do
            print(line)
        end
    end)

    do
        local found_autocomplete
        local random_mode = false

        local function query(str, scroll)
            local subscriptions = userdata.Get(LocalPlayer(), "chatsounds_subscriptions")

            if not subscriptions then
                return
            end

            local temp = {}

            for _, sub in ipairs(subscriptions) do
                table.insert(temp, "chatsounds_custom_" .. sub)
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
            hook.Run("ChatsoundsInitialized")
            init = true
        end

        if str == "sh" or (str:find("sh%s") and not str:find("%Ssh")) or (str:find("%ssh") and not str:find("sh%S")) then
            env.audio.Panic()
        end

        if str:Trim():find("^<.*>$") then return end
        if str:find("^%p") then return end


        local ids = {}
        for _, subscription in ipairs(userdata.Get(ply, "chatsounds_subscriptions")) do
            table.insert(ids, subscription)
        end

        env.audio.player_object = ply
        env.chatsounds.Say(str, math.Round(CurTime()), ids)
    end

    hook.Add("OnPlayerChat", "chatsounds", player_say)

    concommand.Add("saysound",function(ply, _,_, str)
        player_say(ply, str)
    end)

    if not chatsounds_enabled:GetBool() then
        hook.Remove("OnPlayerChat", "chatsounds")
    end
end