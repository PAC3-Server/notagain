timer.Create("uilabelfix", 1, 0, function()
	if LocalPlayer():IsValid() then
		SKIN.Colours.Label.Dark = Color(200, 200, 200, 255)
		timer.Remove("uilabelfix")
	end
end)
