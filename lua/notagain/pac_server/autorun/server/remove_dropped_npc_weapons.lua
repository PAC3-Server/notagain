if engine.ActiveGamemode() ~= "sandbox" then return end

hook.Add("OnNPCKilled", "removed_dropped_npc_weapons", function(npc)
	for _, ent in ipairs(ents.FindInSphere(npc:GetPos(), 200)) do
		if ent:GetOwner() == npc and (ent:IsWeapon() or ent:GetClass():StartWith("item_")) then
			timer.Simple(30, function()
				if ent:IsValid() and not ent:GetOwner():IsValid() then
					ent:SetRenderMode(RENDERMODE_TRANSALPHA)
					ent:SetRenderFX(kRenderFxFadeSlow)
					SafeRemoveEntityDelayed(ent, 2)
				end
			end)
		end
	end
end)