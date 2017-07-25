local Tag = "GhostMode"

if SERVER then
	hook.Add("PlayerDeathThink", Tag, function(ply)
		if not ply:GetNWBool("rpg") then return end

		ply:SetMoveType(MOVETYPE_NOCLIP)
		ply:SetNoDraw(true)
		ply:SetVelocity(ply:GetVelocity() * -0.01) -- this is wrong and bad and might feel awful with high ping

		if not ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_JUMP) then
			ply:SetMoveType(MOVETYPE_WALK)
			ply:SetNoDraw(false)
			return false
		end
	end)
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

	hook.Add("CalcView", Tag, function(ply)
		if ply:GetNWBool("rpg") and not ply:Alive() then
			timer.Simple(0.1,function()
				if ctp and battlecam then
					ctp:Disable()
					battlecam.Disable()
				end
			end)
			return {
				origin = ply:EyePos() + ply:GetAimVector() * -200,
			}
		end
	end)

    hook.Add("PostDrawTranslucentRenderables",Tag,function()
        for _,v in ipairs(player.GetAll()) do
            if v:GetNWBool("rpg") and not v:Alive() then
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

    hook.Add("OnPlayerChat",Tag,function(ply, txt)
        if ply:GetNWBool("rpg") and not ply:Alive() then
            chat.AddText(Color(130, 162, 214),"[Ghost-",ply:GetName(),Color(130, 162, 214),"]",Color(255,255,255),": "..txt)
            return true
        end
    end)

    hook.Add("RenderScreenspaceEffects",Tag,function()
		if LocalPlayer():GetNWBool("rpg") and not LocalPlayer():Alive() then
            DrawColorModify(Settings)
			DrawBloom( 0.25, 5, 9, 9, 1, 1, 1, 1, 1 )
        end
    end)

    hook.Add("HUDShouldDraw",Tag,function(name)
        if name == "CHudDamageIndicator" and LocalPlayer():GetNWBool("rpg") and not LocalPlayer():Alive() then
            return false
        end
    end)

end
