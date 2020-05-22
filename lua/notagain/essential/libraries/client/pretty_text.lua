local fonts = {}

local function create_fonts(font, size, weight, blursize)
	local id = "_" .. font .. "_" .. size .. "_" .. weight .. "_" .. blursize
	local main = "pretty_text" .. id
	local blur = "pretty_text_blur" .. id

	surface.CreateFont(main, {
		font = font,
		size = size,
		weight = weight,
		antialias = true,
	})

	if blursize >= 1 then
		surface.CreateFont(blur, {
			font = font,
			size = size,
			weight = weight,
			blursize = blursize / 2,
			outline = true,
			antialias = true,
		})
	else
		blur = main
	end

	return {
		main = main,
		blur = blur,
	}
end

local default_foreground_color = Color(255, 255, 255, 255)
local default_background_color = Color(0, 0, 0, 255)

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
local TEXFILTER_LINEAR = TEXFILTER.LINEAR

local cam_PushModelMatrix = cam.PushModelMatrix
local render_PushFilterMag = render.PushFilterMag
local render_PushFilterMin = render.PushFilterMin

local cam_PopModelMatrix = cam.PopModelMatrix
local render_PopFilterMag = render.PopFilterMag
local render_PopFilterMin = render.PopFilterMin

local hsv_cache = {}

local prettytext = {}

local stencil_tex = GetRenderTarget("pretty_text_stencil_" .. os.clock(), ScrW(), ScrH(), false)
local stencil_mat = CreateMaterial("pretty_text_stencil_mat" .. os.clock(), "UnlitGeneric", {
	["$alphatest"] = "1",
	["$alphatestreference"] = "0.005",
	["$translucent"] = "1",
	["$vertexcolor"] = "1",
	["$vertexalpha"] = "1",
})

stencil_mat:SetTexture("$basetexture", stencil_tex)

local temp_vec = Vector()
local temp_ang = Angle()
local temp_matrix = Matrix()
local temp_matrix2 = Matrix()

local function skew_matrix(m, x, y)
	x = math.rad(x)
	y = math.rad(y or x)

	temp_matrix2:Identity()
	temp_matrix2:SetField(1,1, 1)
	temp_matrix2:SetField(1,2, math.tan(x))
	temp_matrix2:SetField(2,1, math.tan(y))
	temp_matrix2:SetField(2,2, 1)
	m:Set(m * temp_matrix2)
end

local temp_fg = Color(255, 255, 255, 255)
local temp_bg = Color(255, 255, 255, 255)

