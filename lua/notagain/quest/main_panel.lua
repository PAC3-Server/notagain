if CLIENT then
	local tag = "QuestGUI"

	surface.CreateFont(tag .. "Title", {
		font = "Roboto Bk",
		size = 26,
		weight = 800
	})
	surface.CreateFont(tag .. "Desc", {
		font = "Roboto",
		size = 20,
		weight = 500
	})

	local shadowDist = 3
	local WordWrap = function(str, maxW)
		local strSep = str:Split(" ")
		local buf = ""
		local wBuf = 0
		for k, word in next, strSep do
			local txtW, txtH = surface.GetTextSize(word .. (k == #strSep and "" or " "))
			wBuf = wBuf + txtW
			if wBuf > maxW then
				buf = buf .. "\n"
				wBuf = 0
			end
			buf = buf .. word .. " "
		end

		return buf
	end

	local animTime = 3

	local PANEL = {
		Width = 500,
		Height = 300,
		OnGoing = false,
		Init = function(self)
			self:SetPos(0, 0)
			self:SetSize(0, 0)

			self.Alpha = 0
			self:NoClipping(false)

			self.Buttons = vgui.Create("EditablePanel", self)
			self.Buttons:Dock(BOTTOM)
			self.Buttons:SetTall(48)

			self.Confirm = vgui.Create("DButton", self.Buttons)
			self.Confirm:Dock(LEFT)
			self.Confirm:SetFont(tag .. "Title")
			self.Confirm:SetText("Accept")
			self.Confirm.Paint = function(s, w, h)
				if s:IsHovered() then
					surface.SetDrawColor(188, 57, 240)
					surface.DrawOutlinedRect(5,5,w-10,h-10)
					surface.SetDrawColor(188, 57, 240,20)
					surface.DrawRect(5,5,w-10,h-10)
					s:SetTextColor(Color(188, 57, 240))
				else
					s:SetTextColor(Color(100, 100, 100, 250))
				end
			end

			self.Confirm.DoClick = function()
				net.Start("QuestAddPlayer")
				net.SendToServer()
				self:Close()
				Quest.ShowDialog({"Good luck!\nCome back when you are done."})
			end

			self.Cancel = vgui.Create("DButton", self.Buttons)
			self.Cancel:Dock(RIGHT)
			self.Cancel:SetFont(tag .. "Title")
			self.Cancel:SetText("Bye")
			self.Cancel.DoClick = function()
				self:Close()
			end

			self.Cancel.Paint = function(s, w, h)
				if s:IsHovered() then
					surface.SetDrawColor(188, 57, 240)
					surface.DrawOutlinedRect(5,5,w-10,h-10)
					surface.SetDrawColor(188, 57, 250,20)
					surface.DrawRect(5,5,w-10,h-10)
					s:SetTextColor(Color(188, 57, 240))
				else
					s:SetTextColor(Color(100, 100, 100, 250))
				end
			end

			self.Tasks = {}
		end,
		PerformLayout = function(self)
			self.Confirm:SetWide(self:GetWide() * 0.5)
			self.Cancel:SetWide(self:GetWide() * 0.5)
		end,
		Paint = function(self,w,h)
			if not IsValid(self.NPC) then return end

			local eyes = self.NPC:LookupAttachment("eyes")
			if not eyes then self:Remove() return end

			eyes = self.NPC:GetAttachment(eyes)
			if not LocalPlayer():IsLineOfSightClear(eyes.Pos) then self:Close() end
			if LocalPlayer():GetPos():Distance(eyes.Pos) > 164 then self:Close() end

			DisableClipping(true)
			surface.DisableClipping(true)
			draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 200))
			surface.SetDrawColor(100,100,100,200)
			surface.DrawOutlinedRect(0,0,w,h)

			-- local x, y = self:GetPos()
			local triW, triH = 24, 16
			local tri = {
				{
					x = w + 5,
					y = h * 0.5 - triH * 0.5
				},
				{
					x = w + triW + 5,
					y = h * 0.5
				},
				{
					x = w + 5,
					y = h * 0.5 + triH * 0.5
				}
			}

			draw.NoTexture()
			surface.SetDrawColor(0,0,0,200)
			surface.DrawPoly(tri)
			surface.SetDrawColor(100, 100, 100, 200)
			surface.DrawLine(tri[1].x,tri[1].y,tri[2].x,tri[2].y)
			surface.DrawLine(tri[2].x,tri[2].y,tri[3].x,tri[3].y)
			surface.DrawLine(tri[3].x,tri[3].y,tri[1].x,tri[1].y)

			surface.DisableClipping(false)
			DisableClipping(false)

			local x, y = 8, 12

			surface.SetFont(tag .. "Title")
			local txt = WordWrap(self.Quest, self:GetWide() - x * 2)
			local txtW, txtH = surface.GetTextSize(txt)
			draw.DrawText(txt, tag .. "Title", x, y, Color(242, 150, 58))

			y = y + txtH + 8
			surface.SetFont(tag .. "Desc")
			local txt = WordWrap(self.Description, self:GetWide() - x * 2)
			local txtW, txtH = surface.GetTextSize(txt)
			draw.DrawText(txt, tag .. "Desc", x, y, Color(225, 225, 225, 255))

			-- ✔
			-- ✘
			y = y + txtH + 12
			x = x + 4
			for _, task in next, self.Tasks do
				local txt
				if task.IsFinished then
					txt = "✓"
					surface.SetTextColor(200, 200, 200, 225)
				else
					if task.OnGoing then
						txt = "➙"
						surface.SetTextColor(255, 90, 0, 225)
					else
						txt = "..."
						surface.SetTextColor(200, 200, 200, 225)
					end
				end
				surface.SetTextPos(x, y)
				surface.SetFont(tag .. "Desc")
				surface.DrawText(txt)

				x = x + 16 + 4
				surface.SetFont(tag .. "Desc")
				local txt = WordWrap(task.Name, self:GetWide() - x * 2)
				local txtW, txtH = surface.GetTextSize(txt)
				draw.DrawText(txt, tag .. "Desc", x, y, Color(225, 225, 225, 225))
				x = x - 16 - 4
				y = y + txtH + 4
			end
		end,
		Think = function(self)
			if not IsValid(self.NPC) then return end

			-- Reinventing the wheel because garry animations suck dick
			if self.Opening and not self.Closing then
				self:SetWide(Lerp(FrameTime() * animTime, self:GetWide(), self.Width))
				self:SetTall(Lerp(FrameTime() * animTime, self:GetTall(), self.Height))
				self.Alpha = Lerp(FrameTime() * animTime, self.Alpha, 1)
			elseif self.Closing then
				self:SetWide(Lerp(FrameTime() * animTime, self:GetWide(), 0))
				self:SetTall(Lerp(FrameTime() * animTime, self:GetTall(), 0))
				self.Alpha = Lerp(FrameTime() * animTime, self.Alpha, 0)

				if self.Alpha < 0.05 then
					self:Remove()
				end
			end

			local eyes = self.NPC:LookupAttachment("eyes")
			if not eyes then return end

			eyes = self.NPC:GetAttachment(eyes)
			local pos = eyes.Pos - eyes.Ang:Right() * -10
			local scrPos = pos:ToScreen()
			local x, y = scrPos.x, scrPos.y
			x = x - self:GetWide() - 16
			y = y - self:GetTall() * 0.5

			self:SetPos(x, y)
		end,
		Setup = function(self,npc,quest,desc,tasks,ongoing)
			print(ongoing)
			self.NPC = npc
			self.Quest = quest
			self.Description = desc
			self.Tasks = tasks
			self.OnGoing = ongoing
			if self.OnGoing then
				self.Confirm:Hide()
				self.Cancel:SetText("Ok")
			end
			self:Open()
		end,
		Open = function(self)
			-- self:MakePopup()
			gui.EnableScreenClicker(true)
			self:SetKeyboardInputEnabled(true)
			self:SetMouseInputEnabled(true)
			self.Opening = true
		end,
		Close = function(self)
			gui.EnableScreenClicker(false)
			self:SetKeyboardInputEnabled(false)
			self:SetMouseInputEnabled(false)
			self.Closing = true
		end,
	}

	vgui.Register("QuestMainPanel", PANEL, "EditablePanel")
end

if SERVER then
	util.AddNetworkString("QuestAddPlayer")

	net.Receive("QuestAddPlayer",function(_,ply)
		if Quest then
			Quest.ActiveQuest:AddPlayer(ply)
		end
	end)
end