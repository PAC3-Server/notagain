local prettytext = requirex("pretty_text")

local function show_name(area_name)
	local duration = 5
	local time = RealTime() + duration
	hook.Remove("HUDPaint", "")
	hook.Add("HUDPaint", "newarea", function()
		local f = (time - RealTime()) / duration
		local x, y = ScrW()/2, ScrH()/2

		local brightness = 230
		local alpha = math.max((f^0.15)*255, 1)
		local w, h = prettytext.DrawText({
			text = area_name,
			font = "Square721 BT",
			weight = 0,
			size = 130,
			x = x,
			y = y,
			blur_size = 15,
			blur_overdraw = 4,
			x_align = -0.5,
			y_align = -0.5,
			foreground_color = Color(brightness, brightness, brightness, alpha)
		})

		local border = 6
		local height = 3
		surface.SetDrawColor(0, 0, 0, alpha)
		surface.DrawRect(x - w - border/2, y + h/2.75 - border/2, w*2 + border, height+border)

		surface.SetDrawColor(170, 170, 170, alpha)
		surface.DrawRect(x - w, y + h/2.75, w*2, height)

		if f <= 0 then
			hook.Remove("HUDPaint", "newarea")
		end

	end)
end

local function handle(ent, area_name)
	if ent == LocalPlayer() and ent:GetNWBool("rpg") then
		show_name(area_name or "OverWorld")
	end
end

hook.Add("MD_OnAreaEntered","area_notification", handle)
hook.Add("MD_OnOverWorldEntered","area_notification", handle)

if LocalPlayer():IsValid() then
	show_name("Ash Lake")
end