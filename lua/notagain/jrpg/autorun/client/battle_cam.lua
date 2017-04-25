local prettytext = requirex("pretty_text")

local function FrameTime()
	return math.Clamp(_G.FrameTime(), 0, 0.1)
end

battlecam = battlecam or {}

local joystick_remap = {
	[KEY_XBUTTON_A] = IN_JUMP,
	[KEY_XBUTTON_X] = IN_SPEED,
	[KEY_XBUTTON_B] = IN_USE,

	[KEY_XBUTTON_STICK1] = IN_DUCK,

	[KEY_XSTICK1_UP] = IN_FORWARD,
	[KEY_XSTICK1_DOWN] = IN_BACK,
	[KEY_XSTICK1_LEFT] = IN_MOVELEFT,
	[KEY_XSTICK1_RIGHT] = IN_MOVERIGHT,

	[KEY_XBUTTON_RTRIGGER] = IN_ATTACK,
	[KEY_XBUTTON_LTRIGGER] = IN_ATTACK2,
}

local mouse_buttons = {
	[MOUSE_MIDDLE] = true,
}

local name_to_key = {}

for i = 1, 256 do
	local name = input.GetKeyName(i)
	if name then
		name_to_key[name] = i
	end
end

function battlecam.IsKeyDown(key)
	if key == "target" then
		return input.IsButtonDown(KEY_XBUTTON_STICK2) or input.IsMouseDown(MOUSE_MIDDLE)
	elseif key == "select_left" then
		if battlecam.select_left then
			return true
		end
		return input.IsKeyDown(KEY_LEFT) or input.IsButtonDown(KEY_XBUTTON_LEFT)
	elseif key == "select_right" then
		if battlecam.select_right then
			return true
		end
		return input.IsKeyDown(KEY_RIGHT) or input.IsButtonDown(KEY_XBUTTON_RIGHT)
	elseif key == "attack" then
		return input.IsButtonDown(KEY_XBUTTON_RTRIGGER) or input.IsButtonDown(KEY_XBUTTON_LTRIGGER)
	end
end

local HOOK = function(event) hook.Add(event, "battlecam", battlecam[event]) end
local UNHOOK = function(event) hook.Remove(event, "battlecam") end

function battlecam.LimitAngles(pos, dir, fov, prevpos)
	local a1 = dir:Angle()
	local a2 = (pos - prevpos):Angle()

	fov = fov / 3
	dir = a2:Forward() *-1

	a1.p = a2.p + math.Clamp(math.AngleDifference(a1.p, a2.p), -fov, fov)
	fov = fov / (ScrH()/ScrW())
	a1.y = a2.y + math.Clamp(math.AngleDifference(a1.y, a2.y), -fov, fov)

	a1.p = math.NormalizeAngle(a1.p)
	a1.y = math.NormalizeAngle(a1.y)

	return LerpVector(math.Clamp(Angle(0, a1.y, 0):Forward():DotProduct(dir), 0, 1), a1:Forward(), dir * -1)
end


function battlecam.FindHeadPos(ent)
	if not ent.bc_head or ent.bc_last_mdl ~= ent:GetModel() then
		for i = 0, ent:GetBoneCount() do
			local name = ent:GetBoneName(i):lower()
			if name:find("head") then
				ent.bc_head = i
				ent.bc_last_mdl = ent:GetModel()
				break
			end
		end
	end

	if ent.bc_head then
		local m = ent:GetBoneMatrix(ent.bc_head)
		if m then
			local pos = m:GetTranslation()
			if pos ~= ent:GetPos() then
				return pos
			end
		end
	end

	return ent:EyePos(), ent:EyeAngles()
end

function battlecam.CreateCrosshair()
	for _, v in pairs(ents.GetAll()) do
		if v.battlecam_crosshair then
			SafeRemoveEntity(v)
		end
	end

	local ent = ClientsideModel("models/hunter/misc/cone1x05.mdl")

	ent:SetMaterial("models/shiny")

	local mat = Matrix()
		mat:SetAngles(Angle(-90,0,0))
		mat:Scale(Vector(1,1,2) * 0.25)
		mat:Translate(Vector(0,0,-25))
	ent:EnableMatrix("RenderMultiply", mat)

	ent.RenderOverride = function(ent)
		local c = Vector(GetConVarString("cl_weaponcolor")) * 1.5

		if battlecam.selected_enemy:IsValid() then
			if jrpg.IsFriend(battlecam.selected_enemy) then
				c = Vector(0.5,1,0.5)*2
			else
				c = Vector(1,0.5,0.5)*2
			end
		end

		render.SetColorModulation(c.r ^ 10, c.g ^ 10, c.b ^ 10)
			render.SetBlend(0.75)
				ent:DrawModel()
			render.SetBlend(1)
		render.SetColorModulation(1, 1, 1)
	end

	ent.battlecam_crosshair = true

	battlecam.crosshair_ent = ent
end

local cvar = CreateClientConVar("battlecam_enabled", "0", false, true)

