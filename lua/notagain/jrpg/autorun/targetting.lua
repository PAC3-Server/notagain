jtarget = jtarget or {}
jtarget.scroll_dir = 0

local max_distance = 700

function jtarget.FindEnemies(actor, radius)
	local pos = actor:EyePos()
	local temp = {}
	local i = 1
	for _, ent in ipairs(ents.FindInSphere(pos, radius or 1000)) do
		if not jrpg.IsFriend(actor, ent) and jrpg.IsActor(ent) and ent ~= actor then
			temp[i] = ent
			i = i + 1
		end
	end
	table.sort(list, function(a, b)
		return a:EyePos():Distance(pos) < b:EyePos():Distance(pos)
	end)
	return temp
end

function jtarget.FindFriends(actor, radius)
	local pos = actor:EyePos()
	local temp = {}
	local i = 1
	for _, ent in ipairs(ents.FindInSphere(pos, radius or 1000)) do
		if jrpg.IsFriend(actor, ent) and ent ~= actor then
			temp[i] = ent
			i = i + 1
		end
	end
	table.sort(list, function(a, b)
		return a:EyePos():Distance(pos) > b:EyePos():Distance(pos)
	end)
	return temp
end

if CLIENT then
	function jtarget.GetTargetsOnScreen(prev_target)
		local ply = LocalPlayer()
		local found_left = {}
		local found_right = {}

		local center_x = prev_target and prev_target:GetPos():ToScreen().x or ScrW() / 2
		local ents = ents.FindInSphere(EyePos(), max_distance)

		for _, val in ipairs(ents) do
			if
				jrpg.IsActorAlive(val) and
				((val:IsPlayer() and val ~= ply) or (not val:IsPlayer() and jrpg.IsActor(val))) and
				(jtarget.friends_only == nil or (jtarget.friends_only and jrpg.IsFriend(LocalPlayer(), val)) or (not jtarget.friends_only and not jrpg.IsFriend(LocalPlayer(), val))) and
				val ~= prev_target and
				not util.TraceLine({start = ply:EyePos(), endpos = jrpg.FindHeadPos(val), filter = ents}).Hit
			then
				local pos = val:NearestPoint(val:WorldSpaceCenter() + Vector(0,0,100))
				pos = pos:ToScreen()

				if pos.x > center_x then
					table.insert(found_right, {pos = pos, ent = val})
				else
					table.insert(found_left, {pos = pos, ent = val})
				end
			end
		end

		table.sort(found_right, function(a, b)
			return (a.pos.x - center_x) < (b.pos.x - center_x)
		end)

		table.sort(found_left, function(a, b)
			return (a.pos.x - center_x) > (b.pos.x - center_x)
		end)

		return {right = found_right, left = found_left}
	end

	function jtarget.Scroll(delta)
		local ply = LocalPlayer()
		local prev_target = jtarget.GetEntity(ply)
		jtarget.prev_target = prev_target
		local targets = jtarget.GetTargetsOnScreen(prev_target:IsValid() and prev_target)

		if delta > 0 then
			if delta > #targets.right then
				if targets.left[1] then
					jtarget.SetEntity(ply, targets.left[#targets.left].ent)
				elseif targets.right[1] then
					jtarget.SetEntity(ply, targets.right[1].ent)
				end
			elseif targets.right[1] then
				jtarget.SetEntity(ply, targets.right[((delta - 1) % #targets.right) + 1].ent)
			else
				jtarget.SetEntity(ply, targets.right[1].ent)
			end
		elseif delta < 0 then
			if -delta > #targets.left then
				if targets.right[1] then
					jtarget.SetEntity(ply, targets.right[#targets.right].ent)
				elseif targets.left[1] then
					jtarget.SetEntity(ply, targets.left[1].ent)
				end
			elseif targets.left[1] then
				jtarget.SetEntity(ply, targets.left[((-delta - 1) % #targets.left) + 1].ent)
			else
				jtarget.SetEntity(ply, targets.left[1].ent)
			end
		end

		jtarget.scroll_dir = delta
	end

	do
		local ring_mat = CreateMaterial("battlecam_select_ring_" .. os.clock(), "UnlitGeneric", {
			["$BaseTexture"] = "particle/fire",
			["$VertexColor"] = 1,
			["$VertexAlpha"] = 1,
			["$Additive"] = 1,
		})
		local urlimage = requirex("urlimage")
		ring_mat = urlimage.URLMaterial("https://raw.githubusercontent.com/PAC3-Server/ServerAssets/master/materials/pac_server/jrpg/arrow.png")

		local size = 32

		local function draw_world_target(x, y)
			local w,h = ring_mat()
			if w then
				--surface.SetMaterial(ring_mat)
				surface.DrawTexturedRect(x - size/2, y - size, size, size)
			end
		end

		local function draw_screen_target(x, y, info)

		end

		local next_scroll = 0

		local ring_mat = CreateMaterial("battlecam_select_ring_" .. os.clock(), "UnlitGeneric", {
			["$BaseTexture"] = "sprites/animglow02",
			["$VertexColor"] = 1,
			["$VertexAlpha"] = 1,
			["$Additive"] = 1,
		})
	--ring_mat = Material("sprites/animglow02")
		local size = 20

		function jtarget.DrawSelection()
			local current_target = jtarget.GetEntity(LocalPlayer())
			if not current_target:IsValid() then return end

			if not jtarget.selecting then
				local pos = current_target:WorldSpaceCenter()
				pos = pos:ToScreen()
				if true or pos.Visible then

					surface.SetMaterial(ring_mat)

					surface.SetDrawColor(255, 255, 255, 200)
					surface.DrawTexturedRectRotated(pos.x, pos.y, size, size, os.clock()*10)

					if jrpg.IsFriend(LocalPlayer(), current_target) then
						surface.SetDrawColor(team.GetColor(TEAM_FRIENDS))
					else
						surface.SetDrawColor(team.GetColor(TEAM_PLAYERS))
					end
					surface.DrawTexturedRectRotated(pos.x, pos.y, size, size, os.clock()*10)
				end
				return
			end

			if hitmarkers then
				healthbars.ShowHealth(current_target, true)
			end

			local offset = 0

			if jtarget.select_timer then
				local f = jtarget.select_timer - RealTime()
				f = -f + 1
				f = f * 7
				f = f ^ 2

				if jtarget.prev_target:IsValid() then
					current_target = jtarget.prev_target
				end

--				offset = f*180*-jtarget.scroll_dir
			end

			local targets = jtarget.GetTargetsOnScreen(current_target)

			local pos = current_target:NearestPoint(current_target:WorldSpaceCenter() + Vector(0,0,100))
			pos = pos:ToScreen()

			surface.SetDrawColor(255, 255, 255, 50)

			for i, info in ipairs(targets.left) do
				jhud.DrawInfoSmall(info.ent, info.pos.x, info.pos.y - 50, -(i / #targets.left - 0.8 ^ 5) + 1, jrpg.IsFriend(LocalPlayer(), info.ent) and team.GetColor(TEAM_FRIENDS) or team.GetColor(TEAM_PLAYERS))
				--draw_world_target(info.pos.x, info.pos.y, 0.25)
			end

			if jrpg.IsFriend(LocalPlayer(), current_target) then
				surface.SetDrawColor(team.GetColor(TEAM_FRIENDS))
			else
				surface.SetDrawColor(team.GetColor(TEAM_PLAYERS))
			end

			draw_world_target(offset + pos.x, pos.y - 50 + math.sin(RealTime()*20) * 3, 1, ent)
			jhud.DrawInfoSmall(current_target, offset + pos.x, pos.y - 50, 1, jrpg.IsFriend(LocalPlayer(), current_target) and team.GetColor(TEAM_FRIENDS) or team.GetColor(TEAM_PLAYERS))

			surface.SetDrawColor(255, 255, 255, 50)

			for i, info in ipairs(targets.right) do
				jhud.DrawInfoSmall(info.ent, info.pos.x, info.pos.y - 50, -(i / #targets.right - 0.8 ^ 5) + 1, jrpg.IsFriend(LocalPlayer(), info.ent) and team.GetColor(TEAM_FRIENDS) or team.GetColor(TEAM_PLAYERS))
				--draw_world_target(info.pos.x, info.pos.y, 0.25)
			end
		end
	end

	function jtarget.StartSelection(friends_only)
		if jtarget.selecting then return end

		jtarget.selecting = true
		jtarget.Scroll(1)
		jtarget.Scroll(-1)
		jtarget.friends_only = friends_only

		hook.Add("HUDShouldDraw", "jtarget", function(what)
			if what == "JHitmarkers" and jtarget.GetEntity(LocalPlayer()):IsValid() then
				return false
			end
		end)
	end

	function jtarget.StopSelection()
		jtarget.selecting = false
		hook.Remove("HUDShouldDraw", "jtarget")
	end

	function jtarget.IsSelecting()
		return jtarget.selecting
	end

	hook.Add("HUDPaint", "jtarget", jtarget.DrawSelection)
end

jtarget.prev_target = NULL

function jtarget.SetEntity(ply, ent)
	ent = ent or NULL

	if CLIENT then
		jtarget.prev_ang = ply:EyeAngles()
		jtarget.select_timer = RealTime() + 1
	end

	if CLIENT then
		if ent:IsValid() then
			RunConsoleCommand("jtarget_select", ent:EntIndex())
		else
			RunConsoleCommand("jtarget_select")
		end
		ply.jtarget_ent = ent
		--ply:SetNW2Entity("jtarget", ent)
	end

	if SERVER then
		ply:SetNW2Entity("jtarget", ent)
	end
end

function jtarget.GetEntity(ply)
	if CLIENT and LocalPlayer() == ply and ply.jtarget_ent and ply.jtarget_ent:IsValid() then
		return ply.jtarget_ent
	end
	return ply:GetNW2Entity("jtarget")
end

local function get_aim_angles(ply)
	local ent = ply:GetNW2Entity("jtarget")
	if not ent:IsValid() then return end

	local head_pos = jrpg.FindHeadPos(ent)

	local aim_ang = (head_pos - ply:GetShootPos()):Angle()

	aim_ang.p = math.NormalizeAngle(aim_ang.p)
	aim_ang.y = math.NormalizeAngle(aim_ang.y)
	aim_ang.r = 0


	if jtarget.select_timer then
		local f = jtarget.select_timer - RealTime()
		f = -f + 1

		f = f * 7
		f = f ^ 4

		if f < 1 then
			aim_ang = LerpAngle(f, jtarget.prev_ang, aim_ang)
		else
			jtarget.select_timer = nil
		end
	end

	return aim_ang
end

if CLIENT then
	hook.Add("CreateMove", "jtarget", function(mv)
		if jtarget.pause_aiming then return end
		local ang = get_aim_angles(LocalPlayer())

		if ang then

			local ent = jtarget.GetEntity(LocalPlayer())

			if not jrpg.IsActorAlive(ent) then
				if not ent.jtarget_scrolled then
					ent.jtarget_scrolled = true
					jtarget.Scroll(1)

					if jtarget.GetEntity(LocalPlayer()) == ent then
						jtarget.SetEntity(LocalPlayer())

						battlecam.focus_ent = ent.jrpg_rag_ent
						battlecam.focus_time = RealTime() + 1
					end
				end
			end

			if not LocalPlayer():Alive() or ent:GetPos():Distance(LocalPlayer():GetPos()) > max_distance then
				jtarget.SetEntity(LocalPlayer())
			end

			mv:SetViewAngles(ang)
		end
	end)

	hook.Add("InputMouseApply", "jtarget", function(mv, x, y)
		if math.abs(x) > 1000 or math.abs(y) > 1000 then
			jtarget.SetEntity(LocalPlayer())
			jtarget.StopSelection()
		end
	end)
end

hook.Add("Move", "jtarget", function(ply)
	if jtarget.pause_aiming then return end

	local ang = get_aim_angles(ply)

	if ang then
		ply:SetEyeAngles(ang)
	end
end)

if SERVER then
	concommand.Add("jtarget_select", function(ply, _, _, ent_id)
		ent_id = ent_id:gsub("\"", "")
		ent_id = tonumber(ent_id)
		if ent_id then
			local ent = Entity(ent_id)
			if ent:IsValid() then
				jtarget.SetEntity(ply, ent)
				return
			end
			return
		end

		jtarget.SetEntity(ply)
	end)
end