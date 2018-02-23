local luadev = requirex("luadev")
local utf8 = requirex("utf8")

local chatbox = _G.chatbox or {}
if CLIENT then
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
	chatbox.history = {}

	if IsValid(chatbox.frame) then
		chatbox.frame:Remove()
	end

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
			if self:HasHierarchicalFocus() and input.IsKeyDown(KEY_ESCAPE) then
				self:OnClose()
				gui.HideGameUI()
				return true
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
			local chat = vgui.Create("Panel", frame)
			local text_input = vgui.Create("DTextEntry", chat)
			chatbox.text_input = text_input
			text_input:SetUpdateOnType(true)
			text_input:SetAllowNonAsciiCharacters(true)
			text_input:SetMultiline(true)
			text_input:Dock(BOTTOM)
			local initial_height = text_input:GetTall()
			text_input.Clear = function(self)
				self:SetText("")
				self:SetTall(initial_height)
				self:SetMultiline(false)
			end
			text_input.OnValueChange = function(self, text)
				if text == "" then chatbox.history_i = 1 end
				if not text:find("\n", nil, true) then
					self:SetMultiline(false)
					self:SetTall(initial_height)
				end
				_G.chat.TextChanged(text)
			end
			text_input.OnKeyCodeTyped = function(self, key)

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

				if not text_input:IsMultiline() and (key == KEY_UP or key == KEY_DOWN) then
					local str = self:GetText()

					if str:Trim() ~= "" and chatbox.history[#chatbox.history] ~= str then
						table.insert(chatbox.history, str)
					end

					chatbox.history_i = chatbox.history_i or 1

					if key == KEY_UP then
						chatbox.history_i = chatbox.history_i - 1
					else
						chatbox.history_i = chatbox.history_i + 1
					end

					if chatbox.history_i < 1 then chatbox.history_i = #chatbox.history end
					if chatbox.history_i > #chatbox.history then chatbox.history_i = 1 end

					if chatbox.history[chatbox.history_i] then
						self:SetText(chatbox.history[chatbox.history_i])
						self:SetCaretPos(#self:GetText())
					end
				end

				if key == KEY_ENTER then
					if input.IsShiftDown() then
						surface.SetFont(self:GetFont())
						local w,h  = surface.GetTextSize(self:GetText())
						self:SetTall(initial_height + h)
						self:SetMultiline(true)
						return
					end

					local str = self:GetText()
					_G.chat.SayServer(str)

					if str:Trim() ~= "" and chatbox.history[#chatbox.history] ~= str then
						table.insert(chatbox.history, str)
					end

					chatbox.history_i = 1



					self:Clear()

					_G.chat.Close()
				end

				if key == KEY_TAB then
					if text_input:IsMultiline() then
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

				if self:GetText() == "" then self:SetCaretPos(0) end
			end

			local tab = frame:AddSheet( "chat", chat)
			tab.focus_me = text_input
			chatbox.chat_tab = tab

			local history = vgui.Create("RichText", chat)
			history.ActionSignal = function(self, name, value)
				if name == "TextClicked" then
					gui.OpenURL(value)
				end
			end
			history:Dock(FILL)
			chatbox.richtext = history
		end

		do -- lua tab
			local lua = vgui.Create( "ChatboxLuaTab", frame )
			local tab = frame:AddSheet( "lua", lua)
			tab.focus_me = lua
		end

		do -- settings tab
			local pnl = vgui.Create( "DForm", frame )
			pnl:SetSpacing(5)

			for i,v in ipairs(settings) do
				pnl:CheckBox(v.name, "chatbox_" .. v.cvar)
			end


			local tab = frame:AddSheet( "settings", pnl)
			tab.focus_me = pnl
		end

		frame:MakePopup()
		frame:SetFocusTopLevel(true)
		chatbox.text_input:RequestFocus()

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
	end

	hook.Add("ChatOpenChatBox", "chatbox", function()
		chatbox.Open()
		return false
	end)

	hook.Add("ChatCloseChatBox", "chatbox", function()
		chatbox.Close()
		--return false
	end)

	function chatbox.Close()
		chatbox.frame:SetVisible(false)
		chatbox.text_input:Clear()
	end

	function chatbox.AddText(...)
		local args = {...}
		for _, arg in ipairs(args) do
			if type(arg) == "table" and arg.r and arg.g and arg.b and arg.a then
				chatbox.richtext:InsertColorChange(arg.r, arg.g, arg.b, arg.a)
			elseif type(arg) == "Player" then
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

		chatbox.richtext:AppendText("\n")

		table.insert(args, "\n")

		return hook.Run("ChatHUDAddText", args)
	end
end

_G.chatbox = chatbox