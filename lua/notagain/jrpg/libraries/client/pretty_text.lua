local fonts = {}

local function create_fonts(font, size, weight, blursize)
	local main = "pretty_text_" .. size .. "_" .. weight .. "_" .. blursize
	local blur = "pretty_text_blur_" .. size  .. "_" .. weight .. "_" .. blursize

	surface.CreateFont(
		main,
		{
			font = font,
			size = size,
			weight = weight,
			antialias 	= true,
		}
	)

	surface.CreateFont(
		blur,
		{
			font = font,
			size = size,
			weight = weight,
			antialias 	= true,
			blursize = blursize,
		}
	)

	return
	{
		main = main,
		blur = blur,
	}
end

local def_color1 = Color(255, 255, 255, 255)
local def_color2 = Color(0, 0, 0, 255)

local surface_SetFont = surface.SetFont
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText
local surface_GetTextSize = surface.GetTextSize
local Color = Color

local hsv_cache = {}

local prettytext = {}

function prettytext.Draw(text, x, y, font, size, weight, blursize, color1, color2, x_align, y_align)
	font = font or "arial"
	size = size or 14
	weight = weight or 0
	blursize = blursize or 1
	color1 = color1 or def_color1

	if color2 == true then
		hsv_cache[color1.r] = hsv_cache[color1.r] or {}
		hsv_cache[color1.r][color1.g] = hsv_cache[color1.r][color1.g] or {}

		if not hsv_cache[color1.r][color1.g][color1.b] then
			local h,s,v = ColorToHSV(color1)
			local v2 = v
			s = s * 0.5
			v = v * 0.5
			v = -v + 1

			if math.abs(v-v2) < 0.1 then
				v = v - 0.25
			end
			color2 = HSVToColor(h,s,v)

			hsv_cache[color1.r][color1.g][color1.b] = hsv_cache[color1.r][color1.g][color1.b] or color2
		end

		color2 = hsv_cache[color1.r][color1.g][color1.b]
	end

	color2 = color2 or def_color2

	if not fonts[font] then fonts[font] = {} end
	if not fonts[font][size] then fonts[font][size] = {} end
	if not fonts[font][size][weight] then fonts[font][size][weight] = {} end
	if not fonts[font][size][weight][blursize] then fonts[font][size][weight][blursize] = create_fonts(font, size, weight, blursize) end

	local w, h = prettytext.GetTextSize(text, font, size, weight, blursize)
	if x_align then
		x = x + (w * x_align)
	end

	if y_align then
		y = y + (h * y_align)
	end

	surface_SetFont(fonts[font][size][weight][blursize].blur)
	surface_SetTextColor(Color(color2.r, color2.g, color2.b, color2.a * (color1.a/255)))

	for i = 1, 5 do
		surface_SetTextPos(x, y) -- this resets for some reason after drawing
		surface_DrawText(text)
	end

	surface_SetFont(fonts[font][size][weight][blursize].main)
	surface_SetTextColor(color1)
	surface_SetTextPos(x, y)
	surface_DrawText(text)

	return w, h
end

function prettytext.GetTextSize(text, font, size, weight, blursize)
	font = font or "arial"
	size = size or 14
	weight = weight or 0
	blursize = blursize or 1

	if not fonts[font] then fonts[font] = {} end
	if not fonts[font][size] then fonts[font][size] = {} end
	if not fonts[font][size][weight] then fonts[font][size][weight] = {} end
	if not fonts[font][size][weight][blursize] then fonts[font][size][weight][blursize] = create_fonts(font, size, weight, blursize) end

	surface_SetFont(fonts[font][size][weight][blursize].main)
	return surface_GetTextSize(text)
end

return prettytext