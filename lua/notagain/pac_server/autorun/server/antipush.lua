local throw = ErrorNoHalt

local function IsPlayer(ent)
    return IsValid(ent) and ent:GetClass() == "player" or false
end

local function CanPush(ply, ent)
    local canAlter = ( ply.CanAlter and ply:CanAlter(ent) ) or false
    local isFriend = ( ply.IsFriend and ply:IsFriend(ent) ) or false
    return canAlter or isFriend
end

local function wait(callback, frames)
    local delay = FrameTime() * ( frames or 1 )
    timer.Simple(delay, function() 
        xpcall(callback, throw)
    end)
end

hook.Add( "KeyPress", "antiphyspush", function( ply, key )
    if IsValid(ply) and key == IN_ATTACK then
        ply._appHasInAttack = true
    end
end)

for _, hookTo in next, {"PhysgunPickup", "GravGunPunt"} do
    hook.Add(hookTo, "antiphyspush", function(ply, ent)
        wait(function()
            if ( IsValid(ent) and ply._appHasInAttack ) and ent:IsPlayerHolding() then
                ent.pickedby = ply
            end
            ply._appHasInAttack = nil
        end, 3)
    end)
end

hook.Add("OnEntityCreated", "antiphyspush", function(ent)
    wait(function()
        local ply = IsValid(ent) and ( ent.CPPIGetOwner and ent:CPPIGetOwner() or ent:GetOwner() )

        if ( IsPlayer(ply) ) and not ent.PushProtected then
            ent:AddCallback('PhysicsCollide', function(ent, data)
                local ply = data.HitEntity

                local canMove = IsValid(data.PhysObject) and data.PhysObject:IsMotionEnabled() or false
                local cantAlter = IsPlayer(ply) and not CanPush(ply, ent)

                if ent.IsPushing then
                    data.PhysObject:Sleep()
                end

                if canMove and cantAlter then 
                    local pos = ply:GetPos()
                    ent.IsPushing = true

                    if tobool( ply:GetInfo("cl_godmode_reflect") ) and IsValid(ent.pickedby) then
                        ent.pickedby:SetMoveType(MOVETYPE_WALK)
                        ent.pickedby:SetVelocity((data.OurOldVelocity*-1) + data.HitNormal*-600)
                    end

                    ply:SetVelocity(ply:GetVelocity()*-1)
                    ent:SetPos(ent:GetPos())

                    data.HitObject:Sleep()
                    data.PhysObject:Sleep()

                    wait(function()
                        if IsValid(ply) then
                            ply:SetVelocity(ply:GetVelocity()*-1)
                            ply:SetPos(pos)
                        end
                        if IsValid(ent) and ent.IsPushing then
                            ent.IsPushing = nil
                        end
                    end, 2)
                end

                return false
            end)

            ent.PushProtected = true
        end
    end)
end)
