if CLIENT then
	hook.Add("CreateClientsideRagdoll", "remove_npc_ragdolls", function(ent, rag)
		timer.Simple(5, function()
			if rag:IsValid() then
				local time = RealTime() + 1
				rag:SetRenderMode(RENDERMODE_TRANSALPHA)

				rag.RenderOverride = function()
					local f = time - RealTime()
					render.SetBlend(f)
					rag:DrawModel()
					if f <= 0 then
						SafeRemoveEntityDelayed(rag, 0)
					end
				end
			end
		end)
	end)
end

if SERVER then
	hook.Add("OnEntityCreated","remove_npc_ragdolls",function(ent)
		if ent:GetClass() == "prop_ragdoll" then
			local rag = ent
			timer.Simple(5, function()
				if rag:IsValid() and (not IsValid(rag:GetOwner()) and not (rag.GetCPPiOwner and IsValid((rag:CPPIGetOwner()))) then
					local time = RealTime() + 1
					rag:SetRenderMode(RENDERMODE_TRANSALPHA)

					rag.RenderOverride = function()
						local f = time - RealTime()
						render.SetBlend(f)
						rag:DrawModel()
						if f <= 0 then
							SafeRemoveEntityDelayed(rag, 0)
						end
					end
				end
			end)
		end
	end)
end