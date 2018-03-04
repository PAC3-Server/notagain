local avatar = _G.avatar or {}

avatar.avatars = avatar.avatars or {}
avatar.steam_avatars = avatar.steam_avatars or {}
avatar.npc_avatars = avatar.npc_avatars or {}

if CLIENT then
	local urlimage = requirex("urlimage")

	local suppress = false
	local cvar = CreateClientConVar("cl_avatar", "none", true, true)

	local function set_from_string(str)
		if str == "none" then
			avatar.Change()
			return
		end

		local url, cx,cy, s = unpack(str:gsub("%s+", ""):Split(","))
		if not url then
			ErrorNoHalt("unable to parse cl_avatar string: " .. cl_avatar)
			return
		end
		cx = tonumber(cx)
		cy = tonumber(cy)
		s = tonumber(s) or 1

		avatar.Change(url, cx,cy, s)
	end

	cvars.RemoveChangeCallback("cl_avatar", "cl_avatar")
	cvars.AddChangeCallback("cl_avatar", function(_,_, str)
		if suppress then return end
		set_from_string(str)
	end, "cl_avatar")

	hook.Add("OnEntityCreated", "avatar", function(ent)
		if ent == LocalPlayer() then
			set_from_string(cvar:GetString())
			RunConsoleCommand("request_avatars")
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

		local cx = net.ReadUInt(16)
		local cy = net.ReadUInt(16)
		local s = net.ReadFloat()

		if ply:IsValid() then
			avatar.SetPlayer(ply, url, cx,cy, s)
		end
	end)

	function avatar.Change(url, cx,cy, s)
		if not url then
			net.Start("cl_avatar")
			net.WriteString("none")
			net.SendToServer()
			return
		end

		cx = cx
		cy = cy
		s = s or 1

		net.Start("cl_avatar")
			net.WriteString(url)
			net.WriteUInt(cx, 16)
			net.WriteUInt(cy, 16)
			net.WriteFloat(s)
		net.SendToServer()
	end

	function avatar.SetPlayer(ply, url, center_x, center_y, zoom)
		if not url then
			avatar.avatars[ply] = nil
			return
		end

		avatar.avatars[ply] = {
			url = url,
			mat = urlimage.URLMaterial(url),
			center_x = center_x,
			center_y = center_y,
			zoom = zoom or 1,
		}
		if ply == LocalPlayer() then
			cvar:SetString(table.concat({url, center_x, center_y, zoom}, ","))
		end
	end

	local draw_rect = requirex("draw_skewed_rect")

	local border = CreateMaterial(tostring({}), "UnlitGeneric", {
		["$BaseTexture"] = "props/metalduct001a",
		["$VertexAlpha"] = 1,
		["$VertexColor"] = 1,
	})

	function avatar.Draw(ply, x,y, size, rot, sx,sy, border_size)
		local info = avatar.avatars[ply]

		border_size = border_size or 5

		if info then
			x = x or 0
			y = y or 0
			local sx = info.sx or info.center_x
			local sy = info.sy or info.center_y
			local rot = info.rot or 0

			local w, h = info.mat()
			if not w then return end

			size = size * info.zoom

			local m = Matrix()
			m:Translate(Vector(x - sx,y - sy))

			m:Translate(Vector(sx, sy))
				m:Rotate(Angle(0,rot,0))
				m:Scale(Vector(size/w,size/w,1))
			m:Translate(-Vector(sx, sy))

			cam.PushModelMatrix(m)
			surface.DrawTexturedRect(0, 0, w, h)
			cam.PopModelMatrix()
		elseif ply:IsNPC() then
			if not avatar.npc_avatars[ply] then
				avatar.npc_avatars[ply] = Material("entities/" .. ply:GetClass() .. ".png")
			end

			local x, y = x-size/2,y-size/2

			surface.SetMaterial(avatar.npc_avatars[ply])
			surface.DrawTexturedRect(x, y, size, size)

			render.SetBlend(1)
			render.SetColorModulation(1,1,1,1)
			render.SetMaterial(border)
			draw_rect(x,y,size,size, 0, border_size-1, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)
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

			render.SetMaterial(border)
			render.SetColorModulation(1,1,1)
			render.SetBlend(1)
			draw_rect(x,y,size,size, 0, border_size-1, 70, border_size, border:GetTexture("$BaseTexture"):Width(), true)
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

		local cx = net.ReadUInt(16)
		local cy = net.ReadUInt(16)
		local s = net.ReadFloat()

		avatar.SetPlayer(ply, url, cx,cy, s)
	end)

	function avatar.SetPlayer(ply, url, cx,cy, s, filter)
		if not url then
			net.Start("cl_avatar_set")
			net.WriteString("none")
			net.WriteEntity(ply)
			net.Broadcast()
			avatar.avatars[ply] = nil
			return
		end

		s = s or 1

		net.Start("cl_avatar_set")
			net.WriteString(url)
			net.WriteEntity(ply)
			net.WriteUInt(cx, 16)
			net.WriteUInt(cy, 16)
			net.WriteFloat(s)
		if filter then
			net.Send(filter)
		else
			net.Broadcast()
		end

		avatar.avatars[ply] = {url = url, cx = cx,cy = cy, s = s}
	end

	concommand.Add("request_avatars", function(ply)
		if ply.avatar_last_request and ply.avatar_last_request > RealTime() then return end
		for ent, info in pairs(avatar.avatars) do
			if ent:IsValid() then
				avatar.SetPlayer(ent, info.url, info.cx, info.cy, info.s, ply)
			else
				avatar.avatars[ent] = nil
			end
		end
		ply.avatar_last_request = RealTime() + 1
	end)
end

_G.avatar = avatar