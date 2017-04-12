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
			antialias = true,
		}
	)

	surface.CreateFont(
		blur,
		{
			font = font,
			size = size,
			weight = weight,
			antialias= true,
			blursize = blursize/2,
			outline = true,
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

local STENCILOPERATION_KEEP = STENCILOPERATION_KEEP
local STENCILOPERATION_REPLACE = STENCILOPERATION_REPLACE
local STENCILCOMPARISONFUNCTION_ALWAYS = STENCILCOMPARISONFUNCTION_ALWAYS
local STENCILCOMPARISONFUNCTION_EQUAL = STENCILCOMPARISONFUNCTION_EQUAL

local surface_SetFont = surface.SetFont
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText
local surface_GetTextSize = surface.GetTextSize

local render_PushRenderTarget = render.PushRenderTarget
local render_OverrideAlphaWriteEnable = render.OverrideAlphaWriteEnable
local render_Clear = render.Clear
local render_PopRenderTarget = render.PopRenderTarget
local surface_DisableClipping = surface.DisableClipping
local render_ClearStencil = render.ClearStencil
local render_SetStencilEnable = render.SetStencilEnable
local render_SetStencilWriteMask = render.SetStencilWriteMask
local render_SetStencilTestMask = render.SetStencilTestMask
local render_SetStencilReferenceValue = render.SetStencilReferenceValue
local render_SetStencilFailOperation = render.SetStencilFailOperation
local render_SetStencilZFailOperation = render.SetStencilZFailOperation
local render_SetStencilPassOperation = render.SetStencilPassOperation
local render_SetStencilCompareFunction = render.SetStencilCompareFunction
local render_SetMaterial = render.SetMaterial
local render_DrawScreenQuad = render.DrawScreenQuad
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local ColorToHSV = ColorToHSV
local HSVToColor = HSVToColor
local Color = Color

local hsv_cache = {}

local prettytext = {}

local stencil_tex = GetRenderTarget("pretty_text_stencil_" .. os.clock(), ScrW(),ScrH(), false)
local stencil_mat = CreateMaterial("pretty_text_stencil_mat" .. os.clock(), "UnlitGeneric", {
	["$alphatest"] = "1",
	["$alphatestreference"] = "0.01",
	["$translucent"] = "1",
	["$vertexcolor"] = "1",
	["$vertexalpha"] = "1",
})

stencil_mat:SetTexture("$basetexture", stencil_tex)

function prettytext.Draw(text, x, y, font, size, weight, blursize, color1, color2, x_align, y_align, blur_overdraw, shadow, gradient_mat, gr,gg,gb,ga)
	font = font or "arial"
	size = size or 14
	weight = weight or 0
	blursize = blursize or 1
	color1 = color1 or def_color1
	blur_overdraw = blur_overdraw or 5

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

	if shadow then
		surface_SetTextColor(0,0,0,255)
		for _ = 1, 15 do
			surface_SetTextPos(x+shadow, y+shadow)
			surface_DrawText(text)
		end
	end

	surface_SetTextColor(Color(color2.r, color2.g, color2.b, color2.a * (color1.a/255)))

	for _ = 1, blur_overdraw do
		surface_SetTextPos(x, y)
		surface_DrawText(text)
	end

	if gradient_mat then
		render_PushRenderTarget(stencil_tex)
		render_OverrideAlphaWriteEnable( true, true )
		render_Clear(0, 0, 0, 0)
		surface_SetTextColor(255, 255, 255, 255)
		surface_SetFont(fonts[font][size][weight][blursize].main)
		surface_SetTextPos(x, y)
		surface_DrawText(text)
		render_OverrideAlphaWriteEnable(false)
		render_PopRenderTarget()

		surface_DisableClipping(true)
		render_ClearStencil()
		render_SetStencilEnable(true)
		render_SetStencilWriteMask(255)
		render_SetStencilTestMask(255)
		render_SetStencilReferenceValue(15)
		render_SetStencilFailOperation(STENCILOPERATION_KEEP)
		render_SetStencilZFailOperation(STENCILOPERATION_KEEP)
		render_SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render_SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
			render_SetMaterial(stencil_mat)
			render_DrawScreenQuad()
		render_SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
	end

	-- draw text1
	surface_SetFont(fonts[font][size][weight][blursize].main)
	surface_SetTextColor(color1)
	surface_SetTextPos(x, y)
	surface_DrawText(text)

	if gradient_mat then
		gr = gr or 255
		gg = gg or 255
		gb = gb or 255
		ga = ga or 255

		-- draw gradient
		surface_SetDrawColor(gr,gg,gb,ga)
		surface_SetMaterial(gradient_mat)
		surface_DrawTexturedRect(x,y,w,h)

		render_SetStencilEnable(false)
		surface_DisableClipping(false)
	end

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