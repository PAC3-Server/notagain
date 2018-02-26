local luadev = requirex("luadev")
local utf8 = requirex("utf8")

local chatbox = _G.chatbox or {}

chatbox.frame = chatbox.frame or NULL

local settings = {
	{
		cvar = "default_position",
		name = "default chatbox position",
		default = true,
	},
	{
		cvar = "chathud_follow",
		name = "chathud follows chatbox",
		default = true,
	},
	{
		cvar = "show_close_button",
		name = "show close button",
		default = false,
		callback = function(b)
			chatbox.frame.close_btn:SetVisible(b)
		end,
	},
	{
		cvar = "font_size",
		name = "size",
		default = 15,
		callback = function()
			chatbox.richtext:SetFontInternal(chatbox.GetFont())
		end,
	},
	{
		cvar = "font_name",
		name = "font",
		default = "roboto regular",
		choices = surface.GetFonts and surface.GetFonts() or {"roboto regular"},
		callback = function()
			chatbox.richtext:SetFontInternal(chatbox.GetFont())
		end,
	}
}

local cvars = {}

for i, v in ipairs(settings) do
	local key = "chatbox_" .. v.cvar
	local def = v.default
	if type(def) == "boolean" then
		def = def and "1" or "0"
	else
		def = tostring(def)
	end
	cvars[v.cvar] = CreateClientConVar(key, def, true)
	if v.callback then
		_G.cvars.RemoveChangeCallback(key, key)
		_G.cvars.AddChangeCallback(key, function(_,_,val)
			if type(v.default) == "boolean" then
				v.callback(tobool(val))
			elseif type(v.default) == "number" then
				v.callback(tonumber(val))
			else
				v.callback(val)
			end
		end, key)
	end
end

chatbox.cvars = cvars

if IsValid(chatbox.frame) then
	chatbox.old_state = {
		input_text = chatbox.text_input:GetText(),
		input_caret_pos = chatbox.text_input:GetCaretPos(),
		richtext_history = chatbox.addtext_history,
		opened = chatbox.frame:IsVisible(),
	}
	chatbox.frame:Remove()
end

function chatbox.Open()

	if IsValid(chatbox.frame) then
		if not chatbox.frame:IsVisible() then
			chatbox.frame:SetVisible(true)
			chatbox.text_input:RequestFocus()
			chatbox.frame:SwitchToName("chat")
			chatbox.richtext:GotoTextEnd()
		end
		return
	end

	local frame = vgui.Create("ChatboxFrame")
	chatbox.frame = frame

	local x,y = chat.GetChatBoxPos()
	local w,h = chat.GetChatBoxSize()

	frame:SetPos(x, y)
	frame:SetSize(w, h)

	frame:SetCookieName("chatbox")

	frame.OnClose = function()
		chat.Close()
	end

	frame.OnActiveTabChanged = function(self, old, new)
		if new:GetText() == "chat" then
			chatbox.text_input:RequestFocus()
			chatbox.richtext:GotoTextEnd()
		end
	end

	do -- chat
		local chat = frame:Add("Panel")

		local bottom = chat:Add("Panel")
		bottom:Dock(BOTTOM)
		bottom:SetTall(16)

		local text_input = bottom:Add("ChatboxTextEntry")
		text_input:Dock(FILL)
		chatbox.text_input = text_input

		if chatbox.old_state then
			text_input:SetText(chatbox.old_state.input_text)
			text_input:SetCaretPos(chatbox.old_state.input_caret_pos)
		end

		do -- stickers
			local container = bottom:Add("Panel")
			container:Dock(RIGHT)
			container:SetSize(20, 20)

			local stickers = container:Add("DImageButton")
			stickers:SetImage("icon16/emoticon_smile.png")
			stickers:SizeToContents()

			container.PerformLayout = function() stickers:Center() end

			stickers.DoClick = function()
				vgui.Create("ChatboxStickerBrowser")
			end

		end

		text_input:Dock(BOTTOM)
		text_input.OnEnter = function(_, str)
			_G.chat.SayServer(str)
		end

		local tab = frame:AddSheet("chat", chat)
		tab.focus_me = text_input
		chatbox.chat_tab = tab
		chatbox.chat_panel = chat

		local richtext = chat:Add("RichText")
		richtext.ActionSignal = function(self, name, value)
			if name == "TextClicked" then
				gui.OpenURL(value)
			end
		end
		richtext:Dock(FILL)
		chatbox.richtext = richtext

		if chatbox.old_state then
			for i,v in ipairs(chatbox.old_state.richtext_history) do
				chatbox.restoring = true
				chatbox.AddText(unpack(v))
				chatbox.restoring = nil
			end
			timer.Simple(0, function()
				chatbox.richtext:GotoTextEnd()
			end)
		end
	end

	do -- lua tab
		local lua = frame:Add("ChatboxLuaTab")
		chatbox.lua_panel = lua
		local tab = frame:AddSheet( "lua", lua)
		tab.focus_me = lua
	end

	do -- settings tab
		local scroll = frame:Add("DScrollPanel")

		local pnl = scroll:Add("DForm")
		pnl:Dock(FILL)

		pnl:SetName("settings")

		for i,v in ipairs(settings) do
			if v.choices then
				local box = pnl:ComboBox("font", "chatbox_" .. v.cvar)
				for _, font_name in ipairs(v.choices) do
					box:AddChoice(font_name)
				end
			elseif type(v.default) == "number" then
				pnl:NumSlider(v.name, "chatbox_" .. v.cvar, 1, 30, 0)
			else
				pnl:CheckBox(v.name, "chatbox_" .. v.cvar)
			end
		end

		pnl:Help("")

		pnl:Rebuild()

		local tab = frame:AddSheet( "settings", scroll)
		tab.focus_me = scroll
	end

	frame:MakePopup()
	frame:SetFocusTopLevel(true)
	chatbox.text_input:RequestFocus()

	chatbox.old_state = nil
