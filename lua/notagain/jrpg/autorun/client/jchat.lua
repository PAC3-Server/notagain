if jchat then
	jchat.Stop()
end

jchat = {}

jchat.random_seed = ""

function jchat.RandomSeed(min, max, seed)
	seed = seed or jchat.random_seed
	return util.SharedRandom(seed, min, max)
end

function jchat.Start(stop_cb)

	if jchat.IsActive() then
		jchat.Stop()
	end

	hook.Add("CalcView", "jchat", jchat.CalcView)
	hook.Add("RenderScreenspaceEffects", "jchat", jchat.RenderScreenspaceEffects)

	hook.Add("KeyPress", "jchat", function(ply, key)
		if key == IN_USE and jchat.HasPlayer(LocalPlayer()) then
			jchat.Stop()
			hook.Remove("KeyPress", "jchat")
		end
	end)

	hook.Add("HUDShouldDraw", "jchat", function(str)
		if str ~= "CHudWeaponSelection" and str ~= "CHudGMod" then
			return false
		end
	end)

	hook.Add("ShouldDrawLocalPlayer", "jchat", function()
		if jchat.HasPlayer(LocalPlayer()) then
			return true
		end
	end)

	hook.Add("NPCSpeak", "jchat", function(npc, str)
		if jchat.HasPlayer(npc) then
			local str = language.GetPhrase(str)
			if str then
				str = str:gsub("%b<>", ""):Trim()
				jchat.PlayerSay(npc, str)
			end
		end
	end)

	hook.Add("OnPlayerChat", "jchat", function(ply, str)
		if jchat.HasPlayer(ply) then
			jchat.PlayerSay(ply, str)
		end
	end)

	timer.Create("jchat_check_players", 0.2, 0, function()
		for ply in pairs(jchat.players) do
			if not jchat.CanChat(ply) then
				jchat.RemovePlayer(ply)
			end
		end
	end)

	jchat.active = true
	jchat.stop_cb = stop_cb
end

function jchat.Stop()
	if not jchat.IsActive() then return end

	jchat.players = {}
	jchat.active_player = NULL

	hook.Remove("CalcView", "jchat")
	hook.Remove("RenderScreenspaceEffects", "jchat")

	hook.Remove("HUDShouldDraw", "jchat")
	hook.Remove("OnPlayerChat", "jchat")
	hook.Remove("ShouldDrawLocalPlayer", "jchat")
	timer.Remove("jchat_check_players")

	jchat.active = false

	if jchat.stop_cb then
		jchat.stop_cb()
		jchat.stop_cb = nil
	end
end

function jchat.IsActive()
	return jchat.active
end

do -- players

	do -- manage
		jchat.players = {}

		function jchat.GetPlayers()
			return jchat.players
		end

		function jchat.HasPlayer(ply)
			return jchat.players[ply] and true or false
		end

		function jchat.AddPlayer(ply)
			if not jchat.CanChat(ply) then
				jchat.RemovePlayer(ply)
				return
			end

			jchat.players[ply] = ply
		end

		function jchat.RemovePlayer(ply)
			if jchat.active_player == ply then
				jchat.active_player = NULL
			end

			jchat.players[ply] = nil

			if ply == LocalPlayer() or (table.Count(jchat.players) == 1 and next(jchat.players) == LocalPlayer()) then
				jchat.Stop()
			end
		end
	end

	function jchat.SetActivePlayer(ply)
		if jchat.HasPlayer(ply) then
			jchat.active_player = ply
		end
	end

	function jchat.GetActivePlayer()
		return jchat.active_player or NULL
	end

	function jchat.CanChat(a)
		if not a:IsValid() then
			return false
		end

		local b = LocalPlayer()

		if b:GetVelocity():Length() > 300 then
			return false
		end

		if a == b then
			return true
		end

		if a:GetVelocity():Length() > 300 then
			return false
		end

		local apos = a:EyePos()
		local bpos = b:EyePos()

		if apos:Distance(bpos) > jchat.cam_distance then
			return false
		end

		if a:EyeAngles():Forward():Dot((apos - bpos):GetNormalized()) > 0.9 then
			return false
		end

		return true
	end

	function jchat.PlayerSay(ply, str)
		jchat.random_seed = str

		jchat.AddPlayer(ply)

		jchat.ChooseRandomCameraPos(ply)
		jchat.SetActivePlayer(ply)

		jchat.message = str
		jchat.wrapped_message = nil
		jchat.fade = 255
	end

