
CreateClientConVar("player_ik_foot",                    1,  true, true, "enable/disable inverse kinematic for foot")
CreateClientConVar("player_ik_foot_lean",              	0,  true, true, "enable/disable player movement with additional leaning")
CreateClientConVar("player_ik_foot_ground_distance",    45, true, true, "max collision distance feet with an obstacle")
CreateClientConVar("player_ik_foot_smoothing",          17, true, true, "animation smoothing")
CreateClientConVar("player_ik_foot_debug",              0,  true, true, "enable/disable display debug tools")

local function CanManipulateBones( ply )
    if ply:InVehicle() then return false end

    if istable(ActionGmod) and ply:IsDive() then return false end

    if istable(prone) and ply:IsProne() then return false end

    return true

end

local function manip_pos(ply, id, pos)
	if pac and pac.ManipulateBonePosition then
		pac.ManipulateBonePosition(ply, id, pos)
	else
		ply:ManipulateBonePosition(ply,id, pos)
	end
end

local function manip_angles(ply, id, pos)
	if pac and pac.ManipulateBoneAngles then
		pac.ManipulateBoneAngles(ply, id, pos)
	else
		ply:ManipulateBoneAngles(ply,id, pos)
	end
end

hook.Add( "PostPlayerDraw", "IKFoot_PostPlayerDraw", function( ply )
    if not IsValid( ply ) then return end
    local ikFoot = GetConVar("player_ik_foot"):GetBool()

    local lFoot = ply:LookupBone( "ValveBiped.Bip01_L_Foot" )
    local rFoot = ply:LookupBone( "ValveBiped.Bip01_R_Foot" )

    local lCalf = ply:LookupBone( "ValveBiped.Bip01_L_Calf" )
    local rCalf = ply:LookupBone( "ValveBiped.Bip01_R_Calf" )

    local lThigh = ply:LookupBone( "ValveBiped.Bip01_L_Thigh" )
    local rThigh = ply:LookupBone( "ValveBiped.Bip01_R_Thigh" )

    if lFoot and rFoot and lCalf and rCalf and lThigh and rThigh then
        local basePos = Vector()
        local lerpTime = math.Clamp(FrameTime() * GetConVar("player_ik_foot_smoothing"):GetFloat(), 0, 1)

        local result = {
            basePos = basePos,
            baseAng = Angle(),
            lCalf = Angle(),
            rCalf = Angle(),
            lThigh = Angle(),
            rThigh = Angle(),
            lFoot = Angle(),
            rFoot = Angle(),
        }

        if not ply.IKResult then
            ply.IKResult = result
        end

        if not ply.IKResetManipulationBones then
            ply.IKResetManipulationBones = false
        end

        if ikFoot then
            local groundDist = GetConVar("player_ik_foot_ground_distance"):GetFloat()
            local groundZDist = Vector(0, 0, 1) * groundDist

            local lFootPos, lFootAng = ply:GetBonePosition( lFoot )
            local rFootPos, rFootAng =  ply:GetBonePosition( rFoot )

            if lFootPos and rFootPos and lFootAng and rFootAng then
                local lFootForward = lFootAng:Forward()
                lFootForward.z = 0
                lFootForward:Normalize()

                local rFootForward = rFootAng:Forward()
                rFootForward.z = 0
                rFootForward:Normalize()

                local lToePos = lFootPos + lFootForward * 8
                local rToePos = rFootPos + rFootForward * 8

                local lLegStart = Vector(lFootPos.x, lFootPos.y, ply:GetPos().z + 30)
                local rLegStart = Vector(rFootPos.x, rFootPos.y, ply:GetPos().z + 30)

                local lToeStart = Vector(lToePos.x, lToePos.y, ply:GetPos().z + 30)
                local rToeStart = Vector(rToePos.x, rToePos.y, ply:GetPos().z + 30)

                local mins = Vector(-3, -3, 0)
                local maxs = Vector(3, 3, 5)

                local lLegTrace = util.TraceHull( {
                    start = lLegStart,
                    endpos = lLegStart - groundZDist,
                    mins = mins,
                    maxs = maxs,
                    filter = ply
                } )

                local rLegTrace = util.TraceHull( {
                    start = rLegStart,
                    endpos = rLegStart - groundZDist,
                    mins = mins,
                    maxs = maxs,
                    filter = ply
                } )

                local lTraceToe = util.TraceHull( {
                    start = lToeStart,
                    endpos = lToeStart - groundZDist,
                    mins = mins,
                    maxs = maxs,
                    filter = ply
                })

                local rTraceToe = util.TraceHull( {
                    start = rToeStart,
                    endpos = rToeStart - groundZDist,
                    mins = mins,
                    maxs = maxs,
                    filter = ply
                })

                local lDist = 30
                local rDist = 30

                if ply:OnGround() then
                    lDist = lLegTrace.Fraction * groundDist
                    rDist = rLegTrace.Fraction * groundDist
                end

                local lFootDir = lTraceToe.HitPos - lLegTrace.HitPos
                local rFootDir = rTraceToe.HitPos - rLegTrace.HitPos

                if lLegTrace.Hit or rLegTrace.Hit then
                    local maxDistance = math.max(math.max(rDist, lDist) - 30, 0)
                    result.basePos = basePos + Vector(0, 0, -maxDistance)

                    local rAlpha = -math.deg(math.asin(math.Clamp((rDist - maxDistance - 30) / 17, -1, 1)))

                    result.rCalf = Angle(0, rAlpha, 0)
                    result.rThigh = Angle(0, -rAlpha, 0)

                    local lAlpha = -math.deg(math.asin(math.Clamp((lDist - maxDistance - 30) / 17, -1, 1)))

                    result.lCalf = Angle(0, lAlpha, 0)
                    result.lThigh = Angle(0, -lAlpha, 0)

                    result.lFoot = Angle(0, lFootDir:Angle().p, 0)
                    result.rFoot =  Angle(0, rFootDir:Angle().p, 0)

                end

                if GetConVar("player_ik_foot_lean"):GetBool() then
                    local plyVel = ply:GetVelocity()
                    local plyAng = ply:GetAimVector():Angle()

                    local leanY = math.Clamp( plyVel:Dot(plyAng:Right()) / 20, -4, 4 )

                    result.baseAng = Angle(0, leanY, 0)

                end

                ply.IKResult.basePos = LerpVector( lerpTime, ply.IKResult.basePos, result.basePos )
                ply.IKResult.baseAng = LerpAngle( lerpTime, ply.IKResult.baseAng, result.baseAng )

                ply.IKResult.rCalf = LerpAngle( lerpTime, ply.IKResult.rCalf, result.rCalf )
                ply.IKResult.lCalf = LerpAngle( lerpTime, ply.IKResult.lCalf, result.lCalf )

                ply.IKResult.rThigh = LerpAngle( lerpTime, ply.IKResult.rThigh, result.rThigh )
                ply.IKResult.lThigh = LerpAngle( lerpTime, ply.IKResult.lThigh, result.lThigh )

                ply.IKResult.lFoot = LerpAngle( lerpTime, ply.IKResult.lFoot, result.lFoot )
                ply.IKResult.rFoot = LerpAngle( lerpTime, ply.IKResult.rFoot, result.rFoot )

                local COLOR_WHITE = Color(255, 255, 255, 255)
                local COLOR_RED = Color(255, 0, 0, 255)

                if GetConVar("player_ik_foot_debug"):GetInt() > 0 and CanManipulateBones( ply ) then
                    if lLegTrace.Hit then
                        render.DrawWireframeBox( lLegTrace.HitPos, lFootDir:Angle(), mins, maxs, COLOR_RED, true )
                        render.DrawLine( lLegStart, lLegTrace.HitPos,  COLOR_RED)
                    else
                        render.DrawWireframeBox( lLegTrace.HitPos, Angle(), mins, maxs, COLOR_WHITE, true )
                        render.DrawLine( lLegStart, lLegTrace.HitPos,  COLOR_WHITE)
                    end

                    if rLegTrace.Hit then
                        render.DrawWireframeBox( rLegTrace.HitPos, rFootDir:Angle(), mins, maxs, COLOR_RED, true )
                        render.DrawLine( rLegStart, rLegTrace.HitPos, COLOR_RED)
                    else
                        render.DrawWireframeBox( rLegTrace.HitPos, Angle(), mins, maxs, COLOR_WHITE, true )
                        render.DrawLine( rLegStart, rLegTrace.HitPos, COLOR_WHITE)
                    end

                end
            end
        end

        if GetConVar("player_ik_foot_debug"):GetInt() > 1 then
            local bottom, top = Vector()

            if ply:Crouching() then
                bottom, top = ply:GetHullDuck()
            else
                bottom, top = ply:GetHull()
            end

            render.DrawWireframeBox( ply:GetPos(), Angle(), bottom, top, COLOR_WHITE, true )
        end

        if ikFoot and CanManipulateBones( ply ) then
            manip_pos(ply, 0, ply.IKResult.basePos )
            manip_angles(ply, 0, ply.IKResult.baseAng )

            manip_angles(ply,lCalf, ply.IKResult.lCalf )
            manip_angles(ply,rCalf, ply.IKResult.rCalf )

            manip_angles(ply,lThigh, ply.IKResult.lThigh )
            manip_angles(ply,rThigh, ply.IKResult.rThigh )

            manip_angles(ply,lFoot, ply.IKResult.lFoot )
            manip_angles(ply,rFoot, ply.IKResult.rFoot )

            ply.IKResetManipulationBones = false

        elseif not ply.IKResetManipulationBones then
            manip_pos(ply, 0, Vector() )
            manip_angles(ply, 0, Angle() )

            manip_angles(ply,lCalf, Angle() )
            manip_angles(ply,rCalf, Angle() )

            manip_angles(ply,lThigh, Angle() )
            manip_angles(ply,rThigh, Angle() )

            manip_angles(ply,lFoot, Angle() )
            manip_angles(ply,rFoot, Angle() )

            ply.IKResetManipulationBones = true

        end
    end
end)