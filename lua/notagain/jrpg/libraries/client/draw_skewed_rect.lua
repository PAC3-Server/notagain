local rect_mesh = {}

for i = 1, 6 do
	rect_mesh[i] = {x = 0, y = 0, u = 0, v = 0}
end

local mesh = _G.mesh
local mesh_Begin = mesh.Begin
local mesh_Position = mesh.Position
local mesh_TexCoord = mesh.TexCoord
local mesh_Color = mesh.Color
local mesh_AdvanceVertex = mesh.AdvanceVertex
local mesh_End = mesh.End

local temp_vec = Vector()
local R,G,B = 1,1,1
local A = 1

local function draw_rectangle(x,y, w,h, u1,v1,u2,v2, sx,sy)
	-- scale uv coordinates where sx and sy are maybe texture size
	u1 = u1 / sx
	v1 = v1 / sy
	u2 = u2 / sx
	v2 = v2 / sy

	-- make u2 and v2 relative to u1 and v1
	u2 = u2 + u1
	v2 = v2 + v1

	-- make w and h relative to x and y
	w = w + x
	h = h + y

	-- flip y
	local t = v2
	v2 = v1
	v1 = t

	rect_mesh[1].x = w
	rect_mesh[1].y = h
	rect_mesh[1].u = u2
	rect_mesh[1].v = v1

	rect_mesh[2].x = x
	rect_mesh[2].y = y
	rect_mesh[2].u = u1
	rect_mesh[2].v = v2

	rect_mesh[3].x = w
	rect_mesh[3].y = y
	rect_mesh[3].u = u2
	rect_mesh[3].v = v2


	rect_mesh[4].x = x
	rect_mesh[4].y = h
	rect_mesh[4].u = u1
	rect_mesh[4].v = v1

	rect_mesh[5].x = x
	rect_mesh[5].y = y
	rect_mesh[5].u = u1
	rect_mesh[5].v = v2

	rect_mesh[6].x = w
	rect_mesh[6].y = h
	rect_mesh[6].u = u2
	rect_mesh[6].v = v1

	mesh_Begin(MATERIAL_TRIANGLES, 6)
	for i = 1, 6 do
		local v = rect_mesh[i]
		temp_vec.x = v.x
		temp_vec.y = v.y
		mesh_Position(temp_vec)
		mesh_TexCoord(0, v.u, v.v)
		mesh_Color(R,G,B,A)
		mesh_AdvanceVertex()
	end
	mesh_End()
end

local nince_slice_mesh = {}

for i = 1, 128 do
	nince_slice_mesh[i] = {x = 0, y = 0, u = 0, v = 0}
end

local function draw_rectangle2(i, x,y, w,h, u1,v1,u2,v2, sx,sy)
	-- scale uv coordinates where sx and sy are maybe texture size
	u1 = u1 / sx
	v1 = v1 / sy
	u2 = u2 / sx
	v2 = v2 / sy

	-- make u2 and v2 relative to u1 and v1
	u2 = u2 + u1
	v2 = v2 + v1

	-- make w and h relative to x and y
	w = w + x
	h = h + y

	-- flip y
	local t = v2
	v2 = v1
	v1 = t

	nince_slice_mesh[i + 1].x = w
	nince_slice_mesh[i + 1].y = h
	nince_slice_mesh[i + 1].u = u2
	nince_slice_mesh[i + 1].v = v1

	nince_slice_mesh[i + 2].x = x
	nince_slice_mesh[i + 2].y = y
	nince_slice_mesh[i + 2].u = u1
	nince_slice_mesh[i + 2].v = v2

	nince_slice_mesh[i + 3].x = w
	nince_slice_mesh[i + 3].y = y
	nince_slice_mesh[i + 3].u = u2
	nince_slice_mesh[i + 3].v = v2


	nince_slice_mesh[i + 4].x = x
	nince_slice_mesh[i + 4].y = h
	nince_slice_mesh[i + 4].u = u1
	nince_slice_mesh[i + 4].v = v1

	nince_slice_mesh[i + 5].x = x
	nince_slice_mesh[i + 5].y = y
	nince_slice_mesh[i + 5].u = u1
	nince_slice_mesh[i + 5].v = v2

	nince_slice_mesh[i + 6].x = w
	nince_slice_mesh[i + 6].y = h
	nince_slice_mesh[i + 6].u = u2
	nince_slice_mesh[i + 6].v = v1
end

