local gr_dw_id = surface.GetTextureID("gui/gradient_down")
local gr_up_id = surface.GetTextureID("gui/gradient_up")
local gr_id    = surface.GetTextureID("gui/gradient")
local gr_ct_id = surface.GetTextureID("gui/center_gradient")

local text_color = Color(200,200,200,255)
local metal = CreateMaterial(tostring({}), "UnlitGeneric", {
	["$BaseTextureTransform"] = "center .2 0 scale .5 1 rotate 150 translate 0 0",
	["$BaseTexture"] = "models/weapons/flare/shellside",
	["$VertexAlpha"] = 1,
	["$VertexColor"] = 1,
})

surface.CreateFont("achiev_ui_list_font",{
	font = "Square721 BT",
	size = 15,
	additive = false,
	weight = 700,
	antialias = true,
})

surface.CreateFont("achiev_ui_disp_font",{
	font = "Square721 BT",
	size = 20,
	additive = false,
	weight = 700,
	antialias = true,
    outline = true,
})

surface.CreateFont("achiev_ui_title_font",{
	font = "Square721 BT",
	size = 30,
	additive = false,
	weight = 700,
	antialias = true,
    outline = true,
})

local panel = {
    Init = function(self)
        self:SetSize(700,400)
        self:SetPos(ScrW()/2-250,ScrH()/2-200)
        self:SetTitle("")
        self.btnMaxim:Hide()
        self.btnMinim:Hide()
        self.btnClose:Hide()

        self.List = self:Add("DListView")
        self.List:AddColumn("Achievement")
		self.List:SetHideHeaders(true)
        self.List:SetMultiSelect(false)
        self.List:SetWide(300)
        self.List:DockMargin(0,50,0,0)
        self.List:Dock(LEFT)
		self.List.Paint = function() end

        self.Display = self:Add("DPanel")
        self.Display:SetWide(400)
        self.Display:Dock(RIGHT)
        self.Display.Description = ""
        self.Display.Completed = false
        self.Display.Reward = 0

        self.Display.Paint = function(self,w,h)
            surface.SetTextColor(text_color)
            surface.SetFont("achiev_ui_disp_font")
            surface.SetTextPos(20,60)
            surface.DrawText("Description:")

            local scale = 38
            local amount = math.floor(string.len(self.Description)/scale)
            for i=0,amount do
                local str = string.sub(self.Description,i*scale,i*scale+scale-1)
                surface.SetTextPos(20,90+20*i)
                surface.DrawText(str)
            end

            surface.SetTextPos(20,250)
            surface.DrawText("Status: "..(self.Completed and "Completed" or "OnGoing"))
        end

        local parent = self
        self.List.OnRowSelected = function(self,id,line)
            parent.Display.Description = line.Description
            parent.Display.Completed = line.Status
            parent.Display.Reward = line.Reward
        end

        self.BtnClose = self:Add("DButton")
        self.BtnClose:SetSize(200,25)
        self.BtnClose:SetFont("achiev_ui_list_font")
        self.BtnClose:SetText("Close")
        self.BtnClose:SetPos(self:GetWide()/2-100,355)
        self.BtnClose.Paint = function(self,w,h)
            surface.SetTexture(gr_ct_id)
            if self:IsHovered() then
                surface.SetDrawColor(255,127,127)
            else
                surface.SetDrawColor(127,127,127)
            end
            surface.DrawTexturedRect(0,0,w,h)
        end
        self.BtnClose.DoClick = self.btnClose.DoClick
    end,
    Paint = function(self,w,h)
    	surface.SetMaterial(metal)
	surface.SetDrawColor(75,75,75,253)
	surface.DrawTexturedRect(0,0,w,h)
	surface.SetDrawColor(0,0,0)
	surface.SetTexture(gr_up_id)
	surface.DrawTexturedRect(0,0,w,10)
	surface.SetTexture(gr_dw_id)
	surface.DrawTexturedRect(0,h-10,w,10)
        surface.DrawLine(0,0,0,h)
        surface.DrawLine(w-1,0,w-1,h)

        surface.SetFont("achiev_ui_title_font")
        local str = (IsValid(self.Player) and string.gsub(self.Player:Nick(),"<.->","") or "")
        local x,y = surface.GetTextSize(str.." Achievements")
        surface.SetTextPos(w/2-x/2,20)
        surface.SetTextColor(text_color)
        surface.DrawText(str.." Achievements")
        surface.SetDrawColor(text_color)
        surface.DrawLine(100,55,w-100,55)
    end,
    Think = function(self)
    end,
    Setup = function(self,ply)
        if not PCTasks or not IsValid(ply) then return end
        self.Player = ply
        local parent = self
        for k,v in pairs(PCTasks.Store) do
            local line = self.List:AddLine("")
            line.Description = v.desc
            line.Reward = v.XP
            line.Status = PCTasks.IsCompleted(ply,k)
            local str = string.upper(k)
            line.Paint = function(self,w,h)
                surface.SetTexture(gr_id)
                if self.Status then
                    surface.SetDrawColor(100,175,100,175)
                else
                    surface.SetDrawColor(100,100,100,175)
                end
                if parent.List:GetSelected()[1] == self then
                    surface.SetDrawColor(220,140,0)
                end
                surface.DrawTexturedRect(0,2,w,h-4)
                surface.SetFont("achiev_ui_list_font")
                local ach_x,ach_y = surface.GetTextSize(str)
                surface.SetTextColor(text_color)
                surface.SetTextPos(10,h/2-ach_y/2)
                surface.DrawText(str)
            end
        end
    end,
}

vgui.Register("PCTasksPanel",panel,"DFrame")
