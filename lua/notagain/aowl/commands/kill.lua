AddCSLuaFile()

if CLIENT then
	usermessage.Hook("aowl_kill", function(umr)
		local ply = umr:ReadEntity()
		local vel = umr:ReadLong()
		local angvel = umr:ReadLong()

		if ply:IsValid() then
			local id = "find_rag_" .. ply:EntIndex()

			timer.Create(id, 0, 100, function()
				if not ply:IsValid() then return end
				local rag = ply:GetRagdollEntity() or NULL
				if rag:IsValid() then
					local phys = rag:GetPhysicsObject() or NULL
					if phys:IsValid() then
						local vel = ply:GetAimVector() * vel
						local angvel = VectorRand() * angvel
						for i = 0, rag:GetPhysicsObjectCount()-1 do
							local phys = rag:GetPhysicsObjectNum(i)	or NULL
							if phys:IsValid() then
								phys:SetVelocity(vel)
								phys:AddAngleVelocity(angvel)
							end
						end
						phys:SetVelocity(vel)
						phys:AddAngleVelocity(angvel)
						timer.Remove(id)
					end
				end
			end)
		end
	end)
end

if SERVER then
	aowl.AddCommand("god",function(ply, mode)
		if mode == "help" then
			ply:ChatPrint([[0 = godmode off\n1 = godmode on\n2 = only allow damage from world (fall damage, map damage, etc)\n3 = only allow damage from steam friends and world]])
		elseif not mode or mode == "" then
			local num = ply:GetInfoNum("cl_godmode",0)
			if num > 0 then
				ply:ConCommand("cl_godmode 0")
				ply:ChatPrint("godmode: off")
			else
				ply:ConCommand("cl_godmode 1")
				ply:ChatPrint("godmode: on")
			end
		elseif mode == "0" or mode == "off" then
			ply:ConCommand("cl_godmode 0")
			ply:ChatPrint("godmode: off")
		elseif mode == "1" or mode == "on" then
			ply:ConCommand("cl_godmode 1")
			ply:ChatPrint("godmode: on")
		elseif mode == "2" or mode == "world" then
			ply:ConCommand("cl_godmode 2")
			ply:ChatPrint("godmode: only allow damage from world (fall damage, map damage, etc)")
		elseif mode == "3" or mode == "world and friends" then
			ply:ConCommand("cl_godmode 3")
			ply:ChatPrint("godmode: only allow damage from steam friends and world (fall damage, map damage, etc)")
		end
	end)

	aowl.AddCommand("ungod",function(ply)
		ply:ConCommand("cl_godmode 0")
		ply:ChatPrint("godmode: off")
	end)

	aowl.AddCommand("suicide|die|kill|wrist=number|nil,number|nil", function(ply, line, vel, angvel)
		local ok = hook.Run("CanPlayerSuicide", ply)

		if ok == false then
			return false, "CanPlayerSuicide returns false"
		end

		if ply.last_rip and CurTime() - ply.last_rip < 0.05 then
			return
		end

		ply.last_rip = CurTime()

		ply:Kill()

		if vel then
			umsg.Start("aowl_kill")
				umsg.Entity(ply)
				umsg.Long(vel)
				umsg.Long(angvel or 0)
			umsg.End()
		end
	end)
end