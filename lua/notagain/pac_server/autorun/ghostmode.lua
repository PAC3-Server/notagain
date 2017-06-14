local Tag       = "GhostMode"
local META      = FindMetaTable("Player")
local NetKill   = "ON_KILL"
local NetSilent = "ON_KILL_SILENT"
local NetAlive  = "ON_SET_ALIVE"
local Deads     = {}

META.old_plyalive = META.old_plyalive or META.Alive
META.Alive = function(self)
    if IsValid(self) then 
        if Deads[self:SteamID()] then 
            return false 
        else 
            return META.old_plyalive(self)
        end  
    end
    return false
end

concommand.Remove("kill")
concommand.Add("kill",function(ply)
    ply:Kill()
end)

if SERVER then
    
    util.AddNetworkString(NetKill)
    util.AddNetworkString(NetSilent)
    util.AddNetworkString(NetAlive)
    
    META.old_plykill = META.old_plykill or META.Kill 
    META.old_plykillsilent = META.old_plykillsilent or META.KillSilent 

    local SetDead = function(ply,state)
        timer.Simple(0,function()
            if IsValid(ply) then
                ply:SetNoDraw(state)
                ply:SetNoTarget(state)
                ply:SetNotSolid(state)
                Deads[ply:SteamID()] = state and ply or nil
                if state then
                    ply:SetMoveType(MOVETYPE_NOCLIP)
                    ply:SetHealth(0)
                    ply:StripWeapons()
                end
            end  
        end)
    end

    META.Kill = function(self)
        gamemode.Call("PlayerDeath",self,self,self)
        SetDead(self,true)
        net.Start(NetKill)
        net.WriteEntity(self)
        net.Broadcast()
    end  

    META.KillSilent = function(self)
        gamemode.Call("PlayerSilentDeath",self)
        SetDead(self,true)
        net.Start(NetSilent)
        net.WriteEntity(self)
        net.Broadcast()
    end
    
    local DisallowDead = function(ply,...)
        if IsValid(ply) and Deads[ply:SteamID()] then 
            return false 
        end
    end

    hook.Add("ShouldCollide",Tag,function(e1,e2)
        if IsValid(e1) and IsValid(e2) then 
            if e1:IsPlayer() and Deads[e1:SteamID()] or e2:IsPlayer() and Deads[e2:SteamID()] then 
                return false 
            end
        end
        return true
    end)

    hook.Add("EntityTakeDamage",Tag,function(ent,dmg)
        if IsValid(ent) and ent:IsPlayer() then
            if dmg:GetDamage() >= ent:Health() then 
                gamemode.Call("PlayerDeath",ent,dmg:GetInflictor(),dmg:GetAttacker())
                SetDead(ent,true)
                net.Start(NetKill)
                net.WriteEntity(ent)
                net.Broadcast()
                dmg:SetDamage(0)
            elseif Deads[ent:SteamID()] then 
                dmg:SetDamage(0)
            end 
        end  
    end)

    hook.Add("PlayerSpawn",Tag,function(ply)
        if IsValid(ply) and Deads[ply:SteamID()] then
            SetDead(ply,false)
            timer.Simple(0,function()
                gamemode.Call("PlayerLoadout",ply)
            end)
            net.Start(NetAlive)
            net.WriteEntity(ply)
            net.Broadcast()
        end
    end)

    hook.Add("Think",Tag,function()
        for _,ply in pairs(player.GetAll()) do
            if not ply:old_plyalive() then 
                local oldpos = ply:GetPos()
                ply:Spawn()
                ply:SetPos(oldpos)
                SetDead(ply,true)
                net.Start(NetKill)
                net.WriteEntity(ply)
                net.Broadcast()
            end
        end
    end)

    hook.Add("KeyPress",Tag,function(ply,key)
        if IsValid(ply) and Deads[ply:SteamID()] then 
            if key == IN_ATTACK then 
                ply:Spawn()
            end
        end
    end)
    
    hook.Add("PlayerSpawnVehicle",Tag,DisallowDead)
    hook.Add("PlayerSpawnSWEP",Tag,DisallowDead)
    hook.Add("PlayerSpawnSENT",Tag,DisallowDead)
    hook.Add("PlayerSpawnRagdoll",Tag,DisallowDead)
    hook.Add("PlayerSpawnObject",Tag,DisallowDead)
    hook.Add("PlayerSpawnNPC",Tag,DisallowDead)
    hook.Add("PlayerSpawnEffect",Tag,DisallowDead)
    hook.Add("PlayerGiveSWEP",Tag,DisallowDead)
    hook.Add("PlayerSpawnProp",Tag,DisallowDead)
    hook.Add("PlayerShouldTakeDamage",Tag,DisallowDead)
    hook.Add("PlayerCanPickupWeapon",Tag,DisallowDead)
    hook.Add("PlayerCanPickupItem",Tag,DisallowDead)
    hook.Add("PlayerUse",Tag,DisallowDead)