function battlecam.Enable()
	RunConsoleCommand("joystick", "0")
	RunConsoleCommand("joy_advanced", "0")

	for _, v in pairs(ents.GetAll()) do
		if v.battlecam_crosshair then
			SafeRemoveEntity(v)
		end
	end

	HOOK("CalcView")
	HOOK("InputMouseApply")
	HOOK("CreateMove")
	HOOK("PlayerBindPress")
	HOOK("HUDShouldDraw")
	HOOK("ShouldDrawLocalPlayer")
	HOOK("PreDrawHUD")
	HOOK("PostDrawHUD")

	battlecam.enabled = true
	battlecam.aim_pos = Vector()
	battlecam.aim_dir = Vector()
	--battlecam.CreateCrosshair()
	--battlecam.CreateHUD()

	battlecam.enemy_visibility = 0
	battlecam.player_visibility = 0

	battlecam.pixvis = util.GetPixelVisibleHandle()
	battlecam.pixvis2 = util.GetPixelVisibleHandle()

	cvar:SetInt(1)
end

function battlecam.Disable()
	UNHOOK("CalcView")
	UNHOOK("InputMouseApply")
	UNHOOK("CreateMove")
	UNHOOK("PlayerBindPress")
	UNHOOK("HUDShouldDraw")
	UNHOOK("ShouldDrawLocalPlayer")
	UNHOOK("PreDrawHUD")
	UNHOOK("PostDrawHUD")

	battlecam.enabled = false

	--SafeRemoveEntity(battlecam.crosshair_ent)
	--battlecam.crosshair_ent = NULL
	battlecam.selected_enemy = NULL
	battlecam.want_select = false

	battlecam.DestroyHUD()
	cvar:SetInt(0)
end

function battlecam.IsEnabled()
	return battlecam.enabled
end

-- hooks

