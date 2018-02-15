local afkmera_enable = CreateConVar("cl_afkmera_enable", "1", { FCVAR_ARCHIVE }, "Should AFKmera be active or not?")
local afkmera_anim_enable = CreateConVar("cl_afkmera_anim_enable", "1", { FCVAR_ARCHIVE }, "Should we change the playermodel's animation while AFK or not?")
local afkmera_transition_speed = CreateConVar("cl_afkmera_transition_speed", "0.66", { FCVAR_ARCHIVE }, "The time it takes to go from player eyes to AFKmera and vice versa.")
local afkmera_rotation_speed = CreateConVar("cl_afkmera_rotation_speed", "0.5", { FCVAR_ARCHIVE }, "How fast the AFKmera should rotate around the player. (negative = other way)")
local afkmera_fov = CreateConVar("cl_afkmera_fov", "60", { FCVAR_ARCHIVE }, "Field of view of the AFKmera.")
local afkmera_dist = CreateConVar("cl_afkmera_dist", "10", { FCVAR_ARCHIVE }, "Distance between the AFKmera and the player.")
local afkmera_height = CreateConVar("cl_afkmera_height", "0.25", { FCVAR_ARCHIVE }, "Height of the AFKmera.")
local afkmera_pitch = CreateConVar("cl_afkmera_pitch", "-15", { FCVAR_ARCHIVE }, "Angle pitch of the AFKmera.")
local afkmera_simulate = CreateConVar("cl_afkmera_simulate", "0", { FCVAR_ARCHIVE }, "Force AFKmera to be active (to test and set other ConVars as you like)")

local camDist = 0
local camHeight = 0
local fieldOfView = 0
local act = ""
local newAct = false
local newActDelay = 0
local lastWeapon = false
local spawned = 0

local noAFKEntities = {
	gmod_playx = true,
	gmod_playx_repeater = true,
	gmod_playx_proximity = true,
}

cvars.AddChangeCallback("cl_afkmera_enable", function(convar_name, value_old, value_new)
	if value_new ~= "0" then
		hook.Add("OnPlayerAFK", "afk_camera", function(ply, b)
			if ply == LocalPlayer() then
				if b then
					hook.Add("CalcView", "afk_camera", function(ply, basePos, baseAng, baseFov, nearZ, farZ)
						if not afkmera_enable:GetBool() or spawned > CurTime() or (pace and IsValid(pace.Editor)) then return end

						local IsAFK = false
						local simulate = afkmera_simulate:GetBool() or false
						if ply.IsAFK and ply:IsAFK() or simulate then IsAFK = true end

						local transitionSpeed = afkmera_transition_speed:GetFloat() or 1
						local fov = afkmera_fov:GetFloat() or 70
						camDist 	= math.Clamp(Lerp(FrameTime() * (10 * transitionSpeed), camDist, IsAFK and 1 or 0), 0, 1)
						fieldOfView = Lerp(FrameTime() * (10 * transitionSpeed), fieldOfView, IsAFK and fov or baseFov)

						local dead = false
						if ply:Health() <= 0 or ply:Crouching() or ply:InVehicle() then dead = true end

						camHeight   = Lerp(FrameTime() * (10 * transitionSpeed), camHeight, dead and 1 or 0)

						local trace = ply:GetEyeTrace()
						local badEntity = false
						if trace.Entity ~= nil and trace.Entity ~= NULL and noAFKEntities[trace.Entity:GetClass()] then badEntity = true end

						if camDist > 0.005 and not badEntity then

							local rotationSpeed = afkmera_rotation_speed:GetFloat() or 1
							local dist = afkmera_dist:GetFloat() or 0
							local height = math.Clamp(afkmera_height:GetFloat(), 0.25, 2) or 0.66
							local pitch = afkmera_pitch:GetFloat() or 0

							local _, maxs = ply:GetModelBounds()
							local plyPos = ply:GetPos()
							local pos = plyPos + Vector(0, 0, maxs.z * height - (maxs.z / 3 * camHeight))
							dist = Vector(maxs.z * 2 + dist, 0, 0)
							local lookAway = Angle(pitch, RealTime() * (15 * rotationSpeed) % 360, 0)
							dist:Rotate(lookAway)
							local aroundMe = pos + dist
							local lookAtMe = (pos - aroundMe):Angle()
							trace = {}
							trace.start = pos
							trace.endpos = aroundMe
							trace.filter = ply
							trace.mask = MASK_SOLID_BRUSHONLY
							trace = util.TraceLine(trace)
							aroundMe = trace.HitPos

							local pos = LerpVector(camDist, basePos, aroundMe)
							local ang = LerpAngle(camDist, baseAng, lookAtMe)

							local view = {}
							view.origin = pos
							view.angles = ang
							view.fov = fieldOfView
							view.znear = nearZ
							view.zfar = farZ
							view.drawviewer	= camDist >= 0.1

							return view
						else
							newAct = false
							lastWeapon = false
						end
					end)

					if afkmera_anim_enable:GetBool() then
						hook.Add("CalcMainActivity", "afk_camera", function(ply)

							local IsAFK = false
							local simulate = afkmera_simulate:GetBool() or false
							if ply:EntIndex() == LocalPlayer():EntIndex() and (ply.IsAFK and ply:IsAFK() or simulate) and ply:GetVelocity():Length() <= 10 then IsAFK = true end
							if IsAFK and act ~= "" then
								local seq = ply:LookupSequence(act)
								return seq, seq
							end
						end)
					end
				else
					timer.Simple(3, function()
						hook.Remove("CalcView", "afk_camera")
						hook.Remove("CalcMainActivity", "afk_camera")
					end)
				end
			end
		end)
	else
		hook.Remove("OnPlayerAFK", "afk_camera")
	end
end)

