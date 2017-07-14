if not system.IsLinux() then return end

surface._CreateFont = surface._CreateFont or surface.CreateFont
function surface.CreateFont(name, tbl, ...)
	if tbl.font then
		if file.Exists("resource/fonts/" .. tbl.font:lower() .. ".ttf", "GAME") then
			tbl.font = tbl.font .. ".ttf"
		end
	end
	return surface._CreateFont(name, tbl, ...)
end