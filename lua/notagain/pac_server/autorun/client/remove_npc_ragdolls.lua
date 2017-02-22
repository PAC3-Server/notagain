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