end

function chatbox.Close()
	chatbox.frame:SetVisible(false)
	chatbox.text_input:Clear()
end

function chatbox.GetFont()
	if
		not chatbox.font or
		chatbox.font_size ~= chatbox.cvars.font_size:GetInt() or
		chatbox.font_name ~= chatbox.cvars.font_name:GetString()
	then
		surface.CreateFont("chatbox_font", {
			font = chatbox.cvars.font_name:GetString(),
			size = chatbox.cvars.font_size:GetInt(),
			antialias = true,
			extended = true,
		})
	end
	return "chatbox_font"
end

chatbox.addtext_history = {}

function chatbox.AddText(...)
	local args = {...}

	table.insert(chatbox.addtext_history, args)

	chatbox.richtext:SetFontInternal(chatbox.GetFont())

	for _, arg in ipairs(args) do
		if type(arg) == "table" and arg.r and arg.g and arg.b and arg.a then
			chatbox.richtext:InsertColorChange(arg.r, arg.g, arg.b, arg.a)
		elseif type(arg) == "Player" and arg:IsValid() then
			local c = team.GetColor(arg:Team())
			chatbox.richtext:InsertColorChange(c.r, c.g, c.b, c.a)
			chatbox.richtext:AppendText(arg:Nick())
			chatbox.richtext:InsertColorChange(255, 255, 255, 255)
		else
			local str = tostring(arg)
			if str:find("://", nil, true) then
				for i,v in ipairs(str:Split(" ")) do
					if v:find("://", nil, true) then
						chatbox.richtext:InsertClickableTextStart(v)
						chatbox.richtext:AppendText(v)
						chatbox.richtext:InsertClickableTextEnd()
					else
						chatbox.richtext:AppendText(v)
					end
					chatbox.richtext:AppendText(" ")
				end
			else
				chatbox.richtext:AppendText(str)
			end
		end
	end

	if chatbox.restoring then return end

	chatbox.richtext:AppendText("\n")

	table.insert(args, "\n")

	return hook.Run("ChatHUDAddText", args)
end

hook.Add("ChatOpenChatBox", "chatbox", function()
	local ok = xpcall(function() chatbox.Open() end, ErrorNoHalt)
	if ok then
		return false
	end
	if IsValid(chatbox.frame) then
		chatbox.frame:Remove()
	end
end)

hook.Add("ChatCloseChatBox", "chatbox", function()
	xpcall(function() chatbox.Close() end, ErrorNoHalt)
	--return false
end)

hook.Add("ChatGetChatBoxPos", "chatbox", function()
	if not chatbox.cvars.default_position:GetBool() and chatbox.frame:IsValid() then
		return chatbox.frame:GetPos()
	end
end)