do -- view
	battlecam.cam_speed = 6

	battlecam.cam_pos = Vector()
	battlecam.cam_dir = Vector()
	battlecam.free_cam_dir = Vector()

	local smooth_pos = Vector()
	local smooth_dir = Vector()
	local smooth_roll = 0
	local smooth_fov = 0

	local smooth_visible = 0
	local smooth_visible_offset = 0

	local last_pos = Vector()

	function battlecam.CalcView()
		local ply = LocalPlayer()
		battlecam.aim_pos = ply:GetShootPos()
		battlecam.aim_dir = (ply:EyePos() - battlecam.cam_pos):GetNormalized()

		--if not battlecam.crosshair_ent:IsValid() then
			--battlecam.CreateCrosshair()
		--end

		--battlecam.SetupCrosshair(battlecam.crosshair_ent)

		local delta = FrameTime()
		local target_pos = battlecam.aim_pos * 1
		local target_dir = battlecam.aim_dir * 1
		local target_fov = 60

		-- roll
		local target_roll = 0--math.Clamp(-smooth_dir:Angle():Right():Dot(last_pos - smooth_pos)  * delta * 40, -30, 30)
		last_pos = smooth_pos

		local lerp_thing = 0

		-- do a more usefull and less cinematic view if we're holding ctrl
		if (input.IsButtonDown(KEY_PAD_5) or input.IsMouseDown(MOUSE_MIDDLE) or input.IsButtonDown(KEY_XBUTTON_STICK2)) and not battlecam.selected_enemy:IsValid() then
			battlecam.aim_dir = ply:GetAimVector()
			target_dir = battlecam.aim_dir * 1
			target_pos = target_pos + battlecam.aim_dir * - 175

			delta = delta * 2
		else
			local ent = battlecam.selected_enemy

			if ent:IsValid() then
				local enemy_size = math.min(ent:BoundingRadius() * (ent:GetModelScale() or 1), 200)

				local ply_pos = ply:EyePos()

				local dist = math.min((enemy_size/4)/ent:NearestPoint(ply:GetPos()):Distance(ply:NearestPoint(ent:GetPos())), 1)
				local ent_pos = LerpVector(math.max(dist, 0.5), battlecam.FindHeadPos(ent), ent:NearestPoint(ent:EyePos()))

				local offset = ent_pos - ply_pos

				--offset:Rotate(Angle(smooth_visible*-offset.z/10,0,0))
				offset:Rotate(Angle(0,battlecam.target_cam_rotation.y,0))

				local p = battlecam.target_cam_rotation.p
				offset.z = p


				target_pos = (LerpVector(0.5, ply_pos, ent_pos) - offset/2) + offset:GetNormalized() * (-enemy_size + (smooth_visible*-500))

				lerp_thing = (((target_pos:Distance(ent_pos) - target_pos:Distance(ply_pos)) / offset:Length()) / 1.5) * 0.5 + 0.5
				target_dir = (LerpVector(lerp_thing, ent_pos, ply_pos) - target_pos)

				local visible = (battlecam.player_visibility * battlecam.enemy_visibility) * 2 - 1

				smooth_visible = smooth_visible + ((-visible - smooth_visible) * delta)

				target_fov = target_fov + math.Clamp(smooth_visible*50, -40, 20) - 30
			else
				local inside_sphere = math.max(math.Clamp((smooth_pos:Distance(ply:EyePos()) / 240), 0, 1) ^ 10 - 0.05, 0)
				target_pos = Lerp(inside_sphere, smooth_pos, ply:EyePos())

				local cam_ang = smooth_dir:Angle()
				cam_ang:Normalize()

				if cam_ang.p >= 89 then
					cam_ang.y = math.NormalizeAngle(cam_ang.y + 180)
				end

				local right = cam_ang:Right() * FrameTime() * - battlecam.cam_rotation_velocity.y
				local up = cam_ang:Up() * FrameTime() * battlecam.cam_rotation_velocity.x

				smooth_pos = smooth_pos + right*1500 + up*1500
				smooth_dir = smooth_dir - right*8 - up*8


				do -- trace block
					local data = util.TraceLine({
						start = ply:NearestPoint(smooth_pos),
						endpos = smooth_pos,
						filter = ents.FindInSphere(ply:GetPos(), ply:BoundingRadius()),
						mask =  MASK_VISIBLE,
					})

					if data.Hit and data.Entity ~= ply and not data.Entity:IsPlayer() and not data.Entity:IsVehicle() then
						smooth_pos = data.HitPos--Lerp(inside_sphere, battlecam.cam_pos, data.HitPos)
					end
				end

				do
					local hack = math.min((battlecam.cam_pos * Vector(1,1,0)):Distance(ply:EyePos() * Vector(1,1,0)) / 300, 1) ^ 1.5
					battlecam.last_flip_walk = battlecam.last_flip_walk or 0
					if hack < 0.01 and not battlecam.flip_walk and battlecam.last_flip_walk < RealTime() and ply:GetVelocity():Length() > 190 then
						battlecam.flip_walk = true
						battlecam.last_flip_walk = RealTime() + 0.1
					end
				end
			end
		end

		-- smoothing
		smooth_pos = smooth_pos + ((target_pos - smooth_pos) * delta * battlecam.cam_speed)
		smooth_dir = smooth_dir + ((target_dir - smooth_dir) * delta * battlecam.cam_speed)
		smooth_fov = smooth_fov + ((target_fov - smooth_fov) * delta * battlecam.cam_speed)
		smooth_roll = smooth_roll + ((target_roll - smooth_roll) * delta * battlecam.cam_speed)

		if battlecam.selected_enemy:IsValid() then
			local data = util.TraceLine({
				start = ply:NearestPoint(smooth_pos),
				endpos = smooth_pos,
				filter = ents.FindInSphere(ply:GetPos(), ply:BoundingRadius()),
				mask =  MASK_VISIBLE,
			})

			if data.Hit and data.Entity ~= ply and not data.Entity:IsPlayer() and not data.Entity:IsVehicle() then
				smooth_pos = data.HitPos
				--battlecam.target_cam_rotation.y = battlecam.target_cam_rotation.y - (lerp_thing*2-1)*0.1
			end
		end

		battlecam.cam_pos = smooth_pos
		battlecam.cam_dir = smooth_dir

		battlecam.cam_rotation_velocity:Zero()

		-- return
		local params = {}

		params.origin = smooth_pos
		params.angles = smooth_dir:Angle()
		params.angles.r = smooth_roll
		params.fov = smooth_fov
		params.znear = 20

		return params
	end
end

function battlecam.SetupCrosshair(ent)
	local enemy = battlecam.selected_enemy

	if enemy:IsValid() then
		ent:SetPos(battlecam.FindHeadPos(enemy) + enemy:GetUp() * (15 + math.sin(RealTime() * 20)))
		ent:SetAngles(Angle(-90,0,0))
	else
		local ply = LocalPlayer()
		local trace_res = util.QuickTrace(battlecam.aim_pos, ply:GetAimVector() * 2500, {ply, ply:GetVehicle()})

		ent:SetPos(trace_res.HitPos + Vector(0, 0, math.sin(RealTime() * 10)))
		ent:SetAngles(trace_res.HitNormal:Angle())
	end
end