function prettytext.DrawText(tbl)

	local text = tbl.text or "nil"
	local x = tbl.x or 0
	local y = tbl.y or 0
	local font = tbl.font or "arial"
	local size = tbl.size or 14
	local weight = tbl.weight or 0
	local blur_size = tbl.blur_size or 1

	if tbl.foreground_color_r then
		temp_fg.r = tbl.foreground_color_r
		temp_fg.g = tbl.foreground_color_g
		temp_fg.b = tbl.foreground_color_b
		temp_fg.a = tbl.foreground_color_a
		tbl.foreground_color = temp_fg
	end

	if tbl.background_color_r then
		temp_bg.r = tbl.background_color_r
		temp_bg.g = tbl.background_color_g
		temp_bg.b = tbl.background_color_b
		temp_bg.a = tbl.background_color_a
		tbl.background_color = temp_bg
	end

	local foreground_color = tbl.foreground_color or default_foreground_color
	local background_color = tbl.background_color or default_background_color
	local alpha = (tbl.alpha or 1) * (foreground_color.a / 255)

	alpha = alpha ^ 2

	--surface.SetAlphaMultiplier(alpha)

	if background_color == true then
		hsv_cache[foreground_color.r] = hsv_cache[foreground_color.r] or {}
		hsv_cache[foreground_color.r][foreground_color.g] = hsv_cache[foreground_color.r][foreground_color.g] or {}

		if not hsv_cache[foreground_color.r][foreground_color.g][foreground_color.b] then
			local h,s,v = ColorToHSV(foreground_color)
			local v2 = v
			s = s * 0.5
			v = v * 0.5
			v = -v + 1

			if math.abs(v-v2) < 0.1 then
				v = v - 0.25
			end
			background_color = HSVToColor(h,s,v)

			hsv_cache[foreground_color.r][foreground_color.g][foreground_color.b] = hsv_cache[foreground_color.r][foreground_color.g][foreground_color.b] or background_color
		end

		background_color = hsv_cache[foreground_color.r][foreground_color.g][foreground_color.b]
	end

	background_color = background_color or default_background_color

	if not fonts[font] then fonts[font] = {} end
	if not fonts[font][size] then fonts[font][size] = {} end
	if not fonts[font][size][weight] then fonts[font][size][weight] = {} end
	if not fonts[font][size][weight][blur_size] then fonts[font][size][weight][blur_size] = create_fonts(font, size, weight, blur_size) end

	local w, h = prettytext.GetTextSize(text, font, size, weight, blur_size)

	if tbl.x_align then
		x = x + (w * tbl.x_align)
	end

	if tbl.y_align then
		y = y + (h * tbl.y_align)
	end

	surface_SetFont(fonts[font][size][weight][blur_size].blur)

	local scale_x
	local scale_y
	local angle = tbl.angle
	local render_x = tbl.render_x
	local render_y = tbl.render_y
	local skew_x = tbl.skew_x or tbl.skew
	local skew_y = tbl.skew_y or 0

	if tbl.scale_x or tbl.scale_y or tbl.scale then
		scale_x = tbl.scale_x or tbl.scale
		scale_y = tbl.scale_y or scale_x
	end

	if scale_x or angle or tbl.skew_x or tbl.skew_y or render_x or render_y then
		local x = x + w / 2
		local y = y + h / 2

		temp_matrix:Identity()

		temp_vec.x = x
		temp_vec.y = y

		temp_matrix:Translate(temp_vec)

		if scale_x then
			temp_vec.x = scale_x
			temp_vec.y = scale_y
			temp_matrix:Scale(temp_vec)
		end

		if angle then
			temp_ang.y = angle
			temp_matrix:Rotate(temp_ang)
		end

		if tbl.skew_x or tbl.skew_y then
			skew_matrix(temp_matrix, skew_x or 0, skew_y)
		end

		if render_x or render_y then
			temp_vec.x = render_x
			temp_vec.y = render_y
			temp_matrix:Translate(temp_vec)
		end

		temp_vec.x = -x
		temp_vec.y = -y
		temp_matrix:Translate(temp_vec)

		cam_PushModelMatrix(temp_matrix)
		render_PushFilterMag(TEXFILTER_LINEAR)
		render_PushFilterMin(TEXFILTER_LINEAR)
	end

	if tbl.shadow_x or tbl.shadow_y then
		if tbl.shadow_color then
			surface_SetTextColor(tbl.shadow_color)
		else
			surface_SetTextColor(0, 0, 0, 255)
		end

		local shadow_x = x + (tbl.shadow_x or tbl.shadow_y)
		local shadow_y = y + (tbl.shadow_y or tbl.shadow_x)

		for _ = 1, 15 do
			surface_SetTextPos(shadow_x, shadow_y)
			surface_DrawText(text)
		end
	end

	surface_SetTextColor(background_color.r, background_color.g, background_color.b, (background_color.a/255 * (foreground_color.a/255)^8)*170)

	for _ = 1, tbl.blur_overdraw or 2 do
		surface_SetTextPos(x, y)
		surface_DrawText(text)
	end

	if tbl.gradient_material then
		surface.SetAlphaMultiplier(1)
		render_PushRenderTarget(stencil_tex)
		render_OverrideAlphaWriteEnable(true, true)
		render_Clear(0, 0, 0, 0)
		surface_SetTextColor(255, 255, 255, 1)
		surface_SetFont(fonts[font][size][weight][blur_size].main)
		surface_SetTextPos(x, y)
		surface_DrawText(text)
		render_OverrideAlphaWriteEnable(false)
		render_PopRenderTarget()
		surface.SetAlphaMultiplier(alpha)

		surface_DisableClipping(true)
		render_SetStencilEnable(true)
		render_ClearStencil()
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
	if blur_size > 1 then
		surface_SetFont(fonts[font][size][weight][blur_size].main)
	end
	surface_SetTextColor(foreground_color)
	surface_SetTextPos(x, y)
	surface_DrawText(text)

	if tbl.gradient_material then
		surface_SetDrawColor(foreground_color)
		surface_SetMaterial(tbl.gradient_material)
		surface_DrawTexturedRect(x,y,w,h)

		render_SetStencilEnable(false)
		surface_DisableClipping(false)
	end

	if tbl.scale_x or tbl.scale_y or tbl.scale or tbl.skew_x or tbl.skew_y then
		cam_PopModelMatrix()
		render_PopFilterMag()
		render_PopFilterMin()
	end

	--surface.SetAlphaMultiplier(1)

	return w, h
end

function prettytext.Draw(
		text,
		x,
		y,
		font,
		size,
		weight,
		blursize,
		color1,
		color2,
		x_align,
		y_align,
		blur_overdraw,
		shadow,
		gradient_mat,
		gr,gg,gb,ga
	)

	return prettytext.DrawText({
		text = text,
		x = x,
		y = y,
		font = font,
		size = size,
		weight = weight,
		blur_size = blursize,
		foreground_color = color1,
		background_color = color2,
		x_align = x_align,
		y_align = y_align,
		blur_overdraw = blur_overdraw,
		shadow_x = shadow,
		gradient_mat = gradient_mat,
		gr = gr,
		gg = gg,
		gb = gb,
		ga = ga,
	})
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