end

do -- view
	jchat.cam_distance = 200
	jchat.smooth_speed = 2

	jchat.pos_smooth = vector_origin
	jchat.dir_smooth = vector_origin
	jchat.fov_smooth = 0

	jchat.pos_target = vector_origin
	jchat.dir_target = vector_origin
	jchat.fov_target = 75

	jchat.local_camera_pos = vector_origin
	jchat.angle_offset = Angle(0,0,0)

	function jchat.GetEyePos(ply)
		if ply:IsPlayer() and not ply:Alive() and ply:GetRagdollEntity() then
			ply = ply:GetRagdollEntity()
		end

		local id = ply:LookupBone("ValveBiped.Bip01_Head1")

		if not id then
			for i = 1, ply:GetBoneCount() do
				if ply:GetBoneName(i):lower():find("head") then
					id = i
					break
				end
			end
		end

		id = id or ply:LookupBone("ValveBiped.Bip01_Neck")

		if id then
			local pos, ang = ply:GetBonePosition(id)
			if pos:Distance(ply:GetPos()) > 10 then
				return pos + ang:Forward() * 2
			end
		end

		return ply:NearestPoint(ply:EyePos() + Vector(0,0,100)), ply:EyeAngles()
	end

	function jchat.ChooseRandomCameraPos(ply)
		local prev = jchat.GetActivePlayer()

		if prev ~= ply then
			ply = ply or prev

			if ply:IsValid() then
				jchat.local_camera_pos = Vector(jchat.RandomSeed(-1,1)*0.2, jchat.RandomSeed(-1,1)*0.2, jchat.RandomSeed(-1,0.5)*0.5)
				jchat.angle_offset = Angle(jchat.RandomSeed(-1,1)*2, jchat.RandomSeed(-1,1)*8, jchat.RandomSeed(-1,1))
				jchat.fov_target = jchat.RandomSeed(20, 50)

				jchat.new_angle = true
				jchat.panning_dir = Angle(0,0,0)
				jchat.panning_vel = jchat.RandomSeed(1,3) * jchat.angle_offset.y > 0 and -1 or 1
				jchat.pos_target = nil
			end
		end
	end

	function jchat.GetLocalCameraPos()
		local ply = jchat.GetActivePlayer()

		if ply:IsValid() then
			return (ply:EyeAngles():Forward() * Vector(1,1,0)) + jchat.local_camera_pos
		end

		return vector_origin
	end

	function jchat.GetWorldCameraPos()
		local middle = vector_origin
		local players = jchat.GetPlayers()

		for ply in pairs(jchat.GetPlayers()) do
			middle = middle + jchat.GetEyePos(ply)
		end

		if middle ~= vector_origin then
			middle = middle / table.Count(players)
		end

		local ply = jchat.GetActivePlayer()

		return LerpVector(0.2, jchat.GetEyePos(ply) + (jchat.GetLocalCameraPos() * (jchat.cam_distance * 0.5)), middle)
	end

	function jchat.CalcSmooth()
		local delta = FrameTime()

		jchat.pos_smooth = jchat.pos_smooth + ((jchat.pos_target - jchat.pos_smooth) * (delta * jchat.smooth_speed))
		jchat.dir_smooth = jchat.dir_smooth + ((jchat.dir_target - jchat.dir_smooth) * (delta * jchat.smooth_speed))
		jchat.fov_smooth = jchat.fov_smooth + ((jchat.fov_target - jchat.fov_smooth) * (delta * jchat.smooth_speed))
	end

	jchat.panning_dir = Angle(0,0,0)
	jchat.panning_vel = 0

	function jchat.CalcPanning()
		if math.abs(jchat.panning_dir.y) < 5 then
			jchat.panning_dir = jchat.panning_dir + (Angle(0, FrameTime()*jchat.panning_vel, 0))
		end
	end

	local params = {}

	function jchat.CalcView(ply, origin, angles, fov, znear, zfar)
		jchat.farz = zfar
		jchat.nearz = znear

		local ply = jchat.GetActivePlayer()

		if ply:IsValid() then
			jchat.pos_target = jchat.pos_target or jchat.GetWorldCameraPos()
			jchat.dir_target = jchat.GetEyePos(ply) - jchat.pos_target + jchat.panning_dir:Forward()

			jchat.CalcSmooth()
			jchat.CalcPanning()

			if jchat.new_angle then
				jchat.pos_smooth = jchat.pos_target
				jchat.dir_smooth = jchat.dir_target
				jchat.fov_smooth = jchat.fov_target

				jchat.new_angle = false
			end

			params.origin = jchat.pos_smooth
			params.angles = jchat.dir_smooth:Angle() + jchat.angle_offset + jchat.panning_dir
			params.fov = jchat.fov_smooth
			params.znear = 20

			return params
		end
	end

	jchat.message = "hi2"
	jchat.fade = 1

	local grad_up = surface.GetTextureID("gui/gradient_up")
	local grad_down = surface.GetTextureID("gui/gradient_down")

	local function string_wrapwords(Str,width)
		local tbl, len, Start, End = {}, string.len( Str ), 1, 1

		while ( End < len ) do
		 End = End + 1
		 if ( surface.GetTextSize( string.sub( Str, Start, End ) ) > width ) then
			 local n = string.sub( Str, End, End )
			 local I = 0
			 for i = 1, 15 do
				 I = i
				 if( n != " " and n != "," and n != "." and n != "\n" ) then
					 End = End - 1
					 n = string.sub( Str, End, End )
				 else
					 break
				 end
			 end
			 if( I == 15 ) then
				 End = End + 14
			 end

			 local FnlStr = string.Trim( string.sub( Str, Start, End ) )
			 table.insert( tbl, FnlStr )
			 Start = End + 1
		 end
		end
		table.insert( tbl, string.sub( Str, Start, End ) )
		return tbl
	end


	local prettytext = requirex("pretty_text")

	function jchat.DrawSubtitles()
		local ent = jchat.GetActivePlayer()
		if not ent:IsValid() then return end
		local name

		if ent:IsNPC() then
			name = ent:GetClass()
			if language.GetPhrase(name) then
				name = language.GetPhrase(name)
			end
		else
			name = (jrpg and jrpg.GetFriendlyName(ent) or ent:Nick())
		end

		local font_size = 60
		local font_weight = 100
		local y = 0

		if not jchat.wrapped_message then
			prettytext.GetTextSize("", "Square721 BT", font_size, font_weight, 3, 31)
			jchat.wrapped_message = string_wrapwords(jchat.message, ScrW() - 350)
		end

		for _, str in ipairs(jchat.wrapped_message) do
			y = y + font_size
		end

		local x = 150
		local y = ScrH() - y - 100
		local brightness = 230

		do
			local y = y
			local w = prettytext.Draw(name, x, y, "Square721 BT", font_size, font_weight, 3, Color(brightness, brightness, brightness, 255 * jchat.fade), Color(0,0,0,255), nil, -1, 31)

			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(0 - 3, y - 3 + 5, w + x + 10 + 6, 3 + 6)

			surface.SetDrawColor(170, 170, 170, 255)
			surface.DrawRect(0, y + 5, w + x + 10, 3)
		end

		local y = y
		for _, str in ipairs(jchat.wrapped_message) do
			prettytext.Draw(str, ScrW() / 2, y + 25, "Square721 BT", font_size, font_weight, 3, Color(brightness, brightness, brightness, 255 * jchat.fade), Color(0,0,0,255), -0.5, nil, 31)
			y = y + font_size
		end
	end

	local blur_mat = Material( "pp/bokehblur" )

	local mat = Material("particle/Particle_Glow_04_Additive")
	local size = 400
	function jchat.RenderScreenspaceEffects()
		do
			surface.SetMaterial(mat)
			surface.SetDrawColor(35,35,35,255)
			surface.DrawTexturedRect(-size, -size, ScrW()+size*2, ScrH()+size*2)

			surface.SetDrawColor(0,0,0, 220)

			surface.SetTexture(grad_down)
			surface.DrawTexturedRect(0, 0, ScrW(), ScrH()/2)

			surface.SetTexture(grad_up)
			surface.DrawTexturedRect(0, ScrH()/2, ScrW(), ScrH()/2)
		end

		jchat.DrawSubtitles()
	end
end

hook.Add("PlayerUsedEntity", "jchat", function(ply, ent)
	if not battlecam.IsEnabled() then return end

	if ply == LocalPlayer() and (ent:IsNPC() or ent:IsPlayer()) then
		jchat.Start(function()
			battlecam.Enable()
		end)
		jchat.AddPlayer(ply)
		jchat.AddPlayer(ent)
		jchat.PlayerSay(ent, "")
		battlecam.Disable()
	end
end)