local function draw_sliced_texture(x,y,w,h, uv_size, corner_size, size, dont_draw_center)
	local s = size
	local u = uv_size
	local c = corner_size

	if w/2 < c then c = w/2 end
	if h/2 < c then c = h/2 end

	local i = 0

	if not dont_draw_center then
		draw_rectangle2(
			i,
			x+c,y+c,w-c*2,h-c*2,
			u,u,s-u*2,s-u*2,
			s,s
		)
		i = i + 6
	end

	draw_rectangle2(
		i,
		x,y,c,c,
		0,0,u,u,
		s,s
	)
	i = i + 6

	draw_rectangle2(
		i,
		x+c,y,w/2-c,c,
		u,0,s/2-u,u,
		s,s
	)
	i = i + 6

	draw_rectangle2(
		i,
		w/2+x,y,w/2-c,c,
		s/2,0,s/2-u,u,
		s,s
	)
	i = i + 6

	draw_rectangle2(
		i,
		x+w-c,y,c,c,
		s-u,0,u,u,
		s,s
	)
	i = i + 6

	draw_rectangle2(
		i,
		x,y+h-c,c,c,
		0,s-u,u,u,
		s,s
	)
	i = i + 6

	draw_rectangle2(
		i,
		x+c,y+h-c,w/2-c,c,
		u,s-u,s/2-u,u,
		s,s
	)
	i = i + 6

	draw_rectangle2(
		i,
		w/2+x,y+h-c,w/2-c,c,
		s/2,s-u,s/2-u,u,
		s,s
	)
	i = i + 6

	draw_rectangle2(
		i,
		x+w-c,y+h-c,c,c,
		s-u,s-u,u,u,
		s,s
	)
	i = i + 6


	draw_rectangle2(
		i,
		x,y+c,c,h/2-c,
		0,u,u,s/2-u,
		s,s
	)
	i = i + 6

	draw_rectangle2(
		i,
		x,h/2+y,c,h/2-c,
		0,s/2,u,s/2-u,
		s,s
	)
	i = i + 6


	draw_rectangle2(
		i,
		x+w-c,y+c,c,h/2-c,
		s-u,u,u,s/2-u,
		s,s
	)
	i = i + 6
	draw_rectangle2(
		i,
		x+w-c,h/2+y,c,h/2-c,
		s-u,s/2,u,s/2-u,
		s,s
	)
	i = i + 6

	mesh_Begin(MATERIAL_TRIANGLES, i)
	for i = 1, i do
		local v = nince_slice_mesh[i]
		temp_vec.x = v.x
		temp_vec.y = v.y
		mesh_Position(temp_vec)
		mesh_TexCoord(0, v.u, v.v)
		mesh_Color(R, G, B, A)
		mesh_AdvanceVertex()
	end
	mesh_End()
end

local math_rad = math.rad
local math_tan = math.tan
local temp_matrix = Matrix()

local function skew_matrix(m, x, y)
	x = math_rad(x)
	y = math_rad(y or x)

	local skew = temp_matrix
	--skew:Identity()
	skew:SetField(1,1, 1)
	skew:SetField(1,2, math_tan(x))
	skew:SetField(2,1, math_tan(y))
	skew:SetField(2,2, 1)
	m:Set(m * skew)
end

local cam_PushModelMatrix = cam.PushModelMatrix
local cam_PopModelMatrix = cam.PopModelMatrix

local temp_matrix = Matrix()

local function draw_skewed_rect(x,y,w,h, skew, border, uv_size, corner_size, texture_size, dont_draw_center)
	border = border or 0
	skew = skew or 0

	R,G,B = render.GetColorModulation()
	R = R*255
	G = G*255
	B = B*255

	A = render.GetBlend()
	A = A*255

	local m

	if skew ~= 0 then
		m = temp_matrix
		m:Identity()
		m:Translate(Vector(x + w/2,y + h/2))
		skew_matrix(m, skew, 0)
		m:Translate(-Vector(x + w/2,y + h/2))
	end

	x = x - border
	y = y - border
	w = w + border * 2
	h = h + border * 2

	if m then
		cam_PushModelMatrix(m)
	end

	if uv_size then
		draw_sliced_texture(x,y,w,h, uv_size, corner_size, texture_size, dont_draw_center)
	else
		draw_rectangle(x,y,w,h, 0,0,1,1, 1,1)
	end

	if m then
		cam_PopModelMatrix()
	end
end

if LocalPlayer() == me then
	local border = CreateMaterial(tostring({}), "UnlitGeneric", {
		["$BaseTexture"] = "props/metalduct001a",
		["$VertexAlpha"] = 1,
		["$VertexColor"] = 1,
	})

	hook.Add("HUDPaint", "", function()
		render.SetColorModulation(1,1,0,1)
		render.SetBlend(0.1)
		render.SetMaterial(border)
		draw_skewed_rect(50,50,256,128, 0, 1, nil,8, border:GetTexture("$BaseTexture"):Width(), true)
	end)
end

return draw_skewed_rect