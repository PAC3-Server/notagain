avatar = avatar or {}

avatar.avatars = avatar.avatars or {}
avatar.steam_avatars = avatar.steam_avatars or {}

if CLIENT then
	local suppress = false
	local cvar = CreateClientConVar("cl_avatar", "none", true, true)

	local function set_from_string(str)
		if str == "none" then
			avatar.Change(url)
			return
		end

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

		avatar.Change(url, w,h, cx,cy, s)
	end

	cvars.RemoveChangeCallback("cl_avatar", "cl_avatar")
	cvars.AddChangeCallback("cl_avatar", function(_,_, str)
		if suppress then return end
		set_from_string(str)
	end, "cl_avatar")

	hook.Add("OnEntityCreated", "avatar", function(ent)
		if ent == LocalPlayer() then
			set_from_string(cvar:GetString())
			hook.Remove("OnEntityCreated", "avatar")
		end
	end)

	net.Receive("cl_avatar_set", function(len)
		local url = net.ReadString()
		local ply = net.ReadEntity()

		if url == "none" then
			avatar.SetPlayer(ply)
			return
		end

		local w = net.ReadUInt(16)
		local h = net.ReadUInt(16)
		local cx = net.ReadUInt(16)
		local cy = net.ReadUInt(16)
		local s = net.ReadFloat()

		if ply:IsValid() then
			avatar.SetPlayer(ply, url, w,h, cx,cy, s)
		end
	end)

	function avatar.Change(url, w,h, cx,cy, s)
		if not url then
			net.Start("cl_avatar")
			net.WriteString("none")
			net.SendToServer()
			return
		end

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
		if not url then
			avatar.avatars[ply] = nil
			return
		end

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

	local draw_rect = requirex("draw_skewed_rect")

	local border = CreateMaterial(tostring({}), "UnlitGeneric", {
		["$BaseTexture"] = "props/metalduct001a",
		["$VertexAlpha"] = 1,
		["$VertexColor"] = 1,
	})

	function avatar.Draw(ply, x,y, size, rot, sx,sy)
		local info = avatar.avatars[ply]

		if info then
			x = x or 0
			y = y or 0
			size = size or info.w
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
			local x, y = x-size/2,y-size/2
			pnl:SetPos(x, y)
			pnl:SetSize(size, size)
			pnl:PaintManual()

			surface.SetMaterial(border)
			surface.SetDrawColor(255,255,255,255)
			draw_rect(x,y,size,size, 0, 4, 70, 5, border:GetTexture("$BaseTexture"):Width(), true)
		end
	end
end

if SERVER then
	util.AddNetworkString("cl_avatar")
	util.AddNetworkString("cl_avatar_set")

	net.Receive("cl_avatar", function(len, ply)
		local url = net.ReadString()
		if url == "none" then
			avatar.SetPlayer(ply)
			return
		end

		local w = net.ReadUInt(16)
		local h = net.ReadUInt(16)
		local cx = net.ReadUInt(16)
		local cy = net.ReadUInt(16)
		local s = net.ReadFloat()

		avatar.SetPlayer(ply, url, w,h, cx,cy, s)
	end)

	function avatar.SetPlayer(ply, url, w,h, cx,cy, s, filter)
		if not url then
			net.Start("cl_avatar_set")
			net.WriteString("none")
			net.WriteEntity(ply)
			net.Broadcast()
			avatar.avatars[ply] = nil
			return
		end

		h = h or w
		cx = cx or w/2
		cy = cy or h/2
		s = s or 1

		net.Start("cl_avatar_set")
			net.WriteString(url)
			net.WriteEntity(ply)
			net.WriteUInt(w, 16)
			net.WriteUInt(h, 16)
			net.WriteUInt(cx, 16)
			net.WriteUInt(cy, 16)
			net.WriteFloat(s)
		if filter then
			net.Send(filter)
		else
			net.Broadcast()
		end

		avatar.avatars[ply] = {url = url, w = w, h = h, cx = cx,cy = cy, s = s}
	end

	hook.Add("PlayerInitialSpawn", "avatar", function(ply)
		for ent, info in pairs(avatar.avatars) do
			if ent:IsValid() then
				avatar.SetPlayer(ent, info.url, info.w, info.h, info.cx, info.cy, info.s, ply)
			else
				avatar.avatars[ent] = nil
			end
		end
	end)
end


