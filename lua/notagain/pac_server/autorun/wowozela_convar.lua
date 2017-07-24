hook.Add("InitPostEntity","fuckwowozelaok",function()
    if wowozela then
        local wowo_en = CreateConVar("wowozela_enable","1",FCVAR_ARCHIVE,"Enable or disable wowozela")
        local disabled = not wowo_en:Getbool()
        local DISABLE = function()
            hook.Remove("PostDrawOpaqueRenderables", "wowozela_draw")
            hook.Remove("Think","wowozela_think")
            hook.Remove("KeyPress", "wowozela_keypress")
            hook.Remove("KeyRelease", "wowozela_keyrelease")
            disabled = true
        end
        local ENABLE = function()
            hook.Add("PostDrawOpaqueRenderables", "wowozela_draw", wowozela.Draw)
            hook.Add("Think", "wowozela_think", wowozela.Think)
            hook.Add("KeyPress", "wowozela_keypress", function(ply, key)
                local wep = ply:GetActiveWeapon()
                if wep:IsValid() and wep:GetClass() == "wowozela" and wowozela.IsValidKey(key) then
                    if SERVER then
                        wowozela.BroadcastKeyEvent(ply, key, true)
                        wep:OnKeyEvent(key, true)
                    end

                    if CLIENT then
                        wowozela.KeyEvent(ply, key, true)
                    end
                end
            end)

            hook.Add("KeyRelease", "wowozela_keyrelease", function(ply, key)
                local wep = ply:GetActiveWeapon()
                if wep:IsValid() and wep:GetClass() == "wowozela" and wowozela.IsValidKey(key) then
                    if SERVER then
                        wowozela.BroadcastKeyEvent(ply, key, false)
                        wep:OnKeyEvent(key, false)
                    end

                    if CLIENT then
                        wowozela.KeyEvent(ply, key, false)
                    end
                end
            end)
            disabled = false
        end

        if disabled then
            DISABLE()
        end

        cvars.AddChangeCallback( "wowozela_enable",function(name,old,new)
            if new == 0 then
                DISABLE()
            else
                if disabled then
                    ENABLE()
                end
            end
        end)
    end
end)