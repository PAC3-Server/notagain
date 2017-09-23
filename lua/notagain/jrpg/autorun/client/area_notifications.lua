local prettytext = requirex("pretty_text")

local cur_area = "Overworld"
local cur_panel
local text_color = Color(200,200,200,255)
local y_pos = 50
local CreatePanel = function(area)
    local panel = vgui.Create("DPanel")
    panel:SetSize(200,55)
    panel:SetPos(ScrW(),y_pos)
    panel.Paint = function(self,w,h)
		surface.DisableClipping(true)
		jhud.DrawBar(h/2,0,w,h,1,1,5, 0, 0, 0)
		local w, h = prettytext.DrawText({
			text = area,
			font = "Square721 BT",
			weight = 1000,
			size = 30,
			x = w/2,
			y = h/2,
			blur_size = 8,
			blur_overdraw = 4,
			x_align = -0.5,
			y_align = -0.5,
			background_color = Color(50, 100, 150)
		})
		self:SetWide(w+50)
		surface.DisableClipping(false)
    end
	panel:Paint(panel:GetSize()) -- lol
    return panel
end

local Handle = function(ent,area)
    local area = area or "Overworld"
    if ent == LocalPlayer() and ent:GetNWBool("rpg", false) then
        timer.Simple(0.5,function()
            if cur_area ~= area and LocalPlayer():IsInArea(area) or (area == "Overworld" and table.Count(LocalPlayer():GetCurrentAreas()) == 0) then
                cur_area = area
                if IsValid(cur_panel) then
                    cur_panel:MoveTo(-cur_panel:GetWide(),y_pos,0.35,0,7,function(_,pa) pa:Remove() end)
                end
                local panel = CreatePanel(area)
                cur_panel = panel
                panel:MoveTo(ScrW()/2-panel:GetWide()/2,y_pos,0.35,0,7)
                timer.Simple(3,function()
                    if not IsValid(panel) then return end
                    panel:MoveTo(-panel:GetWide(),y_pos,0.35,0,7,function(_,pa) pa:Remove() end)
                end)
            end
        end)
    end
end

hook.Add("MD_OnAreaEntered","MapDefineNotification",Handle)
hook.Add("MD_OnOverWorldEntered","MapDefineNotification",Handle)