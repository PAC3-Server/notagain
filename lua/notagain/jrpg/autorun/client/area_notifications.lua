surface.CreateFont("area_font",{
	font = "Square721 BT",
	size = 50,
	additive = false,
	weight = 700,
	antialias = true,
})

local cur_area = "Overworld"
local cur_panel
local text_color = Color(200,200,200,255)
local y_pos = 100
local CreatePanel = function(area)
    local panel = vgui.Create("DPanel")
    panel:SetSize(500,70)
    panel:SetPos(ScrW(),y_pos)
    panel.Paint = function(self,w,h)
		draw.NoTexture()
        surface.SetDrawColor(30,30,30,255)
        surface.DrawPoly({
            { x = w*0.2, y = 0 },
            { x = w, y = 0 },
            { x = w*0.8, y = h },
            { x = 0, y = h },
        })
        surface.SetDrawColor(text_color)
        surface.DrawLine(w*0.2,0,w,0)
        surface.DrawLine(w,0,w*0.8,h)
        surface.DrawLine(w*0.8,h-1,0,h-1)
        surface.DrawLine(0,h,w*0.2,0)
        surface.SetFont("area_font")
        local x,y = surface.GetTextSize(area)
        surface.SetTextColor(text_color)
        surface.SetTextPos(w/2-x/2,h/2-y/2)
        surface.DrawText(area)
    end
    return panel
end

local Handle = function(ent,area)
    local area = area or "Overworld"
    if ent == LocalPlayer() then
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

hook.Add("InitPostEntity","MapDefineNotification",function()
    hook.Add("MD_OnAreaEntered","MapDefineNotification",Handle)
    hook.Add("MD_OnOverWorldEntered","MapDefineNotification",Handle)
end)
