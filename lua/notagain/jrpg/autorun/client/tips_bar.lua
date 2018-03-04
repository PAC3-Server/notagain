local gr_up_id = surface.GetTextureID("gui/gradient_up")

surface.CreateFont("hud_tips_font",{
	font = "Square721 BT",
	outline = true,
	weight = 800,
	size = 25,
	additive = false,
	extended = true,
})

if IsValid(_G.TIPS) then
    _G.TIPS:Remove()
end

local tips = {
    ScrW = ScrW(),
	LeftToSlide = 0,
	Sentences = {
		"You can open the PAC editor by pressing "..(string.upper(input.LookupBinding("+menu_context") or "C")).." and click on its icon",
		"To get in RPG mode type !rpg in chat",
		"You can get access to our discord by typing !discord in chat and use the link in your browser!",
		"Check the tasks you completed by typing !tasks #me",
		"If you want to contribute to the server check out, https://github.com/PAC3-Server",
		"Check out the full list of commands by typing !menu",
		"You can goto to someone by double clicking its status bar in the scoreboard",
		"The voicechat is not global, get close to the persons you want to talk to for them to hear you!",
	},
	CurrentSentence = 1,
	CurrentTextWidth = 0,
    Init = function(self)
		self:SetSize(self.ScrW,30)
		self:SetPos(0,0)
        self:SetZPos(-999)
    end,
	FindRandomSentence = function(self)
		local temp = math.random(1,#self.Sentences)
		if temp == self.CurrentSentence then
			self:FindRandomSentence(pre)
		else
			self.CurrentSentence = temp
		end
	end,
    Paint = function(self,w,h)
    	surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(0,0,w,h)
		surface.SetTexture(gr_up_id)
		surface.SetDrawColor(60,60,60,255)
		surface.DrawTexturedRect(0,0,w,h)
		surface.SetDrawColor(130,130,130,255)
		surface.DrawLine(0,29,w,29)

		surface.SetTextColor(200,200,200,255)
		surface.SetFont("hud_tips_font")

		if self.LeftToSlide + self.CurrentTextWidth <= 0 then
			self:FindRandomSentence()
			local text_w = (surface.GetTextSize(self.Sentences[self.CurrentSentence]))
			self.LeftToSlide = w
			self.CurrentTextWidth = text_w
		end

		self.LeftToSlide = self.LeftToSlide - FrameTime()*200

		surface.SetTextPos(self.LeftToSlide,2)
		surface.DrawText(self.Sentences[self.CurrentSentence])

	end,
    Think = function(self)
		if self.ScrW ~= ScrW() then
			self.ScrW = ScrW()
			self:Init()
		end
    end,
}

vgui.Register("tips_panel",tips,"DPanel")

local convar = CreateConVar("rpg_scoreboard_tips","1",FCVAR_ARCHIVE,"Enable or disable the tips status bar")

hook.Add("ScoreboardShow","ShowTipsPanel",function()
	if convar:GetBool() and not IsValid(_G.TIPS) then
		_G.TIPS = vgui.Create("tips_panel")
	end
end)

hook.Add("ScoreboardHide","HideTipsPanel",function()
	if convar:GetBool() and IsValid(_G.TIPS) then
		_G.TIPS:Remove()
	end
end)
