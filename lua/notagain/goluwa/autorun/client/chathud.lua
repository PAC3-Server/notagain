local goluwa = requirex("goluwa")

chathud = chathud or {}

chathud.panel = chathud.panel or NULL

chathud.default_font = {
	font = "Roboto-Black.ttf",
	size = 18,
	weight = 600,
	blur_size = 3,
	background_color = Color(0,0,0,255),--Color(25,50,100,255),
	blur_overdraw = 3,
}

chathud.font_modifiers = {
	["...."] = {
		size = 8,
	},
	["!!!!"] = {
		size = 30,
	},
	["!!!!!11"] = {
		size = 40,
	},
}

for _, font in pairs(chathud.font_modifiers) do
	for k,v in pairs(chathud.default_font) do
		font[k] = font[k] or v
	end
end

chathud.emote_shortcuts = chathud.emote_shortcuts or {
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
			chathud.emote_shortcuts[name] = "<texture=http://cdn.steamcommunity.com/economy/emoticon/" .. name .. ">"
			i = i + 1
		end
	end)

	local markup = goluwa.gfx.CreateMarkup()

	--markup:SetEditable(true)

	chathud.panel = vgui.Create("Panel")

	chathud.panel:SetPos(25,ScrH() - 370)
	chathud.panel:SetSize(527,315)
	chathud.panel:SetMouseInputEnabled(true)

	chathud.panel.Think = function(self)
		markup:SetMaxWidth(self:GetWide())
		markup:Update()
	end
	chathud.panel.PaintX = function(_, w, h)
		markup:Draw()
	end

	hook.Add("HUDPaint", "chathud", function()
		if chathud.panel:IsVisible() then
			surface.DisableClipping(true)
			goluwa.render2d.PushMatrix(chathud.panel:GetPos())
			chathud.panel:PaintX(chathud.panel:GetSize())
			goluwa.render2d.PopMatrix()
			surface.DisableClipping(false)
		end
	end)

	do -- mouse input
		local translate_mouse = {
			[MOUSE_LEFT] = "button_1",
		}

		chathud.panel.OnMousePressed = function(_, code)
			local mouse_x, mouse_y = chathud.panel:ScreenToLocal(gui.MousePos())
			markup:OnMouseInput(translate_mouse[code], true, mouse_x, mouse_y)
			chathud.panel:MouseCapture(true)
		end

		chathud.panel.OnMouseReleased = function(_, code)
			local mouse_x, mouse_y = chathud.panel:ScreenToLocal(gui.MousePos())
			markup:OnMouseInput(translate_mouse[code], false, mouse_x, mouse_y)
			chathud.panel:MouseCapture(false)
		end

		chathud.panel.OnCursorMoved = function(_, x, y)
			markup:SetMousePosition(Vector(x, y, 0))
		end
	end

	chathud.markup = markup


	for _, v in pairs(file.Find("materials/icon16/*", "GAME")) do
		if v:EndsWith(".png") then
			chathud.emote_shortcuts[v:gsub("(%.png)$","")] = "<texture=materials/icon16/" .. v .. ",16>"
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

			-- discord emotes
			v = v:gsub("<:[%w_]+:([%d]+)>", "<texture=https://cdn.discordapp.com/emojis/%1.png,16,16>")

			v = v:gsub("<remember=(.-)>(.-)</remember>", function(key, val)
				chathud.emote_shortcuts[key] = val
			end)

			v = v:gsub("(:[%a%d]-:)", function(str)
				str = str:sub(2, -2)
				if chathud.emote_shortcuts[str] then
					return chathud.emote_shortcuts[str]
				end
			end)

			v = v:gsub("\\n", "\n")
			v = v:gsub("\\t", "\t")

			for pattern, font in pairs(chathud.font_modifiers) do
				if v:find(pattern, nil, true) then
					table.insert(args, {type = "font", val = font})
				end
			end

			table.insert(args, v)
		elseif t == "table" and IsColor(v) then
			table.insert(args, Color(v.r/255, v.g/255, v.b/255, v.a/255))
		else
			table.insert(args, v)
		end
	end

	markup:BeginLifeTime(16, 2)
		markup:AddFont(chathud.default_font)
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
    chathud_old_AddText(...)
end

hook.Add("HUDShouldDraw", "chathud", function(name)
 	if name == "CHudChat" then
		return false
	end
end)

hook.Add("ChatText", "chathud", function(index, name, text, type)
	if type == "none" then
		chathud.AddText(text)
	end
end)

if LocalPlayer():IsValid() then
	chathud.Initialize()
end