hook.Add("ChatGetChatBoxSize", "chatbox", function()
	if not chatbox.cvars.default_position:GetBool() and chatbox.frame:IsValid() then
		return chatbox.frame:GetSize()
	end
end)

hook.Add("ChatAddText", "chatbox", function(...)
	if not chatbox.frame:IsValid() then
		chatbox.Open()
		chatbox.Close()
	end

	return chatbox.AddText(...)
end)

hook.Add("ChatText", "chatbox", function(index, name, text, type)
	chatbox.AddText(text)
end)

do -- panels
	do
		local PANEL = {}
		PANEL.Code = ""
		PANEL.LastAction = {
			Script = "",
			Type   = "",
			Time   = "",
		}

		function PANEL:Init()
			local frame = self

			self.MenuExec = self:Add("DMenuBar")
			self.MenuExec:Dock(NODOCK)
			self.MenuExec:DockPadding(5,0,0,0)
			self.MenuExec.Think = function(self)
				self:SetSize(frame:GetWide(),25)
			end

			self:AddExecButton("clients", "icon16/user.png",function()
				luadev.RunOnClients(self.Code,LocalPlayer())
				self:RegisterAction(self.Code,"clients")
			end,50,60)

			self:AddExecButton("self", "icon16/cog_go.png", function()
				luadev.RunOnSelf(self.Code,LocalPlayer())
				self:RegisterAction(self.Code,"self")
			end,40,50)

			self:AddExecButton("shared","icon16/world.png", function()
				luadev.RunOnShared(self.Code,LocalPlayer())
				self:RegisterAction(self.Code,"shared")
			end,52,40)

			self:AddExecButton("server","icon16/server.png", function()
				luadev.RunOnServer(self.Code,LocalPlayer())
				self:RegisterAction(self.Code,"server")
			end,40,20)

			self.HTMLIDE = self:Add("DHTML")
			self.HTMLIDE:SetPos(0,25)
			self.HTMLIDE:AddFunction("gmodinterface","OnReady",function()
				self.HTMLIDE:Call('SetContent("' .. string.JavascriptSafe(self.Code) .. '");')
			end)
			self.HTMLIDE:AddFunction("gmodinterface","OnCode",function(code)
				self.Code = code
			end)

			self.HTMLIDE.Think = function(self)
				self:SetSize(frame:GetWide(),frame:GetTall()-50)
			end
			self.HTMLIDE:OpenURL("metastruct.github.io/lua_editor/")

			self.LblRunStatus = self:Add("DLabel")
			self.LblRunStatus:Dock(BOTTOM)
			self.LblRunStatus:SetSize(self:GetWide(),25)
			self.LblRunStatus.Think = function(self)
				self:SetText(frame.LastAction.Script ~= "" and (((" "):rep(3)).."["..frame.LastAction.Time.."] Ran "..frame.LastAction.Script.." on "..frame.LastAction.Type) or "")
			end
		end

		function PANEL:RegisterAction(script,type)
			self.LastAction = {
				Script = (string.gsub(string.Explode(" ",script)[1],"\n","")).."...",
				Type = type,
				Time = os.date("%H:%M:%S"),
			}
		end

		function PANEL:AddExecButton(name,ico,callback,size,insert)
			self.MenuExec[name] = self.MenuExec:Add("DButton")
			local frame = self
			local btn = self.MenuExec[name]
			btn:SetText(name)
			btn:SetIcon(ico)
			btn:Dock(LEFT)
			btn:SetSize(32+(size or 0),self.MenuExec:GetTall())
			btn:SetTextInset(btn.m_Image:GetWide() + (insert or 0),0)
			btn:SetPaintBackground(false)
			btn.DoClick = function(self)
				if string.TrimLeft(frame.Code) == "" then return end
				callback()
			end
		end

		vgui.Register("ChatboxLuaTab", PANEL, "DPanel")
	end

	do -- sticker browser
		local env
		local dir = "chatbox_stickers"

		local PANEL = {}

		function PANEL:Init()
			env = requirex("goluwa").env -- hmm

			file.CreateDir(dir)
			dir = dir .. "/"

			self:SetTitle("stickers")
			self:SetSize(512, 512)
			self:Center()
			self:SetSizable(true)
			self:MakePopup()

			local content = self:Add("DPanel")
			content:Dock(FILL)

			local scroll = content:Add("DScrollPanel")
			scroll:Dock(FILL)
			self.scroll = scroll

			local bottom = content:Add("DPanel")
			bottom:SetTall(64)
			bottom:Dock(BOTTOM)

			local set_scroller = bottom:Add("DHorizontalScroller")
			set_scroller:SetTall(64)
			set_scroller:Dock(FILL)
			set_scroller.Paint = function(self, w, h)
				derma.SkinHook("Paint", "CategoryButton", self, w, h)
			end
			self.set_scroller = set_scroller

			local icons = scroll:Add("DIconLayout")
			icons:Dock(FILL)
			self.icons = icons

			self:LoadStickerSets()

			local sticker_edit = bottom:Add("DImageButton")
			sticker_edit:SetSize(64, 64)
			sticker_edit:Dock(RIGHT)
			sticker_edit:SetImage("icon64/tool.png")
			sticker_edit.DoClick = function()
				local frame = vgui.Create("DFrame")
				frame:SetSize(256, 256)
				frame:MakePopup()
				frame:Center()

				local list = frame:Add("DListView")
				list:SetMultiSelect(false)
				list:Dock(FILL)

				list:AddColumn("name")

				local selected

				list.OnRowSelected = function(_, index, pnl)
					selected = pnl:GetColumnText(1)
				end

				local function refresh()
					list:Clear()
					for _, path in ipairs((file.Find(dir .. "*", "DATA"))) do
						list:AddLine(path:sub(0, -5))
					end
					self:LoadStickerSets()
				end

				local function save_set(name, content, cb)
					if tonumber(content) then
						env.utility.DownloadLineStickers(content, function(tbl)
							local str = ""
							str = str .. tbl.icon_path .. "\n"
							for i, path in ipairs(tbl.stickers) do
								str = str .. path .. "\n"
							end
							file.Write(dir .. name .. ".txt", str)
							cb()
						end)
					else
						file.Write(dir .. name .. ".txt", content)
						cb()
					end
				end

				refresh()

				local bottom = frame:Add("Panel")
				bottom:Dock(BOTTOM)

				local add = bottom:Add("DButton")
				add:SetText("add")
				add:Dock(LEFT)
				add.DoClick = function()
					local frame = vgui.Create("DFrame")
					frame:SetSize(256, 256)
					frame:MakePopup()
					frame:Center()
					frame:SetSizable(true)

					local entry = frame:Add("DTextEntry")
					entry:SetMultiline(true)
					entry:Dock(FILL)

					local save = frame:Add("DButton")
					save:SetText("save")
					save:Dock(BOTTOM)
					save.DoClick = function()
						Derma_StringRequest(
							"File name",
							"Choose a file name",
							"",
							function(name)
								save:SetText("saving..")
								save_set(name, entry:GetText(), function()
									refresh()
									frame:Remove()
								end)
							end,
							function() end
						)
					end
				end

				local edit = bottom:Add("DButton")
				edit:SetText("edit")
				edit:Dock(LEFT)
				edit.DoClick = function()
					if not selected then return end
					local selected = selected

					local frame = vgui.Create("DFrame")
					frame:SetSize(256, 256)
					frame:MakePopup()
					frame:Center()
					frame:SetSizable(true)

					local entry = frame:Add("DTextEntry")
					entry:SetMultiline(true)
					entry:Dock(FILL)

					entry:SetText(file.Read(dir .. selected .. ".txt"))

					local save = frame:Add("DButton")
					save:SetText("save")
					save:Dock(BOTTOM)
					save.DoClick = function()
						save:SetText("saving...")
						save_set(selected, entry:GetText(), function()
							refresh()
							frame:Remove()
						end)
					end
				end

				local rem = bottom:Add("DButton")
				rem:SetText("remove")
				rem:Dock(LEFT)
				rem.DoClick = function()
					if selected then
						file.Delete(dir .. selected .. ".txt")
						refresh()
					end
				end
			end
		end

		function PANEL:LoadStickerSets()
			self.set_scroller:Clear()

			local sets = {}

			if DEFAULT_CHATBOX_STICKERS then
				for i, data in ipairs(DEFAULT_CHATBOX_STICKERS) do
					table.insert(sets, data)
				end
			end

			for _, path in ipairs((file.Find(dir .. "*", "DATA"))) do
				local name = path:sub(0, -5)
				local stickers = file.Read(dir .. path, "DATA"):Trim():Split("\n")
				local icon = table.remove(stickers, 1):Trim()
				for i,v in ipairs(stickers) do
					stickers[i] = v:Trim()
				end
				table.insert(sets, {
					name = name,
					icon = icon,
					stickers = stickers,
				})
			end

			for i, data in ipairs(sets) do
				local btn = vgui.Create("DImageButton")
				btn:SetTooltip(data.name)
				btn:SetSize(64,64)
				self.set_scroller:AddPanel(btn)

				local tex = env.render.CreateTextureFromPath(data.icon)
				btn.Paint = function()
					local x, y = btn:LocalToScreen(0,0)
					env.gfx.DrawRect(x, y, btn:GetWide(), btn:GetTall(), tex, 1,1,1,1)
				end

				btn.DoClick = function()
					self.selected_set = data.name

					self.icons:Clear()

					for _, url in ipairs(data.stickers) do
						local btn = self.icons:Add("DImageButton")

						if url:find("<", nil, true) then
							btn:SetSize(90, 90)
							local markup = env.gfx.CreateMarkup()
							markup:SetText(url, true)

							btn.Think = function()
								self.icons:InvalidateLayout()
								btn.Think = function() end
							end

							btn.PaintX = function(_, w, h)
								local x, y = btn:LocalToScreen(0, 0)

								markup:SetMaxWidth(1000)
								markup:Update()

								surface.DisableClipping(true)
								env.render2d.PushMatrix(x + w/2 - markup.width/2, y + h/2 - markup.height/2)
									markup:Draw()
								env.render2d.PopMatrix()
								surface.DisableClipping(false)
							end

							hook.Add("PostRenderVGUI", "goluwa_markup_draw", function()
								if not self:IsValid() or not self.icons:IsValid() then hook.Remove("PostRenderVGUI", "goluwa_markup_draw") return end
								for i,v in ipairs(self.icons:GetChildren()) do
									if v.PaintX then
										v:PaintX(v:GetSize())
									end
								end
							end)

							btn.DoClick = function()
								_G.chat.SayServer(url)
								chatbox.Close()
								self:Remove()
							end

							btn:Paint(btn:GetSize())
						else
							local tex = env.render.CreateTextureFromPath(url)

							btn.Paint = function()
								local x, y = btn:LocalToScreen(0,0)
								env.gfx.DrawRect(x, y, btn:GetWide(), btn:GetTall(), tex, 1,1,1,1)
							end

							btn.Think = function()
								local size = tex:GetSize()
								if btn.last_size ~= size then
									local ratio = size.x/size.y

									btn:SetSize(90 * ratio, 90)
									self.icons:InvalidateLayout(true)

									btn.last_size = size
								end
							end

							btn.DoClick = function()
								_G.chat.SayServer("<texture=" ..  url .. ">")
								chatbox.Close()
								self:Remove()
							end
						end
					end

					-- i give up, it doesn't layout the icons properly
					self:SetWide(self:GetWide()+1)
					timer.Simple(0, function() self:SetWide(self:GetWide()-1) end)
				end

				if (not self.selected_set and i == 1) or self.selected_set == data.name then
					btn:DoClick()
				end
			end
		end

		vgui.Register("ChatboxStickerBrowser", PANEL, "DFrame")
	end

	do
		local PANEL = {}

		-- DFrame behavior
		AccessorFunc( PANEL, "m_bScreenLock", "ScreenLock", FORCE_BOOL )
		AccessorFunc( PANEL, "m_bSizable", "Sizable", FORCE_BOOL )
		AccessorFunc( PANEL, "m_iMinWidth",	"MinWidth", FORCE_NUMBER )
		AccessorFunc( PANEL, "m_iMinHeight", "MinHeight", FORCE_NUMBER )
		AccessorFunc( PANEL, "m_bDraggable", "Draggable", FORCE_BOOL )

		function PANEL:OnMousePressed(...)
			return DFrame.OnMousePressed(self, ...)
		end

		function PANEL:OnMouseReleased(...)
			return DFrame.OnMouseReleased(self, ...)
		end

		function PANEL:Think()
			if chatbox.chat_panel:HasHierarchicalFocus() then
				for i = KEY_0, KEY_Z do
					if input.IsKeyDown(i) then
						chatbox.text_input:RequestFocus()
						break
					end
				end

				if input.IsKeyDown(KEY_ENTER) then
					chatbox.text_input:RequestFocus()
				end
			end

			if chatbox.lua_panel:HasHierarchicalFocus() then
				for i = KEY_0, KEY_Z do
					if input.IsKeyDown(i) then
						chatbox.lua_panel.HTMLIDE:RequestFocus()
						break
					end
				end

				if input.IsKeyDown(KEY_ENTER) then
					chatbox.lua_panel.HTMLIDE:RequestFocus()
				end
			end

			if self:HasHierarchicalFocus() then
				if input.IsKeyDown(KEY_ESCAPE) then
					self:OnClose()
				end
			end

			if cvars.default_position:GetBool() then
				local x,y = chat.GetChatBoxPos()
				local w,h = chat.GetChatBoxSize()

				self:SetPos(x, y)
				self:SetSize(w, h)

				return
			end

			DFrame.Think(self)

			local x,y = self:GetPos()
			if x ~= self.last_x then self.last_x = x self:SetCookie("x", x) end
			if y ~= self.last_y then self.last_y = y self:SetCookie("y", y) end

			local w,h = self:GetSize()
			if w ~= self.last_w then self.last_w = w self:SetCookie("w", w) end
			if h ~= self.last_h then self.last_h = h self:SetCookie("h", h) end
		end

		function PANEL:Init()
			self.tabScroller:Dock(NODOCK)

			self.tabScroller.PerformLayout = function(...)
				DHorizontalScroller.PerformLayout(...)
				local w = 0
				for _, v in ipairs(self.tabScroller.Panels) do
					w = w + v:GetWide()
				end
				self.tabScroller:SetWide(w)
			end

			self:SetMinHeight(50)
			self:SetMinWidth(50)
			self:SetSizable(true)
			self:SetDraggable(true)
			self:SetScreenLock(true)
			self:SetFocusTopLevel( true )

			do -- close button
				local btn = vgui.Create( "DButton", self )
				btn:SetText( "" )
				btn.DoClick = function ( button )
					self:OnClose()
				end
				btn.Paint = function( panel, w, h )
					derma.SkinHook( "Paint", "WindowCloseButton", panel, w, h )
				end
				btn:SetVisible(cvars.show_close_button:GetBool())
				self.close_btn = btn
			end
		end

		function PANEL:LoadCookies()
			local x,y = self:GetPos()
			local w,h = self:GetSize()

			y = self:GetCookieNumber("x", x)
			x = self:GetCookieNumber("y", y)
			w = self:GetCookieNumber("w", w)
			h = self:GetCookieNumber("h", h)

			x = math.Clamp(x, 0, ScrW() - w)
			y = math.Clamp(y, 0, ScrH() - h)

			w = math.Clamp(w, self.m_iMinWidth, ScrW())
			h = math.Clamp(h, self.m_iMinHeight, ScrH())

			self:SetPos(x, y)
			self:SetSize(w, h)
		end

		function PANEL:PerformLayout()
			self.close_btn:SetPos( self:GetWide() - self.close_btn:GetWide(), 0 )
			self.close_btn:SetSize( 31, 24 )

			DPropertySheet.PerformLayout(self)
		end

		function PANEL:OnClose()

		end

		timer.Simple(0, function()
			-- this is so stupid, but it's so DTextEntry can gain focus
			derma.DefineControl( "DPropertySheet_ChatboxFrame", "", DPropertySheet, "EditablePanel" )
			vgui.Register("ChatboxFrame", PANEL, "DPropertySheet_ChatboxFrame")
		end)
	end

	do
		local PANEL = {}

		function PANEL:Init()
			self:SetUpdateOnType(true)
			self:SetAllowNonAsciiCharacters(true)
			self:SetMultiline(true)
			self.initial_height = self:GetTall()

			self.history = {}
		end

		function PANEL:Clear()
			self:SetText("")
			self:SetTall(self.initial_height)
			self:SetMultiline(false)
		end

		function PANEL:OnValueChange(text)
			if text == "" then self.history_i = 1 end
			if not text:find("\n", nil, true) then
				self:SetMultiline(false)
				self:SetTall(self.initial_height)
				self:GetParent():SetTall(self:GetTall())
			end
			_G.chat.TextChanged(text)
		end

		function PANEL:OnKeyCodeTyped(key)
			if key == KEY_BACKSPACE and input.IsControlDown() and self:GetCaretPos() > 0 then
				local str = self:GetText()

				local caret_pos = self:GetCaretPos()
				local left = utf8.sub(str, 0, caret_pos)
				local right = utf8.sub(str, caret_pos + 1)
				local char = utf8.sub(left, utf8.length(left), utf8.length(left))

				local test

				local punctation = [==[[!"#$%&'%(%)*+,-./:;<=>?@%[\%]^`{|}~%s]]==]
				local has_punctation = char:find(punctation)

				local tbl = utf8.totable(left)

				for i = #tbl, 1, -1 do
					local char = tbl[i]
					if
						(has_punctation and not char:find(punctation)) or
						(not has_punctation and char:find(punctation)) or
						i == 1
					then
						if i == 1 then
							self:SetText(right)
						else
							left = utf8.sub(left, 0, i)
							self:SetText(left .. right)
							self:SetCaretPos(#left)
						end
						break
					end
				end
			end

			if key == KEY_DELETE and input.IsControlDown() and self:GetCaretPos() < #self:GetText() then
				local str = self:GetText()

				local caret_pos = self:GetCaretPos()
				local left = utf8.sub(str, 0, caret_pos)
				local right = utf8.sub(str, caret_pos + 1)
				local char = utf8.sub(right, 1, 1)

				local punctation = [==[[!"#$%&'%(%)*+,-./:;<=>?@%[\%]^`{|}~%s]]==]
				local has_punctation = char:find(punctation)

				local tbl = utf8.totable(right)

				for i = 1, #tbl do
					local char = tbl[i]
					if
						(has_punctation and not char:find(punctation)) or
						(not has_punctation and char:find(punctation)) or
						i == #tbl
					then
						if i == #tbl then
							self:SetText(left)
							self:SetCaretPos(#left)
						else
							right = utf8.sub(right, i)
							self:SetText(left .. right)
							self:SetCaretPos(#left)
						end
						break
					end
				end
			end

			if not self:IsMultiline() and (key == KEY_UP or key == KEY_DOWN) then
				local str = self:GetText()

				if str:Trim() ~= "" and self.history[#self.history] ~= str then
					table.insert(self.history, str)
				end

				self.history_i = self.history_i or 1

				if key == KEY_UP then
					self.history_i = self.history_i - 1
				else
					self.history_i = self.history_i + 1
				end

				if self.history_i < 1 then self.history_i = #self.history end
				if self.history_i > #self.history then self.history_i = 1 end

				if self.history[self.history_i] then
					self:SetText(self.history[self.history_i])
					self:SetCaretPos(#self:GetText())
				end
			end

			if key == KEY_ENTER then
				if input.IsShiftDown() then
					surface.SetFont(self:GetFont())
					local w,h  = surface.GetTextSize(self:GetText())
					self:SetTall(self.initial_height + h)
					self:GetParent():SetTall(self:GetTall())
					self:SetMultiline(true)
					return
				end

				local str = self:GetText()

				self:OnEnter(str)

				if str:Trim() ~= "" and self.history[#self.history] ~= str then
					table.insert(self.history, str)
				end

				self.history_i = 1

				self:Clear()

				_G.chat.Close()
			end

			if key == KEY_TAB then
				if self:IsMultiline() then
					local str = self:GetText()
					local pos = self:GetCaretPos()
					self:SetText(str:sub(0, pos) .. "    " .. str:sub(pos+1))
					self:SetCaretPos(pos + 4)
					return true
				end

				local res = _G.chat.Autocomplete(self:GetText())

				if res then
					self:SetText(res)
					self:SetCaretPos(#res)
				end

				return true
			end

			if self:GetText() == "" then
				self:SetCaretPos(0)
			end
		end

		function PANEL:OnEnter(str)

		end

		vgui.Register("ChatboxTextEntry", PANEL, "DTextEntry")
	end
end

if chatbox.was_open then
	chatbox.Open()
	chatbox.was_open = nil
end

_G.chatbox = chatbox