do -- selection
	battlecam.selected_enemy = NULL

	local last_enemy_target = 0
	local last_enemy_scroll = 0

	function battlecam.SelectTarget(ent)
		battlecam.selected_enemy = ent or NULL

		if battlecam.selected_enemy:IsValid() then
			if hitmarkers then
				hitmarkers.ShowHealth(ent, true)
			end
			battlecam.target_cam_rotation = Angle(-30,0,0)
		end
	end

	function battlecam.CalcEnemySelect()
		local ply = LocalPlayer()

		local target = battlecam.selected_enemy

		if target:IsValid() and not target.battlecam_probably_dead then
			battlecam.last_target_pos = target:GetPos()

			if battlecam.IsKeyDown("target") and last_enemy_target < RealTime() or target:GetPos():Distance(ply:GetPos()) > 1000 then
				battlecam.SelectTarget()
				last_enemy_target = RealTime() + 0.25
			end

			if target:IsNPC() then
				for _, val in ipairs(ents.FindInSphere(target:GetPos(), 500)) do
					if val:GetRagdollOwner() == target then
						battlecam.SelectTarget()
						target.battlecam_probably_dead = true
						last_enemy_target = 0
						return
					end
				end
			end

			if battlecam.IsKeyDown("select_left") or battlecam.IsKeyDown("select_right") then
				if last_enemy_scroll < RealTime() then

					local found_left = {}
					local found_right = {}

					local center = target:GetPos():ToScreen()
					local ents = ents.FindInSphere(battlecam.cam_pos, 1000)
					for _, val in ipairs(ents) do
						if
							not jrpg.IsFriend(val) and
							val ~= target and
							not util.TraceLine({start = ply:EyePos(), endpos = val:EyePos(), filter = ents}).Hit
						then
							local pos = val:GetPos():ToScreen()

							if pos.x > center.x then
								table.insert(found_right, {pos = pos, ent = val})
							else
								table.insert(found_left, {pos = pos, ent = val})
							end
						end
					end

					table.sort(found_right, function(a, b)
						return (a.pos.x - center.x) < (b.pos.x - center.x)
					end)

					table.sort(found_left, function(a, b)
						return (a.pos.x - center.x) > (b.pos.x - center.x)
					end)

