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

                    ply:SetVelocity(ply:GetVelocity()*-1)
                    ent:SetAbsVelocity( ent:GetAbsVelocity()*(data.PhysObject:GetMass()*-1) )
                    data.HitObject:Sleep()

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
