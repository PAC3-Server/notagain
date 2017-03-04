avatar = avatar or {}

avatar.avatars = avatar.avatars or {}
avatar.steam_avatars = avatar.steam_avatars or {}

if CLIENT then
	local suppress = false
	local cvar = CreateClientConVar("cl_avatar", "", true, true)

	cvars.AddChangeCallback("cl_avatar", function(_,_, str)
		if suppress then return end
		local url, w,h, cx,cy, s = unpack(str:gsub("%s+", ""):Split(","))
		if not url then
			ErrorNoHalt("unable to parse cl_avatar string: " .. cl_avatar)
			return
		end
		w = tonumber(w)
		h = tonumber(h) or w
		cx = tonumber(cx) or w/2
		cy = tonumber(cy) or h/2
		s = tonumber(s) or 1

		if url then
			avatar.Change(url, w,h, cx,cy, s)
		end
	end)

	net.Receive("cl_avatar_set", function(len)
		local url = net.ReadString()
		local w = net.ReadUInt(16)
		local h = net.ReadUInt(16)
		local cx = net.ReadUInt(16)
		local cy = net.ReadUInt(16)
		local s = net.ReadFloat()
		local ply = net.ReadEntity()

		if ply:IsValid() then
			avatar.SetPlayer(ply, url, w,h, cx,cy, s)
		end
	end)

	function avatar.Change(url, w,h, cx,cy, s)
		h = h or w
		cx = cx or w/2
		cy = cy or h/2
		s = s or 1

		net.Start("cl_avatar")
			net.WriteString(url)
			net.WriteUInt(w, 16)
			net.WriteUInt(h, 16)
			net.WriteUInt(cx, 16)
			net.WriteUInt(cy, 16)
			net.WriteFloat(s)
		net.SendToServer()
	end

	function avatar.SetPlayer(ply, url, w,h, center_x, center_y, zoom)
		local mat = CreateMaterial(tostring({}), "UnlitGeneric", {
			["$BaseTexture"] = "props/metalduct001a",
			["$VertexAlpha"] = 1,
			["$VertexColor"] = 1,
		})

		pac.urltex.GetMaterialFromURL(url, function(_, tex)
			mat:SetTexture("$BaseTexture", tex)
		end, false, "UnlitGeneric")

		avatar.avatars[ply] = {
			url = url,
			mat = mat,
			w = w,
			h = h,
			center_x = center_x,
			center_y = center_y,
			zoom = zoom or 1,
		}
		if ply == LocalPlayer() then
			cvar:SetString(table.concat({url, w,h, center_x, center_y, zoom}, ","))
		end
	end

	function avatar.Draw(ply, x,y, size, rot, sx,sy)
		local info = avatar.avatars[ply]

		if info then
			x = x or 0
			y = y or 0
			local size = info.size or info.w
			local sx = info.sx or info.center_x
			local sy = info.sy or info.center_y
			local rot = info.rot or 0
			local w = info.w
			local h = info.h

			size = size * info.zoom

			surface.SetMaterial(info.mat)

			local m = Matrix()
			m:Translate(Vector(x - sx,y - sy))

			m:Translate(Vector(sx, sy))
				m:Rotate(Angle(0,rot,0))
				m:Scale(Vector(size/w,size/w,1))
			m:Translate(-Vector(sx, sy))

			cam.PushModelMatrix(m)
			surface.DrawTexturedRect(0, 0, w, h)
			cam.PopModelMatrix()
		else
			if not avatar.steam_avatars[ply] then
				local pnl = vgui.Create("AvatarImage")
				pnl:SetPlayer(ply, 184)
				pnl:SetPaintedManually(true)
				avatar.steam_avatars[ply] = pnl
			end

			local pnl = avatar.steam_avatars[ply]

			pnl:SetPos(x-size/2,y-size/2)
			pnl:SetSize(size, size)
			pnl:PaintManual()
		end
	end
end

if SERVER then
	util.AddNetworkString("cl_avatar")
	util.AddNetworkString("cl_avatar_set")

	net.Receive("cl_avatar", function(len, ply)
		local url = net.ReadString()
		local w = net.ReadUInt(16)
		local h = net.ReadUInt(16)
		local cx = net.ReadUInt(16)
		local cy = net.ReadUInt(16)
		local s = net.ReadFloat()

		avatar.SetPlayer(ply, url, w,h, cx,cy, s)
	end)

	function avatar.SetPlayer(ply, url, w,h, cx,cy, s, filter)
		h = h or w
		cx = cx or w/2
		cy = cy or h/2
		s = s or 1

		net.Start("cl_avatar_set")
			net.WriteString(url)
			net.WriteUInt(w, 16)
			net.WriteUInt(h, 16)
			net.WriteUInt(cx, 16)
			net.WriteUInt(cy, 16)
			net.WriteFloat(s)
			net.WriteEntity(ply)
		if filter then
			net.Send(filter)
		else
			net.Broadcast()
		end

		avatar.avatars[ply] = {url = url, w = w, h = h, cx = cx,cy = cy, s = s}
	end

	hook.Add("PlayerInitialSpawn", "avatar", function(ply)
		for ent,v in pairs(avatar.avatars) do
			if ent:IsValid() then
				avatar.SetPlayer(ent, v.url, v.w, v.h, v.cx, v.cy, v.s, ply)
			end
		end
	end)

	if aowl then
		aowl.AddCommand("avatar", function(ply, _, url,w,h,cx,cy,s)

			if not url or not w then
				return false, "url, width, height, center_x, center_y, scale"
			end

			w = tonumber(w)
			h = tonumber(h) or w
			cx = tonumber(cx) or w/2
			cy = tonumber(cy) or h/2
			s = tonumber(s) or 1

			avatar.SetPlayer(ply, url,w,h,cx,cy,s)
		end)
	end
end