--[[
					for k,v in pairs(found_left) do
						debugoverlay.Cross(v.ent:GetPos()+Vector(0,0,100), 5, 1, Color(255,0,0,255))
						debugoverlay.Text(v.ent:GetPos()+Vector(0,0,100), k, 1, Color(255,0,0,255))
					end

					for k,v in pairs(found_right) do
						debugoverlay.Cross(v.ent:GetPos()+Vector(0,0,100), 5, 1, Color(0,255,0,255))
						debugoverlay.Text(v.ent:GetPos()+Vector(0,0,100), k, 1, Color(255,0,0,255))
					end
]]

					local found

					if battlecam.IsKeyDown("select_right") then
						found = found_right[1]
						if not found or found.ent == battlecam.selected_enemy then
							found = found_left[#found_left]
						end
					else
						found = found_left[1]
						if not found or found.ent == battlecam.selected_enemy then
							found = found_right[#found_right]
						end
					end

					if found then
						battlecam.SelectTarget(found.ent)
						last_enemy_scroll = RealTime() + 0.15
					end
				end
			else
				last_enemy_scroll = 0
			end
		elseif battlecam.IsKeyDown("target") and last_enemy_target < RealTime() then
			local data = ply:GetEyeTrace()

			if not data.Entity:IsValid() then
				local end_pos = battlecam.aim_pos + (battlecam.aim_dir * 2000)
				local filter = ents.FindInSphere(end_pos, 50)
				table.insert(filter, ply)
				data = util.TraceHull({
					start = battlecam.aim_pos,
					endpos = end_pos,
					mins = ply:OBBMins(),
					maxs = ply:OBBMaxs(),
					filter = filter,
				})
			end

			local ent = data.Entity

			if ent:IsValid() and (ent:IsPlayer() or ent:IsNPC()) and battlecam.selected_enemy ~= ent and ent ~= LocalPlayer() and not ent.battlecam_probably_dead then
				battlecam.SelectTarget(ent)
				last_enemy_target = RealTime() + 0.25
			else
				local origin = (battlecam.last_target_pos and battlecam.last_target_pos:Distance(ply:GetPos()) < 500 and battlecam.last_target_pos) or ply:GetPos()
				local found = {}
				local ents = ents.FindInSphere(origin, 500)

				for _, val in ipairs(ents) do
					if
						not val.battlecam_probably_dead and
						not jrpg.IsFriend(val) and
						not util.TraceLine({start = ply:EyePos(), endpos = val:EyePos(), filter = ents}).Hit
					then
						table.insert(found, val)
					end
				end

				if found[1] then
					table.sort(found, function(a, b) return a:EyePos():Distance(origin) < b:EyePos():Distance(origin) end)
					battlecam.SelectTarget(found[1])
					last_enemy_target = RealTime() + 0.25
				end
			end
		end
	end
end

battlecam.weapon_i = 1
battlecam.last_select = 0

function battlecam.GetWeapons()
	local ply = LocalPlayer()
	battlecam.weapons = table.ClearKeys(ply:GetWeapons())
	table.sort(battlecam.weapons, function(a, b)return a:EntIndex() < b:EntIndex() end)
	return battlecam.weapons
end

function battlecam.GetWeaponIndex()
	return battlecam.weapon_i%#battlecam.GetWeapons() + 1
end

do
	local smooth_dir = Vector()
	battlecam.target_cam_rotation = Angle()
	battlecam.cam_rotation_velocity = Vector()

	local buttons = {}
	for k, v in pairs(_G) do
		if type(k) == "string" and type(v) == "number" then
			if k:StartWith("KEY_") then
				buttons[k] = v
			end
		end
	end

	function battlecam.PlayerBindPress(ply, bind, press)
		for a, b in pairs(joystick_remap) do
			if input.IsButtonDown(a) then
				return true
			end
		end

		for a, b in pairs(mouse_buttons) do
			if input.IsMouseDown(a) then
				return true
			end
		end
	end

	local smooth_x = 0
	local smooth_y = 0
	local last_select = 0

	function battlecam.InputMouseApply(ucmd, x, y, ang)
		smooth_x = smooth_x + ((x - smooth_x) * FrameTime() * 10)
		smooth_y = smooth_y + ((y - smooth_y) * FrameTime() * 10)

		battlecam.cam_rotation_velocity.y = smooth_x / 60
		battlecam.cam_rotation_velocity.x = smooth_y / 60

		local ent = battlecam.selected_enemy

		if ent:IsValid() and last_select < RealTime() then
			if x > 250 then
				battlecam.select_right = true
				last_select = RealTime() + 0.5
			elseif x < -250 then
				battlecam.select_left = true
				last_select = RealTime() + 0.5
			end
		else
			battlecam.select_left = nil
			battlecam.select_right = nil
		end

		return true
	end

	local smooth_forward = 0
	local reset_forward = false

	function battlecam.CreateMove(ucmd)
		local ply = LocalPlayer()

		do -- joystick bindings
			--for key, val in pairs(buttons) do if input.IsButtonDown(val) then print(key) end end

			for a, b in pairs(joystick_remap) do
				if input.IsButtonDown(a) then
					ucmd:SetButtons(bit.bor(ucmd:GetButtons(), b))

					if battlecam.selected_enemy:IsValid() then
						if b == IN_MOVELEFT then
							ucmd:SetSideMove(-1000)
						elseif b == IN_MOVERIGHT then
							ucmd:SetSideMove(1000)
						end

						if b == IN_FORWARD then
							ucmd:SetForwardMove(1000)
						elseif b == IN_BACK then
							ucmd:SetForwardMove(-1000)
						end
					end
				end
			end
		end

		do
			if input.IsButtonDown(KEY_PAD_5) or input.IsButtonDown(KEY_XBUTTON_STICK2) then
				battlecam.target_cam_rotation = Angle(-30,0,0)
			end

			if input.IsButtonDown(KEY_XSTICK2_RIGHT) or input.IsButtonDown(KEY_PAD_6) then
				battlecam.target_cam_rotation.y = battlecam.target_cam_rotation.y - FrameTime()*20
				battlecam.cam_rotation_velocity.y = FrameTime()*15
			elseif input.IsButtonDown(KEY_XSTICK2_LEFT) or input.IsButtonDown(KEY_PAD_4) then
				battlecam.target_cam_rotation.y = battlecam.target_cam_rotation.y + FrameTime()*20
				battlecam.cam_rotation_velocity.y = -FrameTime()*15
			end

			if input.IsButtonDown(KEY_XSTICK2_UP) or input.IsButtonDown(KEY_PAD_8) then
				battlecam.target_cam_rotation.p = battlecam.target_cam_rotation.x - FrameTime()*20
				battlecam.cam_rotation_velocity.x = FrameTime()*8
			elseif input.IsButtonDown(KEY_XSTICK2_DOWN) or input.IsButtonDown(KEY_PAD_2) then
				battlecam.target_cam_rotation.p = battlecam.target_cam_rotation.x + FrameTime()*40
				battlecam.cam_rotation_velocity.x = -FrameTime()*8
			end

			battlecam.target_cam_rotation:Normalize()
		end

		if battlecam.IsKeyDown("attack") and not ucmd:KeyDown(IN_ATTACK) then
			ucmd:SetButtons(bit.bor(ucmd:GetButtons(), IN_ATTACK))
		end

--[[
		if ucmd:KeyDown(IN_SPEED) and ply:GetVelocity() == vector_origin then
			ucmd:SetButtons(bit.bor(ucmd:GetButtons(), IN_USE))
		end
]]
		if not ply:Alive() or vgui.CursorVisible() then return end

		battlecam.CalcEnemySelect()

		local ent = battlecam.selected_enemy

		if ent:IsValid() then

			if ent:IsPlayer() and (not ent:Alive() or not ply:Alive()) then
				battlecam.SelectTarget()
			end

			local head_pos = battlecam.FindHeadPos(ent)
			local aim_ang = (head_pos - ply:GetShootPos()):Angle()

			aim_ang.p = math.NormalizeAngle(aim_ang.p)
			aim_ang.y = math.NormalizeAngle(aim_ang.y)
			aim_ang.r = 0

			ucmd:SetViewAngles(aim_ang)
		end


		if battlecam.last_select < RealTime() then
			if input.IsKeyDown(KEY_LEFT) or input.IsButtonDown(KEY_XBUTTON_LEFT) then
				battlecam.weapon_i = battlecam.weapon_i + 1
				battlecam.last_select = RealTime() + 0.15
			elseif input.IsKeyDown(KEY_RIGHT) or input.IsButtonDown(KEY_XBUTTON_RIGHT) then
				battlecam.weapon_i = battlecam.weapon_i - 1
				battlecam.last_select = RealTime() + 0.15
			end
		else
			local wep = battlecam.GetWeapons()[battlecam.GetWeaponIndex()]

			if wep then
				ucmd:SelectWeapon(wep)
			end
		end

		if not ucmd:KeyDown(IN_ATTACK) and not ply:KeyDown(IN_DUCK) and not ucmd:KeyDown(IN_ATTACK2) and (not ent:IsValid() or ucmd:KeyDown(IN_SPEED)) then

			local dir = Vector()
			local pos = ply:GetPos()

			if ucmd:KeyDown(IN_MOVELEFT) then
				dir = (pos - battlecam.cam_pos):Angle():Right() * -1
			elseif ucmd:KeyDown(IN_MOVERIGHT) then
				dir = (pos - battlecam.cam_pos):Angle():Right()
			end

			if battlecam.flip_walk then
				dir = dir * -1
			end

			if ucmd:KeyDown(IN_FORWARD) then
				dir = dir + (pos - battlecam.cam_pos):Angle():Forward()
			elseif ucmd:KeyDown(IN_BACK) then
				dir = dir + (pos - battlecam.cam_pos):Angle():Forward() * -1
			else
				battlecam.flip_walk = nil
			end

			if battlecam.flip_walk then
				dir = dir * -1
			end

			dir.z = 0

			if dir ~= Vector(0,0,0) then
				smooth_dir = smooth_dir + ((dir - smooth_dir) * FrameTime() * 10)
				ucmd:SetViewAngles(smooth_dir:Angle())

				ucmd:SetForwardMove(10000)
				ucmd:SetSideMove(0)
			end
		end

		if pac and pac.CreateMove then
			pac.CreateMove(ucmd)
		end
	end
end

function battlecam.HUDShouldDraw(hud_type)
	if
		hud_type == "CHudCrosshair" --[[or
		hud_type == "CHudHealth" or
		hud_type == "CHudBattery" or
		hud_type == "CHudAmmo" or
		hud_type == "CHudSecondaryAmmo" or
		hud_type == "CHudWeaponSelection"
		]]
	then
		return false
	end
end

function battlecam.ShouldDrawLocalPlayer()
	return true
end

do
	battlecam.entities = battlecam.entities or {}

	local function create_ent(path, pos, ang, scale, tex)
		local ent = ClientsideModel(path)
		ent:SetNoDraw(true)
		ent:SetPos(pos)
		ent:SetAngles(ang)

		if type(scale) == "Vector" then
			local m = Matrix()
			m:Scale(Vector(scale))
			ent.matrix = m
			ent:EnableMatrix("RenderMultiply", m)
		else
			ent:SetModelScale(scale or 1)
		end
		ent:SetLOD(0)

		local mat

		if tex then
			mat = CreateMaterial("battlecam_" .. path ..tostring({}), "VertexLitGeneric", {["$basetexture"] = tex})
		else
			mat = CreateMaterial("battlecam_" .. path ..tostring({}), "VertexLitGeneric")
			mat:SetTexture("$basetexture", Material(ent:GetMaterials()[1]):GetTexture("$basetexture"))
		end

		function ent:RenderOverride()
			render.MaterialOverride(mat)
			ent:SetupBones()
			ent:DrawModel()
			render.MaterialOverride()
		end

		table.insert(battlecam.entities, ent)

		return ent
	end

	function battlecam.DestroyHUD()
		for _, ent in pairs(battlecam.entities) do
			SafeRemoveEntity(ent)
		end
		battlecam.entities = {}
	end

	function battlecam.CreateHUD()
		local sx = ScrW() / 1980
		local sy = ScrH() / 1050

		do
			local x = 65*sx
			local y = ScrH() - 140*sy

			x = x * 1/sx
			y = y * 1/sy

			local combine_scanner_ent = create_ent("models/combine_scanner.mdl", Vector(x+150,y-38,1000), Angle(-90,-90-45,0), 10)
			combine_scanner_ent:SetSequence(combine_scanner_ent:LookupSequence("flare"))

			local suit_charger_ent = create_ent("models/props_combine/suit_charger001.mdl", Vector(x+350,y-20,0), Angle(-90,0,0), 10)
			suit_charger_ent:SetSequence(suit_charger_ent:LookupSequence("idle"))

			local health_bar_bg = create_ent("models/props_combine/combine_train02a.mdl", Vector(x+645,y-5,300), Angle(0,-90,0), Vector(0.2,1.27,1))
			local health_bar = create_ent("models/hunter/plates/plate1x1.mdl", Vector(x+640,y-5,600), Angle(90,90,0), Vector(1,3,0.7) * 6, "decals/light")


			local mana_bar_bg = create_ent("models/props_combine/combine_train02a.mdl", Vector(x+445,y-20,300), Angle(0,-90,0), Vector(0.125,0.75,1))
			local mana_bar = create_ent("models/hunter/plates/plate1x1.mdl", Vector(x+640,y-20,600), Angle(90,90,0), Vector(1,3,0.3) * 6, "decals/light")

			local smooth_hp = 100
			local smooth_armor = 100
			local smooth_hide_bar = 0
			local time = 0

			function battlecam.DrawHPMP()
				local ply = LocalPlayer()
				local cur_hp = ply:Health()
				local cur_armor = ply:Armor()

				smooth_hp = smooth_hp + ((cur_hp - smooth_hp) * FrameTime() * 5)
				smooth_armor = smooth_armor + ((cur_armor - smooth_armor) * FrameTime() * 5)

				local max_hp = ply:GetMaxHealth()
				local max_armor = 100

				local fract = smooth_hp / max_hp
				fract = fract ^ 0.3

				combine_scanner_ent:SetCycle(((-fract+1)^0.25) + (math.sin((-smooth_hide_bar+1)*math.pi)*0.25))
				suit_charger_ent:SetCycle(smooth_hide_bar)

				render.SetColorModulation(Lerp(fract, math.sin(time)+1.5, 1),Lerp(fract, 0.25, 1),Lerp(fract, 0.25, 1))
				time = time + FrameTime()*(7/fract)

				render.SuppressEngineLighting(true)

				cam.StartOrthoView(0,0,ScrW()*(1/sx),ScrH()*(1/sy))

					render.CullMode(MATERIAL_CULLMODE_CW)
						render.PushCustomClipPlane(Vector(0,1,0), 500)
							suit_charger_ent:DrawModel()
						render.PopCustomClipPlane()
						combine_scanner_ent:DrawModel()
					render.CullMode(MATERIAL_CULLMODE_CCW)

					-- armor
					render.SetColorModulation(1,1,1,1)
					mana_bar_bg:DrawModel()

					render.SetColorModulation(0.5,0.65,1.75)
					render.PushCustomClipPlane(Vector(-1,0,0), (-670 - x) * math.min(smooth_armor/max_armor, 1))
						mana_bar:DrawModel()
					render.PopCustomClipPlane()

					-- health

					do
						smooth_hide_bar = smooth_hide_bar + ((((battlecam.selected_enemy:IsValid() or battlecam.want_select) and 0 or 1) - smooth_hide_bar) * FrameTime() * 5)

						local m = Matrix()
						m:Scale(Vector(0.2,1.27 * Lerp(smooth_hide_bar, 1, 0.6),1))
						m:Translate(Vector(0,smooth_hide_bar*-245,0))
						health_bar_bg:EnableMatrix("RenderMultiply", m)

						render.SetColorModulation(1,1,1,1)
						health_bar_bg:DrawModel()


						render.SetColorModulation(0.5,1.75,0.65)
						render.PushCustomClipPlane(Vector(-1,0,0), (-1000 - x) * math.min(smooth_hp/max_hp, 1) * Lerp(smooth_hide_bar, 1, 0.69))
							health_bar:DrawModel()
						render.PopCustomClipPlane()
					end

					render.SetColorModulation(1,1,1)

					prettytext.Draw("HP", x + 260, y + 7, "candara", 30, 30, 2, Color(100, 255, 100, 200))
					prettytext.Draw(math.Round(smooth_hp), x + 300, y + 5, "candara", 30, 30, 2, Color(255, 255, 255, 200))

				cam.EndOrthoView()
			end
		end

		do
			local x = ScrW() - 220*sx
			local y = ScrH() - 175*sy

			x = x * 1/sx
			y = y * 1/sy

			local weapon_menu = create_ent("models/combine_helicopter/helicopter_bomb01.mdl", Vector(x,y), Angle(0,90,0), 7)
			local weapon_menu2 = create_ent("models/combine_dropship_container.mdl", Vector(x-80,y, -500), Angle(90,0,0), 1.9)
			local weapon_selection = create_ent("models/props_combine/combinetrain01a.mdl", Vector(x-5, y - 5, -500), Angle(0,0,0), Vector(0.8,0.45,1) * 0.5)

			local font_lookup = {
				["Pistol"] = "p",
				["SMG1"] = "\x72",
				["SMG1_Grenade"] = "\x5F",
				["357"] = "\x71",
				["AR2"] = "u",
				["AR2AltFire"] = "z",
				["Buckshot"] = "s",
				["XBowBolt"] = "w",
				["Grenade"] = "v",
				["RPG_Round"] = "x",
				["slam"] = "o",

				["weapon_smg1"] = "&",
				["weapon_shotgun"] = "(",
				["weapon_pistol"] = "%",
				["weapon_357"] = "$",
				["weapon_crossbow"] = ")",
				["weapon_ar2"] = ":",
				["weapon_frag"] = "_",
				["weapon_rpg"] = ";",
				["weapon_crowbar"] = "^",
				["weapon_stunstick"] = "n",
				["weapon_physcannon"] = "!",
				["weapon_physgun"] = "h",
				["weapon_bugbait"] = "~",
				["weapon_slam"] = "o",
			}

			function battlecam.DrawWeaponSelection()
				local ply = LocalPlayer()
				local weapons = battlecam.GetWeapons()

				if not weapons[1] then return end

				cam.StartOrthoView(0,0,ScrW()*(1/sx),ScrH()*(1/sy))
					render.CullMode(MATERIAL_CULLMODE_CW)

					render.PushCustomClipPlane(Vector(-1,0,0), -x)
						for i, wep in ipairs(weapons) do
							i = i + -battlecam.weapon_i
							i = i - #weapons / 2
							i = i + (0.25 * #weapons) - 1
							i = i / #weapons
							i = i * math.pi * 2

							wep.battlecam_smooth_i = wep.battlecam_smooth_i or 0
							wep.battlecam_smooth_i = wep.battlecam_smooth_i + ((i - wep.battlecam_smooth_i) * FrameTime() * 10)

							local i = wep.battlecam_smooth_i

							local x = x + math.sin(i) * 200
							local y = y + math.cos(i) * 50

							weapon_selection:SetRenderOrigin(Vector(x-5, y - 5, x*-40))
							weapon_selection:DrawModel()

							local name = wep:GetClass()

							if language.GetPhrase(name) then
								name = language.GetPhrase(name)
							end

							render.CullMode(MATERIAL_CULLMODE_CCW)
								surface.SetAlphaMultiplier(math.abs(math.sin(i)) ^ 3)
								prettytext.Draw(name, x-120, y-19, "candara", 26, 0, 4, Color(255, 255, 255, 150))
								surface.SetAlphaMultiplier(1)
							render.CullMode(MATERIAL_CULLMODE_CW)
						end
					render.PopCustomClipPlane()

					weapon_menu:DrawModel()
					weapon_menu2:DrawModel()

					render.CullMode(MATERIAL_CULLMODE_CCW)

					cam.IgnoreZ(true)

					local wep = LocalPlayer():GetActiveWeapon()
					if wep:IsValid() then
						local size = 200
						if wep.DrawWeaponSelection then
							wep:DrawWeaponSelection(x-size/2,y-size/4, size, size, 255)
						else
							local icon = font_lookup[wep:GetClass()]
							if icon then
								local w,h = prettytext.GetTextSize(icon, "HALFLIFE2", 150, 0)
								local m = Matrix()
								m:Translate(Vector(x-w/2 + w, y-h/2, 0))
								m:Scale(Vector(-1,1,1))
								cam.PushModelMatrix(m)
								render.CullMode(MATERIAL_CULLMODE_CW)
									surface.SetAlphaMultiplier(0.5)
									prettytext.Draw(icon, 0, -12, "HALFLIFE2", 1000, 0, 10, Color(200, 255, 255, 255))
									surface.SetAlphaMultiplier(1)
								render.CullMode(MATERIAL_CULLMODE_CCW)
								cam.PopModelMatrix()
							end
						end
					end
				cam.EndOrthoView()
			end
		end
	end
end

do
	local ring_mat = CreateMaterial("battlecam_select_ring_" .. os.clock(), "UnlitGeneric", {
		["$BaseTexture"] = "effects/splashwake3",
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
	})

	local size = 40

	function battlecam.PostDrawHUD()
		local enemy = battlecam.selected_enemy

		if enemy:IsValid() then
			local pos = enemy:WorldSpaceCenter()
			pos = pos:ToScreen()
			if true or pos.Visible then
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(ring_mat)
				surface.DrawTexturedRectRotated(pos.x, pos.y, size, size, os.clock()*10)
			end
		end
	end
end

function battlecam.PreDrawHUD()
	cam.IgnoreZ(true)

	surface.SetDrawColor(255,255,255,255)
	surface.SetAlphaMultiplier(1)
	--[[
	local grid_size = 9
	for i = 0, grid_size do
		i = i * ScrH() / grid_size
		surface.DrawLine(0,i, ScrW(),i)
	end
	for i = 0, grid_size do
		i = i * ScrW() / grid_size
		surface.DrawLine(i,0, i,ScrH())
	end]]

	surface.DisableClipping(true)
	render.SuppressEngineLighting(true)
	render.SetColorModulation(1,1,1)

	--battlecam.DrawHPMP()
	--battlecam.DrawWeaponSelection()

	render.SetColorModulation(1,1,1)
	render.SuppressEngineLighting(false)
	cam.IgnoreZ(false)
	surface.DisableClipping(false)

	battlecam.player_visibility = util.PixelVisible(LocalPlayer():EyePos(), LocalPlayer():BoundingRadius()*2, battlecam.pixvis)

	local ent = battlecam.selected_enemy
	if ent:IsValid() then
		battlecam.enemy_visibility = util.PixelVisible(ent:EyePos(), ent:BoundingRadius()*2, battlecam.pixvis2)
	end
end

concommand.Add("battlecam", function()
	if battlecam.IsEnabled() then
		battlecam.Disable()
	else
		battlecam.Enable()
	end
end)

if battlecam.IsEnabled() then
	battlecam.Disable()
	battlecam.Enable()
end