surface.CreateFont("area_font",{
	font = "Square721 BT",
	size = 50,
	additive = false,
	weight = 700,
	antialias = true,
})

local cur_area = "OverWorld"
local cur_panel
local text_color = Color(200,200,200,255)
local y_pos = 100
local CreatePanel = function(area)
    local area = area or "OtherWorld"
    local panel = vgui.Create("DPanel")
    panel:SetSize(500,70)
    panel:SetPos(ScrW(),y_pos)
    panel.Paint = function(self,w,h)
        surface.SetDrawColor(0,0,0,250)
        surface.DrawPoly({
            { x = w*0.2, y = 0 },
            { x = w, y = 0 },
            { x = w*0.8, y = h },
            { x = 0, y = h },
        })
        surface.SetFont("area_font")
        local x,y = surface.GetTextSize(area)
        surface.SetTextColor(text_color)
        surface.SetTextPos(w/2-x/2,h/2-y/2)
        surface.DrawText(area)
    end
    return panel
end

local Handle = function(ent,area)
    local area = area or "OverWorld"
    if ent == LocalPlayer() then
        timer.Simple(0.5,function()
            if cur_area ~= area and LocalPlayer():IsInArea(area) or (area == "OverWorld" and table.Count(LocalPlayer():GetCurrentAreas()) == 0) then
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