end  

if CLIENT then 
    local Settings = {
        [ "$pp_colour_addr" ]       = 0,
        [ "$pp_colour_addg" ]       = 0,
        [ "$pp_colour_addb" ]       = 0,
        [ "$pp_colour_brightness" ] = 0.1,
        [ "$pp_colour_contrast" ]   = 0.8,
        [ "$pp_colour_colour" ]     = 0,
        [ "$pp_colour_mulr" ]       = 0,
        [ "$pp_colour_mulg" ]       = 0.2,
        [ "$pp_colour_mulb" ]       = 0.5,
    }
    local DBloom,DBloomMult
    local r,g,b      = 0,0.1,0
	local GlareMat   = Material("sprites/light_ignorez")
	local WarpMat    = Material("particle/warp2_warp")
	local Emitter2D  = ParticleEmitter(vector_origin)
	Emitter2D:SetNoDraw(true)
	local Shiny = CreateMaterial(tostring({}) .. os.clock(), "VertexLitGeneric", {
		["$Additive"]          = 1,
		["$Translucent"]       = 1,
		["$Phong"]             = 1,
		["$PhongBoost"]        = 10,
		["$PhongExponent"]     = 5,
		["$PhongFresnelRange"] = Vector(0,0.5,1),
		["$PhongTint"]         = Vector(1,1,1),
		["$Rimlight"]          = 1,
		["$RimlightBoost"]     = 50,
		["$RimlightExponent"]  = 5,
		["$BaseTexture"]       = "models/debug/debugwhite",
		["$BumpMap"]           = "dev/bump_normal",
	})
	local Glare2Mat = CreateMaterial(tostring{}, "UnlitGeneric", {
		["$BaseTexture"] = "particle/fire",
		["$Additive"]    = 1,
		["$VertexColor"] = 1,
		["$VertexAlpha"] = 1,
	})    
    local Friend = {
        strong = { r = 50, g = 200, b = 200},
        medium = { r = 75, g = 150, b = 255},
        light  = { r = 100, g = 200, b = 255},
    }
    local NotFriend = {
        strong = { r = 200, g = 200, b = 50},
        medium = { r = 255, g = 150, b = 75},
        light  = { r = 255, g = 200, b = 100},
    }

    local SetDead = function(ply,state)
        if IsValid(ply) then
            ply:SetNotSolid(state)
            ply:SetNoDraw(state)
            Deads[ply:SteamID()] = state and ply or nil
            if ply == LocalPlayer() then
                if state then
                    RunConsoleCommand("pp_bloom","1")
                    RunConsoleCommand("pp_bloom_multiply","5")
                else 
                    RunConsoleCommand("pp_bloom",DBloom)
                    RunConsoleCommand("pp_bloom_multiply",DBloomMult)
                end
            end
        end
    end

    net.Receive(NetKill,function()
        local ply = net.ReadEntity()
        SetDead(ply,true)
    end)

    net.Receive(NetSilent,function()
        local ply = net.ReadEntity()
        SetDead(ply,true)
    end)

    net.Receive(NetAlive,function()
        local ply = net.ReadEntity()
        SetDead(ply,false)
    end)

    hook.Add("PostDrawTranslucentRenderables",Tag,function()
        for _,v in pairs(Deads) do 
            if IsValid(v) then   
                local color 
                if v:GetFriendStatus() == "friend" or v == LocalPlayer() then 
                    color = Friend 
                else 
                    color = NotFriend
                end
                render.SetColorModulation(r, g, b)
                render.MaterialOverride(Shiny)
                local Pos = v:WorldSpaceCenter()
                v.PixelVisible = v.PixelVisible or util.GetPixelVisibleHandle()
                v.PixelVisible2 = v.PixelVisible2 or util.GetPixelVisibleHandle()
                local Radius = v:BoundingRadius()
                local Visi = util.PixelVisible(Pos, Radius*0.5, v.PixelVisible)
                local Time = RealTime()
                local Glow = math.abs(math.sin(Time))
                local r = Radius/8
                cam.IgnoreZ(true)
                render.SetMaterial(WarpMat)
                render.DrawSprite(Pos, 25, 25, Color(r*255*2, g*255*2, b*255*2, Visi*20))
                render.SetMaterial(Glare2Mat)
                render.DrawSprite(Pos, r*10, r*10, Color(color.light.r, color.light.g, color.light.b, Visi*255*Glow+3))
                render.DrawSprite(Pos, r*15, r*15, Color(color.medium.r, color.medium.g, color.medium.b, Visi*255*(Glow+3.25)))
                render.DrawSprite(Pos, r*20, r*20, Color(color.strong.r, color.strong.g, color.strong.b, Visi*150*(Glow+3.50)))
                render.SetMaterial(GlareMat)
                cam.IgnoreZ(false)
                --v:DrawModel()
                if not v.NextEmit2 or v.NextEmit2 < Time then
                    local p = Emitter2D:Add(Glare2Mat, Pos + (VectorRand()*Radius*0.5))
                    p:SetDieTime(math.Rand(2,4))
                    p:SetLifeTime(1)
                    p:SetStartSize(math.Rand(16,32))
                    p:SetEndSize(0)
                    p:SetStartAlpha(0)
                    p:SetEndAlpha(255)
                    p:SetColor(color.medium.r, color.medium.g, color.medium.b)
                    p:SetVelocity(VectorRand()*5)
                    p:SetGravity(Vector(0,0,3))
                    p:SetAirResistance(30)
                    v.NextEmit2 = Time + 0.1
                    if math.random() > 0.2 then
                        local p = Emitter2D:Add(Glare2Mat, Pos + (VectorRand()*Radius*0.5))
                        p:SetDieTime(math.Rand(1,3))
                        p:SetLifeTime(1)
                        p:SetStartSize(math.Rand(16,32))
                        p:SetEndSize(0)
                        p:SetStartAlpha(255)
                        p:SetEndAlpha(255)
                        p:SetVelocity(VectorRand()*3)
                        p:SetGravity(Vector(0,0,math.Rand(3,5)))
                        p:SetAirResistance(30)
                        p:SetNextThink(CurTime())
                        local Seed = math.random()
                        local Seed2 = math.Rand(-4,4)
                        p:SetThinkFunction(function(p)
                            p:SetStartSize(math.abs(math.sin(Seed+Time*Seed2)*3+math.Rand(0,2)))
                            p:SetColor(math.Rand(200, 255), math.Rand(200, 255), math.Rand(200, 255))
                            p:SetNextThink(CurTime())
                        end)
                    end
                end
                Emitter2D:Draw()
                render.SetColorModulation(1,1,1)
                render.MaterialOverride()
            end
        end
    end)

    hook.Add("OnPlayerChat",Tag,function(ply,txt,team,dead)        
        if dead then
            chat.AddText(Color(130, 162, 214),"[Ghost-"..ply:GetName().."]",Color(255,255,255),": "..txt)
            return true
        end
    end)

    hook.Add("RenderScreenspaceEffects",Tag,function()
        if not LocalPlayer():Alive() then
            DrawColorModify(Settings)
        end
    end)

    hook.Add("Initialize",Tag,function()
        DBloom     = GetConVar("pp_bloom"):GetString()
        DBloomMult = GetConVar("pp_bloom_multiply"):GetString()
    end)

    hook.Add("HUDShouldDraw",Tag,function(name)
        if not LocalPlayer():Alive() and name == "CHudDamageIndicator" then
            return false
        end
    end)

end
