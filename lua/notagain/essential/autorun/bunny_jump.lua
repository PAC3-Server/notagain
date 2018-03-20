if engine.ActiveGamemode() ~= "sandbox" then return end

local default = 1.5
local hook_key = "bhop"

if SERVER then
	util.AddNetworkString(hook_key.."_effect")
	util.AddNetworkString(hook_key)
end

do
	DEFINE_BASECLASS( "player_sandbox" )

	function BaseClass:FinishMove( move )
		-- If the player has jumped this frame
		if JUMPING then
			-- Get their orientation
			local forward = move:GetAngles()
			forward.p = 0
			forward = forward:Forward()

			-- Compute the speed boost

			-- HL2 normally provides a much weaker jump boost when sprinting
			-- For some reason this never applied to GMod, so we won't perform
			-- this check here to preserve the "authentic" feeling
			local speedBoostPerc = ( ( not self.Player:Crouching() ) and 0.5 ) or 0.1

			local speedAddition = math.abs( move:GetForwardSpeed() * speedBoostPerc )
			local maxSpeed = move:GetMaxSpeed() * ( 1 + speedBoostPerc )
			local newSpeed = speedAddition + move:GetVelocity():Length2D()

			-- Reverse it if the player is running backwards
			if move:GetVelocity():Dot(forward) < 0 then
				speedAddition = -speedAddition
			end

			-- Apply the speed boost
			move:SetVelocity(forward * speedAddition + move:GetVelocity())
		end

		JUMPING = nil
	end
	baseclass.Set("player_sandbox", BaseClass)
end

do
	local META = FindMetaTable("Player")

	function META:SetSuperJumpMultiplier(mult, dont_update_client)
		self.super_jump_multiplier = mult

		if SERVER and not dont_update_client then
			net.Start(hook_key)
				net.WriteFloat(mult)
			net.Send(self)
		end

		self:SetDuckSpeed(0.05)
		self:SetUnDuckSpeed(0.05)
	end

	function META:GetSuperJumpMultiplier()
		return self.super_jump_multiplier or default
	end
end

local function play_effect(ply, fraction, origin, normal)
	ply:EmitSound(
		("weapons/fx/rics/ric%s.wav"):format(math.random(5)),
		75,
		math.Clamp(300*fraction, 70, 150),
		math.Clamp(fraction*0.5, 0, 1)
	)
	ply:EmitSound(
		("physics/plastic/plastic_barrel_impact_bullet3.wav"):format(math.random(5)),
		75,
		100,
		math.Clamp(fraction, 0, 1)
	)

	local ef = EffectData()
		ef:SetOrigin(origin)
		ef:SetScale(10*fraction)
		ef:SetNormal(normal)
	util.Effect("StunstickImpact", ef)

end

if CLIENT then
	net.Receive(hook_key.."_effect", function(len)
		local ply = net.ReadEntity()
		if ply:IsValid() then
			local fraction = net.ReadFloat()
			local origin = net.ReadVector()
			local normal = net.ReadVector()

			play_effect(ply, fraction, origin, normal)
		end
	end)

	net.Receive(hook_key, function()
		LocalPlayer():SetSuperJumpMultiplier(net.ReadFloat())
	end)
end

if SERVER then
	hook.Add("GetFallDamage", hook_key, function(ply, speed)
		if ply:KeyDown(IN_JUMP) then
			return 0
		end
	end)
end

local function send_effect(ply, fraction, origin, normal)
	if CLIENT then
		if IsFirstTimePredicted() then
			play_effect(ply, fraction, origin, normal)
		end
	end

	if SERVER then
		net.Start(hook_key.."_effect", true)
			net.WriteEntity(ply)
			net.WriteFloat(fraction)
			net.WriteVector(origin)
			net.WriteVector(normal)
		net.SendOmit(ply)
	end
end

hook.Add("Move", hook_key, function(ply, data)
	if ply:GetMoveType() ~= MOVETYPE_WALK then return end

	local mult = ply:GetSuperJumpMultiplier()

	if mult ~= 1 and data:KeyPressed(IN_JUMP) and ply:IsOnGround() then
		data:SetVelocity(data:GetVelocity() * mult)

		local eye = math.Clamp(data:GetAngles().p / 89, 0, 1) ^ 3

		if eye > 0.3 then
			ply:SetGroundEntity(NULL)

			local fraction = data:GetVelocity():Length() / (GetConVarNumber("sv_maxvelocity") / 4)

			send_effect(ply, fraction, data:GetOrigin(), Vector(0,0,1))

			data:SetVelocity(LerpVector(eye, data:GetVelocity(), Vector(0.5, 0.5, 1) * data:GetVelocity() + Vector(0,0,data:GetVelocity():Length()*0.3)) + Vector(0,0, ply:GetJumpPower()))
		end
	end

	if data:KeyPressed(IN_JUMP) or data:KeyWasDown(IN_JUMP) then
		local velocity = data:GetVelocity()
		local normalized = velocity:GetNormalized()

		local params = {}
			params.start = data:GetOrigin()
			params.endpos = params.start + normalized * ply:BoundingRadius() * 2
			local filter = {ply}
			for k,v in pairs(ents.FindInSphere(ply:GetPos(), 512)) do
				if v:GetOwner() == ply then
					table.insert(filter, v)
				end
			end
			params.filter = filter
			params.mins = ply:OBBMins()
			params.maxs = ply:OBBMaxs()
		local res = util.TraceHull(params)

		if
			not ply:IsOnGround() and
			res.Hit and
			math.abs(res.HitNormal.z) < 0.7 and
			(not ply.bhop_wall_bounce_origin or ply.bhop_wall_bounce_origin:Distance(data:GetOrigin()) > ply:BoundingRadius()) and
			velocity.x ~= 0 and velocity.y ~= 0
		then
			local direction = velocity - 2 * (res.HitNormal:DotProduct(velocity) * res.HitNormal)

			local fraction = math.min(velocity:Length() / GetConVarNumber("sv_maxvelocity"), 1)

			data:SetVelocity(direction*1.1)

			local fraction = velocity:Length() / (GetConVarNumber("sv_maxvelocity") / 4)

			send_effect(ply, fraction, res.HitPos, res.HitNormal)

			ply.bhop_wall_bounce_origin = data:GetOrigin()
		end
	end
end)

hook.Add("PostGamemodeLoaded", hook_key, function()
	function GAMEMODE:StartMove() end
	function GAMEMODE:FinishMove() end

	if SERVER then
		RunConsoleCommand("sv_airaccelerate", "1000000")
		RunConsoleCommand("sv_maxvelocity", "40960")
		RunConsoleCommand("sv_sticktoground", "0")
	end

	hook.Remove("PostGamemodeLoaded",hook_key)
end)
