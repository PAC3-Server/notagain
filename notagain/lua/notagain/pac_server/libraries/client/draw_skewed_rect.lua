local mesh = {}

for i = 1, 6 do
	mesh[i] = {x = 0, y = 0, u = 0, v = 0}
end

local function draw_rectangle(x,y, w,h, u1,v1,u2,v2, sx,sy)
	u1 = u1 or 0
	v1 = v1 or 0

	u2 = u2 or 1
	v2 = v2 or 1

	sx = sx or 1
	sy = sy or 1

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

	mesh[1].x = w
	mesh[1].y = h
	mesh[1].u = u2
	mesh[1].v = v1

	mesh[2].x = x
	mesh[2].y = y
	mesh[2].u = u1
	mesh[2].v = v2

	mesh[3].x = w
	mesh[3].y = y
	mesh[3].u = u2
	mesh[3].v = v2


	mesh[4].x = x
	mesh[4].y = h
	mesh[4].u = u1
	mesh[4].v = v1

	mesh[5].x = x
	mesh[5].y = y
	mesh[5].u = u1
	mesh[5].v = v2

	mesh[6].x = w
	mesh[6].y = h
	mesh[6].u = u2
	mesh[6].v = v1

	surface.DrawPoly(mesh)
end

local function draw_sliced_texture(x,y,w,h, uv_size, corner_size, size, dont_draw_center)
	local s = size
	local u = uv_size
	local c = corner_size

	if w/2 < c then c = w/2 end
	if h/2 < c then c = h/2 end

	if not dont_draw_center then
		draw_rectangle(
			x+c,y+c,w-c*2,h-c*2,
			u,u,s-u*2,s-u*2,
			s,s
		)
	end

	draw_rectangle(
		x,y,c,c,
		0,0,u,u,
		s,s
	)
	draw_rectangle(
		x+c,y,w/2-c,c,
		u,0,s/2-u,u,
		s,s
	)
	draw_rectangle(
		w/2+x,y,w/2-c,c,
		s/2,0,s/2-u,u,
		s,s
	)
	draw_rectangle(
		x+w-c,y,c,c,
		s-u,0,u,u,
		s,s
	)


	draw_rectangle(
		x,y+h-c,c,c,
		0,s-u,u,u,
		s,s
	)
	draw_rectangle(
		x+c,y+h-c,w/2-c,c,
		u,s-u,s/2-u,u,
		s,s
	)
	draw_rectangle(
		w/2+x,y+h-c,w/2-c,c,
		s/2,s-u,s/2-u,u,
		s,s
	)
	draw_rectangle(
		x+w-c,y+h-c,c,c,
		s-u,s-u,u,u,
		s,s
	)

	draw_rectangle(
		x,y+c,c,h/2-c,
		0,u,u,s/2-u,
		s,s
	)
	draw_rectangle(
		x,h/2+y,c,h/2-c,
		0,s/2,u,s/2-u,
		s,s
	)


	draw_rectangle(
		x+w-c,y+c,c,h/2-c,
		s-u,u,u,s/2-u,
		s,s
	)
	draw_rectangle(
		x+w-c,h/2+y,c,h/2-c,
		s-u,s/2,u,s/2-u,
		s,s
	)
end

local function skew_matrix(m, x, y)
	x = math.rad(x)
	y = math.rad(y or x)

	local skew = Matrix()
	skew:SetField(1,1, 1)
	skew:SetField(1,2, math.tan(x))
	skew:SetField(2,1, math.tan(y))
	skew:SetField(2,2, 1)
	m:Set(m * skew)
end

return function(x,y,w,h, skew, border, uv_size, corner_size, texture_size, dont_draw_center)
	border = border or 0
	skew = skew or 0

	local m

	if skew ~= 0 then
		m = Matrix()
		m:Translate(Vector(x,y))
		skew_matrix(m, skew, 0)
		m:Translate(-Vector(x,y))
	end

	x = x - border
	y = y - border
	w = w + border * 2
	h = h + border * 2

	if m then
		cam.PushModelMatrix(m)
	end

	if uv_size then
		draw_sliced_texture(x,y,w,h, uv_size, corner_size, texture_size, dont_draw_center)
	else
		draw_rectangle(x,y,w,h)
	end

	if m then
		cam.PopModelMatrix()
	end
end