local prettytext = requirex("pretty_text")

local function show_name(area_name)
	local duration = 5
	local time = RealTime() + duration
	jrpg.RemoveHook("HUDPaint", "")
	jrpg.AddHook("HUDPaint", "newarea", function()
		local f = math.max((time - RealTime()) / duration, 0)
		local x, y = ScrW()/2, ScrH()/4

		local brightness = 255
		local alpha = (f^0.15)*255*1.2

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

		surface.SetDrawColor(brightness, brightness, brightness, alpha)
		surface.DrawRect(x - w, y + h/2.75, w*2, height)

		if f <= 0 then
			jrpg.RemoveHook("HUDPaint", "newarea")
		end

	end)
end

local function handle(ent, area_name)
	if ent == LocalPlayer() and jrpg.IsEnabled(ent) then
		show_name(area_name or "OverWorld")
	end
end

jrpg.AddHook("MD_OnAreaEntered","area_notification", handle)
jrpg.AddHook("MD_OnOverWorldEntered","area_notification", handle)

if LocalPlayer():IsValid() then
	show_name("Ash Lake")
end