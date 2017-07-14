chathud = chathud or {}
chathud.life_time = 5
chathud.panel = chathud.panel or NULL

chathud.font_modifiers = {
	["...."] = {type = "font", val = "chathud_default_small"},
	["!!!!"] = {type = "font", val = "chathud_default_large"},
	["!!!!!11"] = {type = "font", val = "chathud_default_larger"},
}

chathud.emote_shortucts = chathud.emote_shortucts or {
	smug = "<texture=masks/smug>",
	downs = "<texture=masks/downs>",
	saddowns = "<texture=masks/saddowns>",
	niggly = "<texture=masks/niggly>",
	colbert = "<texture=masks/colbert>",
	eli = "<texture=models/eli/eli_tex4z,4>",
	bubu = "<remember=bubu><color=1,0.3,0.2><texture=materials/hud/killicons/default.vtf,50>  <translate=0,-15><color=0.58,0.239,0.58><font=ChatFont>Bubu<color=1,1,1>:</translate></remember>",
	acchan = "<remember=acchan><translate=20,-35><scale=1,0.6><texture=http://www.theonswitch.com/wp-content/uploads/wow-speech-bubble-sidebar.png,64></scale></translate><scale=0.75,1><texture=http://img1.wikia.nocookie.net/__cb20110317001632/southparkfanon/images/a/ad/Kyle.png,64></scale></remember>",
}

chathud.tags = chathud.tags or {}

function chathud.Initialize()
	if chathud.panel:IsValid() then
		chathud.panel:Remove()
	end

	http.Fetch("http://cdn.steam.tools/data/emote.json", function(data)
		local i = 0
		for name in data:gmatch('"name": ":(.-):"') do
			chathud.emote_shortucts[name] = "<texture=http://cdn.steamcommunity.com/economy/emoticon/" .. name .. ">"
			i = i + 1
		end
	end)

	local markup = GoluwaMarkup()

	chathud.panel = vgui.Create("Panel")

	chathud.panel:SetPos(25,ScrH() - 370)
	chathud.panel:SetSize(527,315)

	chathud.panel.Paint = function(_, w, h)
		markup:SetMaxWidth(w)
		markup:Update()
		markup:Draw()
	end

	do -- mouse input
		local translate_mouse = {}
		for k,v in pairs(_G) do
			if isstring(k) and isnumber(v) and k:StartWith("MOUSE_") then
				translate_mouse[v] = k:lower():sub(7)
			end
		end

		local mouse_x = 0
		local mouse_y = 0

		chathud.panel.OnMousePressed = function(_, code)
			markup:OnMouseInput(translate_mouse[code], true, mouse_x, mouse_y)
		end

		chathud.panel.OnMouseReleased = function(_, code)
			markup:OnMouseInput(translate_mouse[code], false, mouse_x, mouse_y)
		end

		chathud.panel.OnCursorMoved = function(_, x, y)
			mouse_x = x
			mouse_y = y
		end
	end

	chathud.markup = markup

	surface.CreateFont("chathud_default", {
		font = "Roboto-Bold",
		size = 16,
	})

	surface.CreateFont("chathud_default_large", {
		font = "Roboto-Bold",
		size = 20,
	})

	surface.CreateFont("chathud_default_larger", {
		font = "Roboto-Bold",
		size = 30,
	})

	surface.CreateFont("chathud_default_small", {
		font = "Roboto-Bold",
		size = 8,
	})

	for _, v in pairs(file.Find("materials/icon16/*", "GAME")) do
		if v:EndsWith(".png") then
			chathud.emote_shortucts[v:gsub("(%.png)$","")] = "<texture=materials/icon16/" .. v .. ",16>"
		end
	end
end

function chathud.AddText(...)

	if not chathud.panel:IsValid() then
		chathud.Initialize()
	end

	local markup = chathud.markup

	local args = {}

	for _, v in pairs({...}) do
		local t = type(v)
		if t == "Player" then
			local c = team.GetColor(v:Team())
			table.insert(args, Color(c.r/255, c.g/255, c.b/255, c.a/255))
			table.insert(args, v:GetName())
			table.insert(args, Color(1,1,1,1))
		elseif t == "string" then

			if v == ": sh" or v == "sh" or v:find("%ssh%s") then
				markup:TagPanic()
			end

			v = v:gsub("<remember=(.-)>(.-)</remember>", function(key, val)
				chathud.emote_shortucts[key] = val
			end)

			v = v:gsub("(:[%a%d]-:)", function(str)
				str = str:sub(2, -2)
				if chathud.emote_shortucts[str] then
					return chathud.emote_shortucts[str]
				end
			end)

			v = v:gsub("\\n", "\n")
			v = v:gsub("\\t", "\t")

			for pattern, font in pairs(chathud.font_modifiers) do
				if v:find(pattern, nil, true) then
					table.insert(args, #args-1, font)
				end
			end

			table.insert(args, v)
		elseif t == "table" and IsColor(v) then
			table.insert(args, Color(v.r/255, v.g/255, v.b/255, v.a/255))
		else
			table.insert(args, v)
		end
	end

	markup:BeginLifeTime(chathud.life_time)
		-- this will make everything added here get removed after said life time
		markup:AddFont("chathud_default") -- also reset the font just in case
		markup:AddTable(args, true)
		markup:AddTagStopper()
		markup:AddString("\n")
	markup:EndLifeTime()


	for k,v in pairs(chathud.tags) do
		markup.tags[k] = v
	end
end

chathud_old_AddText = chathud_old_AddText or chat.AddText

function chat.AddText(...)
    chathud.AddText(...)
    --chathud_old_AddText(...)
end

if LocalPlayer():IsValid() then
	chathud.Initialize()
end